const { db } = require("../db");
const { ApiError } = require("../middleware/errors");
const { isObject } = require("../utils/validate");

/** The app's saved stores, one JSON document per user. */
const KEYS = ["settings", "plants", "care_schedule", "cart", "wallet", "favorites", "address"];
const ARRAY_KEYS = new Set(["plants", "favorites"]);

function assertSafeWallet(value) {
  for (const method of value.methods ?? []) {
    if (!isObject(method)) throw new ApiError(422, "Invalid payment method");
    const allowed =
      method.type === "card"
        ? ["type", "id", "brand", "last4", "holder", "expMonth", "expYear"]
        : ["type", "id", "email"];
    // A full card number or CVC must never reach the server.
    if (Object.keys(method).some((field) => !allowed.includes(field))) {
      throw new ApiError(422, "Payment methods can only hold non-sensitive fields.");
    }
    if (method.type === "card" && !/^\d{4}$/.test(String(method.last4))) {
      throw new ApiError(422, "Invalid card details.");
    }
  }
}

function assertValid(key, value) {
  if (!KEYS.includes(key)) throw new ApiError(404, "Unknown data key", { code: "not_found" });
  const shapeOk = ARRAY_KEYS.has(key) ? Array.isArray(value) : isObject(value);
  if (!shapeOk) throw new ApiError(422, `Invalid ${key} data`, { code: "validation" });
  if (key === "wallet") assertSafeWallet(value);
}

function get(userId, key) {
  const row = db.prepare("SELECT value FROM user_data WHERE user_id = ? AND key = ?").get(userId, key);
  return row ? JSON.parse(row.value) : null;
}

function put(userId, key, value) {
  assertValid(key, value);
  db.prepare(
    `INSERT INTO user_data (user_id, key, value, updated_at) VALUES (?, ?, ?, ?)
     ON CONFLICT (user_id, key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at`,
  ).run(userId, key, JSON.stringify(value), new Date().toISOString());
  return value;
}

function snapshot(userId) {
  const data = {};
  for (const row of db.prepare("SELECT key, value FROM user_data WHERE user_id = ?").all(userId)) {
    data[row.key] = JSON.parse(row.value);
  }
  return data;
}

/** "Erase my data": everything except the account itself. */
function eraseAll(userId) {
  for (const table of ["user_data", "orders", "notifications", "sensor_readings", "reminder_emails", "reviews"]) {
    db.prepare(`DELETE FROM ${table} WHERE user_id = ?`).run(userId);
  }
}

module.exports = { KEYS, get, put, snapshot, eraseAll };
