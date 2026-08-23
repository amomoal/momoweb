const JSON_HEADERS = {
  'Content-Type': 'application/json; charset=utf-8',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
  'Access-Control-Allow-Methods': 'GET, PUT, OPTIONS',
};

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: JSON_HEADERS });
    }

    const url = new URL(request.url);

    try {
      if (url.pathname === '/admin/content' && request.method === 'GET') {
        return json(await getAdminContent(request, env, url.origin));
      }

      if (url.pathname === '/admin/info' && request.method === 'PUT') {
        return json(await updateInfo(request, env, url.origin));
      }

      if (url.pathname === '/admin/image' && request.method === 'PUT') {
        return json(await updateImage(request, env, url.origin));
      }

      const publicContentMatch = url.pathname.match(/^\/public\/sites\/([^/]+)\/content$/);
      if (publicContentMatch && request.method === 'GET') {
        return json(await getPublicContent(env, publicContentMatch[1], url.origin));
      }

      const publicImageMatch = url.pathname.match(/^\/public\/sites\/([^/]+)\/image$/);
      if (publicImageMatch && (request.method === 'GET' || request.method === 'HEAD')) {
        return getPublicImage(env, publicImageMatch[1], request.method === 'HEAD');
      }

      return jsonError('Not found', 404);
    } catch (error) {
      if (error instanceof ApiError) {
        return jsonError(error.message, error.status);
      }

      console.error(error);
      return jsonError('Server error', 500);
    }
  },
};

async function getAdminContent(request, env, origin) {
  const context = await requireUserSite(request, env);
  return siteResponse(context.site, origin);
}

async function updateInfo(request, env, origin) {
  const context = await requireUserSite(request, env);
  const body = await request.json().catch(() => null);
  const info = typeof body?.info === 'string' ? body.info.trim() : '';

  if (!info) {
    throw new ApiError('お知らせを入力してください。', 400);
  }

  if (info.length > 2000) {
    throw new ApiError('お知らせは2000文字以内で入力してください。', 400);
  }

  await env.UPDATE_DB.prepare(
    'UPDATE sites SET info = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND customer_id = ?',
  )
    .bind(info, context.site.id, context.user.customer_id)
    .run();

  return siteResponse({ ...context.site, info }, origin);
}

async function updateImage(request, env, origin) {
  const context = await requireUserSite(request, env);

  if (context.site.plan !== 'info_image') {
    throw new ApiError('このプランでは画像を更新できません。', 403);
  }

  const formData = await request.formData();
  const image = formData.get('image');

  if (!(image instanceof File)) {
    throw new ApiError('画像を選択してください。', 400);
  }

  if (!image.type.startsWith('image/')) {
    throw new ApiError('画像ファイルを選択してください。', 400);
  }

  if (image.size > 5 * 1024 * 1024) {
    throw new ApiError('画像は5MB以内にしてください。', 400);
  }

  const extension = extensionFor(image.type);
  const imageKey = `${context.site.id}/${crypto.randomUUID()}${extension}`;

  await env.UPDATE_IMAGES.put(imageKey, image.stream(), {
    httpMetadata: {
      contentType: image.type,
    },
  });

  await env.UPDATE_DB.prepare(
    'UPDATE sites SET image_key = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ? AND customer_id = ?',
  )
    .bind(imageKey, context.site.id, context.user.customer_id)
    .run();

  return siteResponse({ ...context.site, image_key: imageKey }, origin);
}

async function getPublicContent(env, siteId, origin) {
  const site = await env.UPDATE_DB.prepare(
    'SELECT id, name, slug, plan, info, image_key, updated_at FROM sites WHERE id = ?',
  )
    .bind(siteId)
    .first();

  if (!site) {
    throw new ApiError('Not found', 404);
  }

  return siteResponse(site, origin);
}

async function getPublicImage(env, siteId, headersOnly = false) {
  const site = await env.UPDATE_DB.prepare(
    'SELECT image_key FROM sites WHERE id = ?',
  )
    .bind(siteId)
    .first();

  if (!site?.image_key) {
    throw new ApiError('Not found', 404);
  }

  const object = await env.UPDATE_IMAGES.get(site.image_key);
  if (!object) {
    throw new ApiError('Not found', 404);
  }

  return new Response(headersOnly ? null : object.body, {
    headers: {
      'Content-Type': object.httpMetadata?.contentType ?? 'application/octet-stream',
      'Cache-Control': 'public, max-age=60',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

async function requireUserSite(request, env) {
  const token = bearerToken(request);
  const tokenHash = await sha256Hex(token);

  const user = await env.UPDATE_DB.prepare(
    'SELECT id, customer_id, site_id, email FROM users WHERE token_hash = ?',
  )
    .bind(tokenHash)
    .first();

  if (!user) {
    throw new ApiError('ログインが必要です。', 401);
  }

  const site = await env.UPDATE_DB.prepare(
    `SELECT id, customer_id, name, slug, plan, info, image_key, updated_at
     FROM sites
     WHERE id = ? AND customer_id = ?
     LIMIT 1`,
  )
    .bind(user.site_id, user.customer_id)
    .first();

  if (!site) {
    throw new ApiError('更新できるサイトがありません。', 403);
  }

  return { user, site };
}

function bearerToken(request) {
  const header = request.headers.get('Authorization') ?? '';
  const match = header.match(/^Bearer\s+(.+)$/i);
  if (!match) {
    throw new ApiError('ログインが必要です。', 401);
  }
  return match[1];
}

async function sha256Hex(value) {
  const data = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest('SHA-256', data);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

function siteResponse(site, origin = '') {
  return {
    siteId: site.id,
    siteName: site.name,
    slug: site.slug,
    plan: site.plan,
    info: site.info,
    imageUrl: site.image_key ? `${origin}/public/sites/${site.id}/image` : null,
    updatedAt: site.updated_at,
  };
}

function extensionFor(contentType) {
  switch (contentType) {
    case 'image/png':
      return '.png';
    case 'image/webp':
      return '.webp';
    case 'image/gif':
      return '.gif';
    default:
      return '.jpg';
  }
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: JSON_HEADERS,
  });
}

function jsonError(message, status) {
  return json({ message }, status);
}

class ApiError extends Error {
  constructor(message, status) {
    super(message);
    this.status = status;
  }
}
