const { ApiError } = require("../middleware/errors");

const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

const invalid = (field, message) =>
  new ApiError(422, message, { code: "validation", fields: { [field]: message } });

function text(value, field, { min = 1, max = 200, label = field } = {}) {
  if (typeof value !== "string") throw invalid(field, `${label} is required.`);
  const trimmed = value.trim();
  if (trimmed.length < min) throw invalid(field, `${label} is required.`);
  if (trimmed.length > max) throw invalid(field, `${label} is too long.`);
  return trimmed;
}

function email(value) {
  const trimmed = typeof value === "string" ? value.trim().toLowerCase() : "";
  if (!EMAIL.test(trimmed) || trimmed.length > 254) {
    throw invalid("email", "Enter a valid email address.");
  }
  return trimmed;
}

function password(value, field = "password") {
  if (typeof value !== "string" || value.length < 8) {
    throw invalid(field, "Use at least 8 characters.");
  }
  if (value.length > 128) throw invalid(field, "That password is too long.");
  return value;
}

/** Strict positive integer from a route or query parameter. */
function positiveInt(value, field = "id") {
  const raw = String(value);
  if (!/^[1-9]\d{0,8}$/.test(raw)) {
    throw new ApiError(400, `Invalid ${field}`, { code: "bad_request" });
  }
  return Number(raw);
}

function optionalNumber(value, field, { min = -Infinity, max = Infinity } = {}) {
  if (value === undefined || value === null || value === "") return null;
  const number = Number(value);
  if (!Number.isFinite(number) || number < min || number > max) {
    throw new ApiError(400, `Invalid ${field}`, { code: "bad_request" });
  }
  return number;
}

const isObject = (value) =>
  typeof value === "object" && value !== null && !Array.isArray(value);

module.exports = { invalid, text, email, password, positiveInt, optionalNumber, isObject };
