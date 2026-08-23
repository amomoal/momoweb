import assert from 'node:assert/strict';
import test from 'node:test';

import worker from '../src/index.js';

test('requires bearer token for admin content', async () => {
  const env = createEnv();
  const response = await worker.fetch(new Request('https://api.test/admin/content'), env);
  const body = await response.json();

  assert.equal(response.status, 401);
  assert.equal(body.message, 'ログインが必要です。');
});

test('returns only the site owned by the authenticated user', async () => {
  const env = createEnv();
  const response = await worker.fetch(
    authedRequest('https://api.test/admin/content', 'info-token'),
    env,
  );
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.siteId, 'info-site');
  assert.equal(body.plan, 'info');
});

test('blocks image updates for info plan users', async () => {
  const env = createEnv();
  const formData = new FormData();
  formData.set('image', new File(['image'], 'image.jpg', { type: 'image/jpeg' }));

  const response = await worker.fetch(
    authedRequest('https://api.test/admin/image', 'info-token', {
      method: 'PUT',
      body: formData,
    }),
    env,
  );
  const body = await response.json();

  assert.equal(response.status, 403);
  assert.equal(body.message, 'このプランでは画像を更新できません。');
  assert.equal(env.UPDATE_IMAGES.objects.size, 0);
});

test('allows image updates for info_image plan users', async () => {
  const env = createEnv();
  const formData = new FormData();
  formData.set('image', new File(['image'], 'image.png', { type: 'image/png' }));

  const response = await worker.fetch(
    authedRequest('https://api.test/admin/image', 'image-token', {
      method: 'PUT',
      body: formData,
    }),
    env,
  );
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.siteId, 'image-site');
  assert.equal(body.plan, 'info_image');
  assert.match(body.imageUrl, /^https:\/\/api\.test\/public\/sites\/image-site\/image$/);
  assert.equal(env.UPDATE_IMAGES.objects.size, 1);
});

test('updates info for the authenticated customer site', async () => {
  const env = createEnv();
  const response = await worker.fetch(
    authedRequest('https://api.test/admin/info', 'info-token', {
      method: 'PUT',
      body: JSON.stringify({ info: '新しいお知らせ' }),
      headers: { 'Content-Type': 'application/json' },
    }),
    env,
  );
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.info, '新しいお知らせ');
  assert.equal(env.UPDATE_DB.sites.get('info-site').info, '新しいお知らせ');
  assert.equal(env.UPDATE_DB.sites.get('image-site').info, '画像プランのお知らせ');
});

test('returns public content without auth', async () => {
  const env = createEnv();
  const response = await worker.fetch(
    new Request('https://api.test/public/sites/image-site/content'),
    env,
  );
  const body = await response.json();

  assert.equal(response.status, 200);
  assert.equal(body.siteName, '画像つきサイト');
  assert.equal(body.plan, 'info_image');
});

test('supports HEAD for public images', async () => {
  const env = createEnv();
  env.UPDATE_DB.sites.get('image-site').image_key = 'image-site/current.jpg';
  await env.UPDATE_IMAGES.put('image-site/current.jpg', new ReadableStream(), {
    httpMetadata: { contentType: 'image/jpeg' },
  });

  const response = await worker.fetch(
    new Request('https://api.test/public/sites/image-site/image', {
      method: 'HEAD',
    }),
    env,
  );

  assert.equal(response.status, 200);
  assert.equal(response.headers.get('Content-Type'), 'image/jpeg');
  assert.equal(await response.text(), '');
});

function authedRequest(url, token, init = {}) {
  const headers = new Headers(init.headers);
  headers.set('Authorization', `Bearer ${token}`);
  return new Request(url, { ...init, headers });
}

function createEnv() {
  return {
    UPDATE_DB: new MockD1Database(),
    UPDATE_IMAGES: new MockR2Bucket(),
  };
}

class MockD1Database {
  constructor() {
    this.users = new Map([
      [
        'e6e7a949b2d64be7183a8ef0c205e2d7ee31f2fcc929e0a4c630b5b67b2ad4d0',
        {
          id: 'info-user',
          customer_id: 'info-customer',
          site_id: 'info-site',
          email: 'info@example.com',
        },
      ],
      [
        '3a8b45db0b6f86a1c874814f42f4f0701c6332a9f4d7c7143cb603a2648e5a1d',
        {
          id: 'image-user',
          customer_id: 'image-customer',
          site_id: 'image-site',
          email: 'image@example.com',
        },
      ],
    ]);
    this.sites = new Map([
      [
        'info-site',
        {
          id: 'info-site',
          customer_id: 'info-customer',
          name: 'INFOだけサイト',
          slug: 'info-site',
          plan: 'info',
          info: 'INFOプランのお知らせ',
          image_key: null,
          updated_at: '2026-08-23 00:00:00',
        },
      ],
      [
        'image-site',
        {
          id: 'image-site',
          customer_id: 'image-customer',
          name: '画像つきサイト',
          slug: 'image-site',
          plan: 'info_image',
          info: '画像プランのお知らせ',
          image_key: null,
          updated_at: '2026-08-23 00:00:00',
        },
      ],
    ]);
  }

  prepare(sql) {
    return new MockD1Statement(this, sql);
  }
}

class MockD1Statement {
  constructor(db, sql) {
    this.db = db;
    this.sql = sql;
    this.values = [];
  }

  bind(...values) {
    this.values = values;
    return this;
  }

  async first() {
    if (this.sql.includes('FROM users WHERE token_hash')) {
      return this.db.users.get(this.values[0]) ?? null;
    }

    if (this.sql.includes('FROM sites') && this.sql.includes('WHERE id = ? AND customer_id = ?')) {
      return [...this.db.sites.values()].find(
        (site) => site.id === this.values[0] && site.customer_id === this.values[1],
      ) ?? null;
    }

    if (this.sql.includes('SELECT id, name, slug, plan, info, image_key')) {
      return this.db.sites.get(this.values[0]) ?? null;
    }

    if (this.sql.includes('SELECT image_key FROM sites')) {
      const site = this.db.sites.get(this.values[0]);
      return site ? { image_key: site.image_key } : null;
    }

    throw new Error(`Unhandled first SQL: ${this.sql}`);
  }

  async run() {
    if (this.sql.includes('UPDATE sites SET info')) {
      const [info, siteId, customerId] = this.values;
      const site = this.db.sites.get(siteId);
      if (site?.customer_id === customerId) {
        site.info = info;
      }
      return { success: true };
    }

    if (this.sql.includes('UPDATE sites SET image_key')) {
      const [imageKey, siteId, customerId] = this.values;
      const site = this.db.sites.get(siteId);
      if (site?.customer_id === customerId) {
        site.image_key = imageKey;
      }
      return { success: true };
    }

    throw new Error(`Unhandled run SQL: ${this.sql}`);
  }
}

class MockR2Bucket {
  constructor() {
    this.objects = new Map();
  }

  async put(key, body, options) {
    this.objects.set(key, {
      body,
      httpMetadata: options?.httpMetadata,
    });
  }

  async get(key) {
    return this.objects.get(key) ?? null;
  }
}
