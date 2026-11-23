const { db } = require("../db");
const { ApiError } = require("../middleware/errors");

function reviewStats(id) {
  return db
    .prepare("SELECT AVG(rating) AS rating, COUNT(*) AS count FROM reviews WHERE product_id = ?")
    .get(id);
}

/** Real reviews replace the placeholder rating of the catalogue once they exist. */
function hydrate(row) {
  const product = JSON.parse(row.data);
  const stats = reviewStats(product.id);
  const stock = Number(product.stock ?? 0);
  return {
    ...product,
    stock,
    inStock: stock > 0,
    rating: stats.count ? Math.round(stats.rating * 10) / 10 : product.rating,
    reviewCount: stats.count || product.reviewCount,
  };
}

const all = () => db.prepare("SELECT * FROM products ORDER BY id").all().map(hydrate);

function byId(id) {
  const row = db.prepare("SELECT * FROM products WHERE id = ?").get(id);
  return row ? hydrate(row) : null;
}

function requireProduct(id) {
  const product = byId(id);
  if (!product) throw new ApiError(404, "Product not found", { code: "not_found" });
  return product;
}

const summary = ({ id, name, price, image, tag, category, tags, rating, featured, inStock }) => ({
  id,
  name,
  price,
  image,
  tag,
  category,
  tags,
  rating,
  featured,
  inStock,
});

const SORTS = {
  price_asc: (a, b) => a.price - b.price,
  price_desc: (a, b) => b.price - a.price,
  name: (a, b) => a.name.localeCompare(b.name),
  rating: (a, b) => (b.rating ?? 0) - (a.rating ?? 0),
};

function list({ category, search, sort, minPrice, maxPrice }) {
  if (sort && !SORTS[sort]) {
    throw new ApiError(400, "Invalid sort", { code: "bad_request" });
  }
  const needle = search?.trim().toLowerCase();
  const result = all().filter(
    (p) =>
      (!category || p.category === category) &&
      (minPrice === null || p.price >= minPrice) &&
      (maxPrice === null || p.price <= maxPrice) &&
      (!needle ||
        [p.name, p.summary, p.tag, ...(p.tags ?? []).map((t) => t.label)]
          .filter(Boolean)
          .some((value) => value.toLowerCase().includes(needle))),
  );
  return sort ? result.sort(SORTS[sort]) : result;
}

function details(id) {
  const { relatedIds = [], ...rest } = requireProduct(id);
  const related = relatedIds.map(byId).filter(Boolean).map(summary);
  return { ...rest, related };
}

function validateBody(body, { partial = false } = {}) {
  const fail = (field, message) => {
    throw new ApiError(422, message, { code: "validation", fields: { [field]: message } });
  };
  if (!partial || body.name !== undefined) {
    if (typeof body.name !== "string" || !body.name.trim()) fail("name", "Name is required.");
  }
  if (!partial || body.price !== undefined) {
    if (typeof body.price !== "number" || !(body.price >= 0)) fail("price", "Invalid price.");
  }
  if (!partial || body.category !== undefined) {
    if (typeof body.category !== "string" || !body.category.trim()) {
      fail("category", "Category is required.");
    }
  }
  if (body.stock !== undefined && (!Number.isInteger(body.stock) || body.stock < 0)) {
    fail("stock", "Invalid stock.");
  }
  const { id: _id, inStock: _inStock, related: _related, ...clean } = body;
  return clean;
}

function create(body) {
  const clean = validateBody(body);
  const product = { image: "", images: [], stock: 0, featured: false, ...clean };
  const { lastInsertRowid } = db
    .prepare("INSERT INTO products (data) VALUES (?)")
    .run(JSON.stringify(product));
  const id = Number(lastInsertRowid);
  db.prepare("UPDATE products SET data = ? WHERE id = ?").run(
    JSON.stringify({ ...product, id }),
    id,
  );
  return byId(id);
}

function update(id, body) {
  const row = db.prepare("SELECT data FROM products WHERE id = ?").get(id);
  if (!row) throw new ApiError(404, "Product not found", { code: "not_found" });
  const merged = { ...JSON.parse(row.data), ...validateBody(body, { partial: true }), id };
  db.prepare("UPDATE products SET data = ? WHERE id = ?").run(JSON.stringify(merged), id);
  return byId(id);
}

function remove(id) {
  const { changes } = db.prepare("DELETE FROM products WHERE id = ?").run(id);
  if (!changes) throw new ApiError(404, "Product not found", { code: "not_found" });
}

/** Adds [delta] to the stock. Must run inside a transaction. */
function adjustStock(id, delta) {
  const row = db.prepare("SELECT data FROM products WHERE id = ?").get(id);
  if (!row) return;
  const product = JSON.parse(row.data);
  product.stock = Number(product.stock ?? 0) + delta;
  db.prepare("UPDATE products SET data = ? WHERE id = ?").run(JSON.stringify(product), id);
}

module.exports = { all, byId, requireProduct, summary, list, details, create, update, remove, adjustStock };
