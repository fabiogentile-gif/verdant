const path = require("path");
const cors = require("cors");
const express = require("express");
const helmet = require("helmet");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit").default;
const config = require("./config");
const { ApiError, errorHandler, notFound } = require("./middleware/errors");
const accountRoutes = require("./routes/account");
const authRoutes = require("./routes/auth");
const productRoutes = require("./routes/products");

const app = express();

app.use(helmet({ crossOriginResourcePolicy: { policy: "cross-origin" } }));
// The Android app ignores CORS; this only concerns browsers.
app.use(cors(config.isProduction ? { origin: config.corsOrigins } : undefined));
if (!config.isTest) app.use(morgan(config.isProduction ? "combined" : "dev"));
app.use(
  rateLimit({
    windowMs: 60 * 1000,
    limit: 300,
    standardHeaders: true,
    legacyHeaders: false,
    skip: () => config.isTest,
    handler: (req, res, next) =>
      next(new ApiError(429, "Too many requests.", { code: "rate_limited" })),
  }),
);
app.use(express.json({ limit: "512kb" }));
app.use("/static", express.static(path.join(__dirname, "../public")));
// Carts and orders saved by older versions still point at the old image paths.
app.get(/^\/(product_[a-z_]+\.png)$/, (req, res) =>
  res.redirect(301, `/static/products/${req.params[0]}`),
);

app.get("/", (req, res) => {
  res.json({
    message: "Welcome to Verdant Shop API",
    version: "2.0.0",
    endpoints: {
      "GET /api/products": "Product summaries (?category, q, sort, minPrice, maxPrice, page, limit)",
      "GET /api/products/:id": "Product details",
      "GET /api/products/:id/reviews": "Product reviews",
      "GET /api/categories": "All categories",
      "GET /api/categories/:category": "Products of one category",
      "GET /api/featured": "Up to 3 featured products",
      "POST /api/auth/register": "Create an account",
      "POST /api/auth/login": "Sign in",
      "POST /api/auth/logout": "Sign out (auth)",
      "GET|PATCH|DELETE /api/me": "Profile and account (auth)",
      "POST /api/me/password": "Change password (auth)",
      "GET|DELETE /api/sync, PUT /api/sync/:key": "App data sync (auth)",
      "/api/cart, /api/favorites, /api/addresses, /api/payment-methods": "User data (auth)",
      "/api/plants, /api/reminders, /api/settings, /api/notifications": "User data (auth)",
      "/api/orders, POST /api/discounts/validate": "Orders and discounts (auth)",
      "/api/sensors/:deviceId/readings": "Smart-pot readings (auth)",
    },
  });
});

app.use("/api", productRoutes);
app.use("/api", authRoutes);
app.use("/api", accountRoutes);

app.use(notFound);
app.use(errorHandler);

module.exports = app;
