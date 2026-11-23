const { Router } = require("express");
const { db } = require("../db");
const { requireAuth, requireAdmin } = require("../middleware/auth");
const { handle } = require("../middleware/errors");
const products = require("../services/products");
const { positiveInt, optionalNumber, text, invalid } = require("../utils/validate");

const router = Router();
const admin = [requireAuth, requireAdmin];

const queryText = (value) => (typeof value === "string" ? value : undefined);

router.get(
  "/products",
  handle((req, res) => {
    const { page, limit } = req.query;
    const result = products.list({
      category: queryText(req.query.category),
      search: queryText(req.query.search) ?? queryText(req.query.q),
      sort: queryText(req.query.sort),
      minPrice: optionalNumber(req.query.minPrice, "minPrice", { min: 0 }),
      maxPrice: optionalNumber(req.query.maxPrice, "maxPrice", { min: 0 }),
    });
    const total = result.length;
    let items = result;
    let pagination;
    if (page !== undefined || limit !== undefined) {
      const pageNumber = page === undefined ? 1 : positiveInt(page, "page");
      const size = limit === undefined ? 20 : Math.min(positiveInt(limit, "limit"), 100);
      items = result.slice((pageNumber - 1) * size, pageNumber * size);
      pagination = { page: pageNumber, limit: size, total, pages: Math.ceil(total / size) };
    }
    res.json({ success: true, data: items.map(products.summary), count: items.length, pagination });
  }),
);

router.post(
  "/products",
  admin,
  handle((req, res) => res.status(201).json({ success: true, data: products.create(req.body) })),
);

router.get(
  "/products/:id",
  handle((req, res) =>
    res.json({ success: true, data: products.details(positiveInt(req.params.id)) }),
  ),
);

router.put(
  "/products/:id",
  admin,
  handle((req, res) =>
    res.json({ success: true, data: products.update(positiveInt(req.params.id), req.body) }),
  ),
);

router.delete(
  "/products/:id",
  admin,
  handle((req, res) => {
    products.remove(positiveInt(req.params.id));
    res.status(204).end();
  }),
);

router.get(
  "/products/:id/reviews",
  handle((req, res) => {
    const id = positiveInt(req.params.id);
    products.requireProduct(id);
    const data = db
      .prepare(
        `SELECT reviews.rating, reviews.comment, reviews.created_at AS createdAt, users.name AS author
         FROM reviews JOIN users ON users.id = reviews.user_id
         WHERE product_id = ? ORDER BY reviews.created_at DESC`,
      )
      .all(id);
    res.json({ success: true, data, count: data.length });
  }),
);

router.put(
  "/products/:id/reviews",
  requireAuth,
  handle((req, res) => {
    const id = positiveInt(req.params.id);
    products.requireProduct(id);
    const { rating } = req.body;
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      throw invalid("rating", "Choose a rating from 1 to 5.");
    }
    const comment = req.body.comment
      ? text(req.body.comment, "comment", { max: 1000, label: "Comment" })
      : "";
    db.prepare(
      `INSERT INTO reviews (product_id, user_id, rating, comment, created_at) VALUES (?, ?, ?, ?, ?)
       ON CONFLICT (product_id, user_id) DO UPDATE SET rating = excluded.rating, comment = excluded.comment`,
    ).run(id, req.user.id, rating, comment, new Date().toISOString());
    res.json({ success: true, data: { rating, comment } });
  }),
);

router.get(
  "/categories",
  handle((req, res) => {
    const data = [...new Set(products.all().map((p) => p.category))];
    res.json({ success: true, data, count: data.length });
  }),
);

router.get(
  "/categories/:category",
  handle((req, res) => {
    const { category } = req.params;
    const data = products
      .list({ category, minPrice: null, maxPrice: null })
      .map(products.summary);
    res.json({ success: true, data, count: data.length, category });
  }),
);

const FEATURED_LIMIT = 3;

router.get(
  "/featured",
  handle((req, res) => {
    const data = products
      .all()
      .filter((p) => p.featured)
      .slice(0, FEATURED_LIMIT)
      .map(products.summary);
    res.json({ success: true, data, count: data.length });
  }),
);

module.exports = router;
