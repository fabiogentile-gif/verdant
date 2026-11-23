const { ApiError } = require("./errors");
const { authenticate } = require("../services/auth");

/** Requires `Authorization: Bearer <token>` and sets `req.user` and `req.jti`. */
function requireAuth(req, res, next) {
  const [scheme, token] = (req.headers.authorization || "").split(" ");
  const session = scheme === "Bearer" && token ? authenticate(token) : null;
  if (!session) {
    return next(
      new ApiError(401, "Please sign in again.", { code: "unauthorized" }),
    );
  }
  req.user = session.user;
  req.jti = session.jti;
  next();
}

function requireAdmin(req, res, next) {
  if (req.user?.role !== "admin") {
    return next(new ApiError(403, "Admins only.", { code: "forbidden" }));
  }
  next();
}

module.exports = { requireAuth, requireAdmin };
