const path = require("path");

require("dotenv").config({ path: path.join(__dirname, "../.env"), quiet: true });

const env = process.env.NODE_ENV || "development";

/** Runtime settings, all overridable through `.env` (see `.env.example`). */
module.exports = {
  env,
  isProduction: env === "production",
  isTest: env === "test",
  port: Number(process.env.PORT) || 3000,
  databasePath:
    process.env.DATABASE_PATH || path.join(__dirname, "../data/verdant.db"),
  jwtSecret: process.env.JWT_SECRET || null,
  sessionDays: Number(process.env.SESSION_DAYS) || 30,
  corsOrigins: (process.env.CORS_ORIGINS || "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean),
  smtpUrl: process.env.SMTP_URL || null,
  mailFrom: process.env.MAIL_FROM || "Verdant <no-reply@verdant.local>",
};
