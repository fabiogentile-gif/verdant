const crypto = require("crypto");
const { promisify } = require("util");
const jwt = require("jsonwebtoken");
const config = require("../config");
const { db } = require("../db");
const { ApiError } = require("../middleware/errors");

const scrypt = promisify(crypto.scrypt);
const KEY_LENGTH = 64;

/** Production needs JWT_SECRET; development keeps a generated one in the database. */
function loadSecret() {
  if (config.jwtSecret) return config.jwtSecret;
  if (config.isProduction) {
    throw new Error("JWT_SECRET is required when NODE_ENV=production");
  }
  const saved = db.prepare("SELECT value FROM meta WHERE key = 'jwt_secret'").get();
  if (saved) return saved.value;
  const secret = crypto.randomBytes(48).toString("hex");
  db.prepare("INSERT INTO meta (key, value) VALUES ('jwt_secret', ?)").run(secret);
  return secret;
}

const secret = loadSecret();

async function hashPassword(password) {
  const salt = crypto.randomBytes(16);
  const key = await scrypt(password, salt, KEY_LENGTH);
  return `${salt.toString("hex")}:${key.toString("hex")}`;
}

async function verifyPassword(password, stored) {
  const [saltHex, keyHex] = stored.split(":");
  const expected = Buffer.from(keyHex, "hex");
  const actual = await scrypt(password, Buffer.from(saltHex, "hex"), KEY_LENGTH);
  return crypto.timingSafeEqual(actual, expected);
}

// Compared when the email is unknown, so both failures take the same time.
const dummyHash = hashPassword(crypto.randomBytes(16).toString("hex"));

const publicUser = (row) => ({
  id: row.id,
  email: row.email,
  name: row.name,
  location: row.location,
  role: row.role,
  createdAt: row.created_at,
});

function createSession(userId) {
  const now = Date.now();
  db.prepare("DELETE FROM sessions WHERE expires_at < ?").run(new Date(now).toISOString());
  const jti = crypto.randomUUID();
  const expiresAt = new Date(now + config.sessionDays * 86400000).toISOString();
  db.prepare("INSERT INTO sessions (jti, user_id, expires_at) VALUES (?, ?, ?)").run(
    jti,
    userId,
    expiresAt,
  );
  return jwt.sign({ sub: String(userId) }, secret, {
    algorithm: "HS256",
    jwtid: jti,
    expiresIn: `${config.sessionDays}d`,
  });
}

/** Returns the session of a valid, non-revoked token, otherwise null. */
function authenticate(token) {
  let claims;
  try {
    claims = jwt.verify(token, secret, { algorithms: ["HS256"] });
  } catch {
    return null;
  }
  const row = db
    .prepare(
      `SELECT users.* FROM sessions JOIN users ON users.id = sessions.user_id
       WHERE sessions.jti = ? AND sessions.user_id = ? AND sessions.expires_at > ?`,
    )
    .get(claims.jti, Number(claims.sub), new Date().toISOString());
  return row ? { user: publicUser(row), jti: claims.jti } : null;
}

async function register({ name, email, password }) {
  const passwordHash = await hashPassword(password);
  try {
    const { lastInsertRowid } = db
      .prepare(
        `INSERT INTO users (email, name, password_hash, created_at)
         VALUES (?, ?, ?, ?)`,
      )
      .run(email, name, passwordHash, new Date().toISOString());
    const id = Number(lastInsertRowid);
    const row = db.prepare("SELECT * FROM users WHERE id = ?").get(id);
    return { user: publicUser(row), token: createSession(id) };
  } catch (error) {
    if (String(error.message).includes("UNIQUE")) {
      const message = "An account with this email already exists.";
      throw new ApiError(409, message, {
        code: "email_taken",
        fields: { email: message },
      });
    }
    throw error;
  }
}

async function login({ email, password }) {
  const row = db.prepare("SELECT * FROM users WHERE email = ?").get(email);
  const valid = await verifyPassword(password, row?.password_hash ?? (await dummyHash));
  if (!row || !valid) {
    throw new ApiError(401, "Wrong email or password.", { code: "bad_credentials" });
  }
  return { user: publicUser(row), token: createSession(row.id) };
}

function logout(jti) {
  db.prepare("DELETE FROM sessions WHERE jti = ?").run(jti);
}

function updateProfile(userId, { name, location }) {
  db.prepare(
    "UPDATE users SET name = COALESCE(?, name), location = COALESCE(?, location) WHERE id = ?",
  ).run(name ?? null, location ?? null, userId);
  return publicUser(db.prepare("SELECT * FROM users WHERE id = ?").get(userId));
}

async function assertPassword(userId, password) {
  const row = db.prepare("SELECT password_hash FROM users WHERE id = ?").get(userId);
  if (!(await verifyPassword(password, row.password_hash))) {
    const message = "That password isn’t right.";
    throw new ApiError(403, message, {
      code: "bad_password",
      fields: { currentPassword: message },
    });
  }
}

/** Changes the password and signs out every other device. */
async function changePassword(userId, jti, currentPassword, newPassword) {
  await assertPassword(userId, currentPassword);
  const hash = await hashPassword(newPassword);
  db.prepare("UPDATE users SET password_hash = ? WHERE id = ?").run(hash, userId);
  db.prepare("DELETE FROM sessions WHERE user_id = ? AND jti <> ?").run(userId, jti);
}

async function deleteAccount(userId, password) {
  await assertPassword(userId, password);
  db.prepare("DELETE FROM users WHERE id = ?").run(userId);
}

module.exports = {
  authenticate,
  register,
  login,
  logout,
  updateProfile,
  changePassword,
  deleteAccount,
};
