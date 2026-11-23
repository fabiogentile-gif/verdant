const { Router } = require("express");
const rateLimit = require("express-rate-limit").default;
const config = require("../config");
const { requireAuth } = require("../middleware/auth");
const { handle, ApiError } = require("../middleware/errors");
const auth = require("../services/auth");
const v = require("../utils/validate");

const router = Router();

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  skip: () => config.isTest,
  handler: (req, res, next) =>
    next(new ApiError(429, "Too many attempts. Try again in a few minutes.", { code: "rate_limited" })),
});

router.post(
  "/auth/register",
  limiter,
  handle(async (req, res) => {
    const result = await auth.register({
      name: v.text(req.body.name, "name", { max: 60, label: "Name" }),
      email: v.email(req.body.email),
      password: v.password(req.body.password),
    });
    res.status(201).json({ success: true, data: result });
  }),
);

router.post(
  "/auth/login",
  limiter,
  handle(async (req, res) => {
    if (typeof req.body.password !== "string" || !req.body.password) {
      throw v.invalid("password", "Enter your password.");
    }
    const result = await auth.login({
      email: v.email(req.body.email),
      password: req.body.password.slice(0, 128),
    });
    res.json({ success: true, data: result });
  }),
);

router.post(
  "/auth/logout",
  requireAuth,
  handle((req, res) => {
    auth.logout(req.jti);
    res.status(204).end();
  }),
);

router.get("/me", requireAuth, (req, res) => res.json({ success: true, data: req.user }));

router.patch(
  "/me",
  requireAuth,
  handle((req, res) => {
    const { name, location } = req.body;
    const data = auth.updateProfile(req.user.id, {
      name: name === undefined ? undefined : v.text(name, "name", { max: 60, label: "Name" }),
      location:
        location === undefined
          ? undefined
          : v.text(location, "location", { min: 0, max: 80, label: "Location" }),
    });
    res.json({ success: true, data });
  }),
);

router.post(
  "/me/password",
  requireAuth,
  limiter,
  handle(async (req, res) => {
    const current = v.text(req.body.currentPassword, "currentPassword", {
      max: 128,
      label: "Current password",
    });
    await auth.changePassword(
      req.user.id,
      req.jti,
      current,
      v.password(req.body.newPassword, "newPassword"),
    );
    res.status(204).end();
  }),
);

router.delete(
  "/me",
  requireAuth,
  limiter,
  handle(async (req, res) => {
    const password = v.text(req.body?.password, "password", { max: 128, label: "Password" });
    await auth.deleteAccount(req.user.id, password);
    res.status(204).end();
  }),
);

module.exports = router;
