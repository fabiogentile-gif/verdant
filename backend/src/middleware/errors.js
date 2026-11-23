/** An error that is safe to show to the API client. */
class ApiError extends Error {
  constructor(status, message, { code, fields } = {}) {
    super(message);
    this.status = status;
    this.code = code;
    this.fields = fields;
  }
}

/** Forwards errors of sync and async route handlers to Express. */
const handle = (fn) => (req, res, next) =>
  Promise.resolve()
    .then(() => fn(req, res, next))
    .catch(next);

const notFound = (req, res, next) =>
  next(new ApiError(404, "Route not found", { code: "not_found" }));

// Express recognises error middleware by its four arguments.
// eslint-disable-next-line no-unused-vars
function errorHandler(error, req, res, next) {
  if (error.type === "entity.parse.failed") {
    error = new ApiError(400, "Invalid JSON body", { code: "bad_json" });
  } else if (error.type === "entity.too.large") {
    error = new ApiError(413, "Request body is too large", { code: "too_large" });
  }
  if (!(error instanceof ApiError)) {
    console.error(error);
    error = new ApiError(500, "Something went wrong", { code: "server_error" });
  }
  res.status(error.status).json({
    success: false,
    message: error.message,
    code: error.code,
    fields: error.fields,
  });
}

module.exports = { ApiError, handle, notFound, errorHandler };
