CREATE TABLE customers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE sites (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  plan TEXT NOT NULL CHECK (plan IN ('info', 'info_image')),
  info TEXT NOT NULL DEFAULT '',
  image_key TEXT,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE users (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  site_id TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  token_hash TEXT NOT NULL UNIQUE,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id),
  FOREIGN KEY (site_id) REFERENCES sites(id)
);

CREATE INDEX idx_sites_customer_id ON sites(customer_id);
CREATE INDEX idx_users_customer_id ON users(customer_id);
CREATE INDEX idx_users_site_id ON users(site_id);
