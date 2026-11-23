const fs = require("fs");
const path = require("path");
const { DatabaseSync } = require("node:sqlite");
const config = require("./config");

if (config.databasePath !== ":memory:") {
  fs.mkdirSync(path.dirname(config.databasePath), { recursive: true });
}

const db = new DatabaseSync(config.databasePath);
db.exec("PRAGMA foreign_keys = ON;");
if (config.databasePath !== ":memory:") db.exec("PRAGMA journal_mode = WAL;");

db.exec(`
  CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
  CREATE TABLE IF NOT EXISTS products (
    id INTEGER PRIMARY KEY,
    data TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE COLLATE NOCASE,
    name TEXT NOT NULL,
    location TEXT NOT NULL DEFAULT '',
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user',
    created_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS sessions (
    jti TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    expires_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS user_data (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    PRIMARY KEY (user_id, key)
  );
  CREATE TABLE IF NOT EXISTS discount_codes (
    code TEXT PRIMARY KEY,
    label TEXT NOT NULL,
    rate REAL NOT NULL,
    first_order_only INTEGER NOT NULL DEFAULT 0,
    active INTEGER NOT NULL DEFAULT 1
  );
  CREATE TABLE IF NOT EXISTS orders (
    number TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    idempotency_key TEXT,
    status TEXT NOT NULL DEFAULT 'placed',
    data TEXT NOT NULL,
    created_at TEXT NOT NULL,
    UNIQUE (user_id, idempotency_key)
  );
  CREATE TABLE IF NOT EXISTS reviews (
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    PRIMARY KEY (product_id, user_id)
  );
  CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    read_at TEXT,
    created_at TEXT NOT NULL
  );
  CREATE TABLE IF NOT EXISTS sensor_readings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id TEXT NOT NULL,
    plant_id TEXT,
    moisture REAL,
    light REAL,
    temperature REAL,
    recorded_at TEXT NOT NULL
  );
  CREATE INDEX IF NOT EXISTS sensor_readings_lookup
    ON sensor_readings (user_id, device_id, recorded_at);
  CREATE TABLE IF NOT EXISTS reminder_emails (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    plan_id TEXT NOT NULL,
    due TEXT NOT NULL,
    sent_at TEXT NOT NULL,
    PRIMARY KEY (user_id, plan_id, due)
  );
`);

/** Runs [work] atomically and returns its result. */
function transaction(work) {
  db.exec("BEGIN IMMEDIATE");
  try {
    const result = work();
    db.exec("COMMIT");
    return result;
  } catch (error) {
    db.exec("ROLLBACK");
    throw error;
  }
}

/**
 * Imports catalogue products not seen before, plus the welcome discount.
 * Imported ids are remembered, so stock edits are kept and a product deleted
 * by an admin doesn't come back on restart.
 */
function seed() {
  const { count } = db.prepare("SELECT COUNT(*) AS count FROM products").get();
  const saved = db.prepare("SELECT value FROM meta WHERE key = 'catalogue_ids'").get();
  // Databases created before this list existed held the first six products.
  const imported = new Set(
    saved ? JSON.parse(saved.value) : count > 0 ? [1, 2, 3, 4, 5, 6] : [],
  );
  const catalogue = JSON.parse(
    fs.readFileSync(path.join(__dirname, "data/products.json"), "utf8"),
  );
  const insert = db.prepare("INSERT OR IGNORE INTO products (id, data) VALUES (?, ?)");
  transaction(() => {
    for (const product of catalogue) {
      if (imported.has(product.id)) continue;
      insert.run(product.id, JSON.stringify(product));
      imported.add(product.id);
    }
    db.prepare(
      `INSERT INTO meta (key, value) VALUES ('catalogue_ids', ?)
       ON CONFLICT (key) DO UPDATE SET value = excluded.value`,
    ).run(JSON.stringify([...imported]));
  });
  db.prepare(
    `INSERT OR IGNORE INTO discount_codes (code, label, rate, first_order_only)
     VALUES ('GROW10', 'Welcome discount (10%)', 0.10, 1)`,
  ).run();
}

seed();

module.exports = { db, transaction };
