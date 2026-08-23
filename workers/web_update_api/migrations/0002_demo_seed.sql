INSERT INTO customers (id, name)
VALUES ('demo-customer', 'デモ顧客');

INSERT INTO sites (id, customer_id, name, slug, plan, info)
VALUES (
  'roman-demo',
  'demo-customer',
  '純喫茶 ロマン',
  'roman',
  'info_image',
  '本日は通常通り営業しています。'
);

-- demo-info-image-token
INSERT INTO users (id, customer_id, site_id, email, token_hash)
VALUES (
  'demo-user',
  'demo-customer',
  'roman-demo',
  'demo@example.com',
  '3790085c0d5c98e63f4771dadd7bb6ee858a4a0b72682745f62a01ed447656de'
);
