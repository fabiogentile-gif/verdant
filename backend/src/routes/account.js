const crypto = require("crypto");
const { Router } = require("express");
const { db } = require("../db");
const { requireAuth, requireAdmin } = require("../middleware/auth");
const { ApiError, handle } = require("../middleware/errors");
const orders = require("../services/orders");
const data = require("../services/user_data");
const v = require("../utils/validate");

const router = Router();
// Listed explicitly so unknown /api routes still answer 404 instead of 401.
router.use(
  [
    "/sync",
    "/cart",
    "/settings",
    "/addresses",
    "/payment-methods",
    "/reminders",
    "/favorites",
    "/plants",
    "/discounts",
    "/orders",
    "/notifications",
    "/sensors",
  ],
  requireAuth,
);

const ok = (res, value) => res.json({ success: true, data: value });

// --- Whole-store sync, used by the app ---------------------------------------

router.get("/sync", (req, res) =>
  ok(res, { stores: data.snapshot(req.user.id), orders: orders.listFor(req.user.id) }),
);

router.put(
  "/sync/:key",
  handle((req, res) => ok(res, data.put(req.user.id, req.params.key, req.body?.value))),
);

router.delete(
  "/sync",
  handle((req, res) => {
    data.eraseAll(req.user.id);
    res.status(204).end();
  }),
);

// --- Simple document resources -----------------------------------------------

for (const [path, key, empty] of [
  ["/cart", "cart", { items: [], discount: null, shipping: "standard" }],
  ["/settings", "settings", {}],
  ["/addresses", "address", {}],
  ["/payment-methods", "wallet", { methods: [], selectedId: null }],
  ["/reminders", "care_schedule", { plans: [], completed: [] }],
]) {
  router.get(path, (req, res) => ok(res, data.get(req.user.id, key) ?? empty));
  router.put(
    path,
    handle((req, res) => ok(res, data.put(req.user.id, key, req.body))),
  );
}

// --- Favourites --------------------------------------------------------------

router.get("/favorites", (req, res) => ok(res, data.get(req.user.id, "favorites") ?? []));

router.put(
  "/favorites/:productId",
  handle((req, res) => {
    const id = v.positiveInt(req.params.productId, "productId");
    const current = data.get(req.user.id, "favorites") ?? [];
    ok(res, data.put(req.user.id, "favorites", [...new Set([...current, id])]));
  }),
);

router.delete(
  "/favorites/:productId",
  handle((req, res) => {
    const id = v.positiveInt(req.params.productId, "productId");
    const current = data.get(req.user.id, "favorites") ?? [];
    ok(res, data.put(req.user.id, "favorites", current.filter((x) => x !== id)));
  }),
);

// --- Plants ------------------------------------------------------------------

const plantsOf = (userId) => data.get(userId, "plants") ?? [];

function requirePlant(userId, id) {
  const plant = plantsOf(userId).find((p) => p.id === id);
  if (!plant) throw new ApiError(404, "Plant not found", { code: "not_found" });
  return plant;
}

router.get("/plants", (req, res) => ok(res, plantsOf(req.user.id)));

router.get(
  "/plants/:id",
  handle((req, res) => {
    const plant = requirePlant(req.user.id, req.params.id);
    const schedule = data.get(req.user.id, "care_schedule") ?? {};
    ok(res, {
      ...plant,
      plans: (schedule.plans ?? []).filter((p) => p.plantId === plant.id),
      history: (schedule.completed ?? []).filter((c) => c.plantId === plant.id),
    });
  }),
);

router.post(
  "/plants",
  handle((req, res) => {
    const plant = {
      id: crypto.randomUUID(),
      name: v.text(req.body.name, "name", { max: 60, label: "Name" }),
      room: v.text(req.body.room, "room", { max: 60, label: "Room" }),
      species: v.text(req.body.species, "species", { max: 100, label: "Species" }),
      imagePath: typeof req.body.imagePath === "string" ? req.body.imagePath.slice(0, 300) : "",
      addedOn: new Date().toISOString(),
    };
    data.put(req.user.id, "plants", [...plantsOf(req.user.id), plant]);
    res.status(201).json({ success: true, data: plant });
  }),
);

router.patch(
  "/plants/:id",
  handle((req, res) => {
    const plant = requirePlant(req.user.id, req.params.id);
    const updated = {
      ...plant,
      name:
        req.body.name === undefined
          ? plant.name
          : v.text(req.body.name, "name", { max: 60, label: "Name" }),
      room:
        req.body.room === undefined
          ? plant.room
          : v.text(req.body.room, "room", { max: 60, label: "Room" }),
    };
    data.put(
      req.user.id,
      "plants",
      plantsOf(req.user.id).map((p) => (p.id === plant.id ? updated : p)),
    );
    ok(res, updated);
  }),
);

router.delete(
  "/plants/:id",
  handle((req, res) => {
    const plant = requirePlant(req.user.id, req.params.id);
    data.put(req.user.id, "plants", plantsOf(req.user.id).filter((p) => p.id !== plant.id));
    const schedule = data.get(req.user.id, "care_schedule");
    if (schedule) {
      data.put(req.user.id, "care_schedule", {
        plans: (schedule.plans ?? []).filter((p) => p.plantId !== plant.id),
        completed: (schedule.completed ?? []).filter((c) => c.plantId !== plant.id),
      });
    }
    res.status(204).end();
  }),
);

router.post(
  "/plants/:id/water",
  handle((req, res) => {
    const plant = requirePlant(req.user.id, req.params.id);
    const schedule = data.get(req.user.id, "care_schedule") ?? { plans: [], completed: [] };
    const now = new Date();
    const event = {
      plantId: plant.id,
      title: "Watered",
      date: now.toISOString(),
      note: "Marked as done in Verdant",
      kind: "water",
    };
    const plans = (schedule.plans ?? []).map((p) => {
      if (p.plantId !== plant.id || p.kind !== "water") return p;
      const next = new Date(now.getTime() + (p.everyDays ?? 7) * 86400000).toISOString();
      return { ...p, nextDue: next, nextDueUtc: next };
    });
    data.put(req.user.id, "care_schedule", {
      plans,
      completed: [...(schedule.completed ?? []), event],
    });
    res.status(201).json({ success: true, data: event });
  }),
);

// --- Orders and discounts ----------------------------------------------------

router.post(
  "/discounts/validate",
  handle((req, res) => ok(res, orders.findDiscount(req.user.id, req.body.code))),
);

router.get("/orders", (req, res) => ok(res, orders.listFor(req.user.id)));

router.post(
  "/orders",
  handle((req, res) => {
    const { order, created } = orders.place(req.user, req.body);
    res.status(created ? 201 : 200).json({ success: true, data: order });
  }),
);

router.get(
  "/orders/:number",
  handle((req, res) => ok(res, orders.findFor(req.user.id, req.params.number))),
);

router.patch(
  "/orders/:number/status",
  requireAdmin,
  handle((req, res) => ok(res, orders.setStatus(req.params.number, req.body.status))),
);

// --- In-app notifications ----------------------------------------------------

router.get("/notifications", (req, res) =>
  ok(
    res,
    db
      .prepare(
        `SELECT id, title, body, read_at AS readAt, created_at AS createdAt
         FROM notifications WHERE user_id = ? ORDER BY id DESC LIMIT 100`,
      )
      .all(req.user.id),
  ),
);

router.post("/notifications/read", (req, res) => {
  db.prepare("UPDATE notifications SET read_at = ? WHERE user_id = ? AND read_at IS NULL").run(
    new Date().toISOString(),
    req.user.id,
  );
  res.status(204).end();
});

// --- Smart-pot sensors -------------------------------------------------------

router.post(
  "/sensors/:deviceId/readings",
  handle((req, res) => {
    const deviceId = v.text(req.params.deviceId, "deviceId", { max: 64, label: "Device" });
    const moisture = v.optionalNumber(req.body.moisture, "moisture", { min: 0, max: 100 });
    const light = v.optionalNumber(req.body.light, "light", { min: 0, max: 200000 });
    const temperature = v.optionalNumber(req.body.temperature, "temperature", { min: -40, max: 80 });
    if (moisture === null && light === null && temperature === null) {
      throw v.invalid("reading", "Send at least one sensor value.");
    }
    const plantId = typeof req.body.plantId === "string" ? req.body.plantId.slice(0, 100) : null;
    const recordedAt = new Date().toISOString();
    db.prepare(
      `INSERT INTO sensor_readings (user_id, device_id, plant_id, moisture, light, temperature, recorded_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
    ).run(req.user.id, deviceId, plantId, moisture, light, temperature, recordedAt);
    res.status(201).json({
      success: true,
      data: { deviceId, plantId, moisture, light, temperature, recordedAt },
    });
  }),
);

router.get(
  "/sensors/:deviceId/readings",
  handle((req, res) => {
    const limit = req.query.limit ? Math.min(v.positiveInt(req.query.limit, "limit"), 500) : 50;
    ok(
      res,
      db
        .prepare(
          `SELECT device_id AS deviceId, plant_id AS plantId, moisture, light, temperature,
                  recorded_at AS recordedAt
           FROM sensor_readings WHERE user_id = ? AND device_id = ?
           ORDER BY id DESC LIMIT ?`,
        )
        .all(req.user.id, req.params.deviceId, limit),
    );
  }),
);

module.exports = router;
