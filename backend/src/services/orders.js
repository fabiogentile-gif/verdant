const crypto = require("crypto");
const { db, transaction } = require("../db");
const { ApiError } = require("../middleware/errors");
const { invalid, text, email, isObject } = require("../utils/validate");
const mailer = require("./mailer");
const products = require("./products");

const SHIPPING = { standard: 6, express: 12 };
const FREE_DELIVERY_FROM = 100;
const MAX_QUANTITY = 99;
const STATUSES = ["placed", "shipped", "delivered", "cancelled"];

const round = (value) => Math.round(value * 100) / 100;

function hasOrders(userId) {
  return Boolean(
    db
      .prepare("SELECT 1 FROM orders WHERE user_id = ? AND status <> 'cancelled' LIMIT 1")
      .get(userId),
  );
}

/** Returns the usable discount for this user, or throws a readable error. */
function findDiscount(userId, rawCode) {
  const code = typeof rawCode === "string" ? rawCode.trim().toUpperCase() : "";
  const row = db
    .prepare("SELECT * FROM discount_codes WHERE code = ? AND active = 1")
    .get(code);
  if (!row) throw invalid("code", "That code doesn’t look right.");
  if (row.first_order_only && hasOrders(userId)) {
    throw invalid("code", "This code is for your first order only.");
  }
  return { code: row.code, label: row.label, rate: row.rate };
}

function parseAddress(value) {
  if (!isObject(value)) throw invalid("address", "Add a delivery address.");
  return {
    fullName: text(value.fullName, "fullName", { label: "Full name" }),
    street: text(value.street, "street", { label: "Street" }),
    city: text(value.city, "city", { label: "City" }),
    postalCode: text(value.postalCode, "postalCode", { max: 20, label: "Postal code" }),
    country: text(value.country, "country", { label: "Country" }),
    phone: text(value.phone, "phone", { max: 40, label: "Phone" }),
    email: email(value.email),
    label: typeof value.label === "string" ? value.label.slice(0, 20) : "Home",
  };
}

function parseItems(value) {
  if (!Array.isArray(value) || value.length === 0 || value.length > 100) {
    throw invalid("items", "Your cart is empty.");
  }
  const quantities = new Map();
  for (const item of value) {
    if (
      !isObject(item) ||
      !Number.isInteger(item.productId) ||
      !Number.isInteger(item.quantity) ||
      item.quantity < 1 ||
      item.quantity > MAX_QUANTITY
    ) {
      throw invalid("items", "Some cart items are not valid.");
    }
    quantities.set(item.productId, (quantities.get(item.productId) ?? 0) + item.quantity);
  }
  return quantities;
}

const toJson = (row) => ({ ...JSON.parse(row.data), number: row.number, status: row.status });

/** Prices, discount and stock all come from the server, never from the client. */
function place(user, body) {
  const key = typeof body.idempotencyKey === "string" ? body.idempotencyKey.slice(0, 80) : null;
  const shipping = Object.hasOwn(SHIPPING, body.shipping) ? body.shipping : null;
  if (!shipping) throw invalid("shipping", "Choose a delivery option.");
  const address = parseAddress(body.address);
  const quantities = parseItems(body.items);
  const paymentTitle = text(body.paymentTitle, "paymentTitle", {
    max: 80,
    label: "Payment method",
  });

  const { order, created } = transaction(() => {
    if (key) {
      const existing = db
        .prepare("SELECT * FROM orders WHERE user_id = ? AND idempotency_key = ?")
        .get(user.id, key);
      if (existing) return { order: toJson(existing), created: false };
    }

    const items = [];
    for (const [productId, quantity] of quantities) {
      const product = products.byId(productId);
      if (!product) throw invalid("items", "A product in your cart is no longer available.");
      if (product.stock < quantity) {
        throw new ApiError(409, `Only ${product.stock} left of ${product.name}.`, {
          code: "out_of_stock",
        });
      }
      products.adjustStock(productId, -quantity);
      items.push({
        productId,
        name: product.name,
        unitPrice: product.price,
        image: product.image,
        variant: product.variantLabel ?? null,
        quantity,
      });
    }

    const subtotal = round(items.reduce((sum, i) => sum + i.unitPrice * i.quantity, 0));
    const discount = body.discountCode ? findDiscount(user.id, body.discountCode) : null;
    const discountAmount = discount ? round(subtotal * discount.rate) : 0;
    const delivery =
      shipping === "standard" && subtotal >= FREE_DELIVERY_FROM ? 0 : SHIPPING[shipping];
    const placedAt = new Date().toISOString();
    const number = `VRD-${crypto.randomInt(100000, 1000000)}${crypto.randomInt(10, 100)}`;
    const data = {
      items,
      subtotal,
      discountLabel: discount ? `${discount.code} · ${Math.round(discount.rate * 100)}% off` : null,
      discountAmount,
      shipping,
      delivery,
      total: round(subtotal - discountAmount + delivery),
      paymentTitle,
      placedAt,
      address,
    };
    db.prepare(
      `INSERT INTO orders (number, user_id, idempotency_key, data, created_at)
       VALUES (?, ?, ?, ?, ?)`,
    ).run(number, user.id, key, JSON.stringify(data), placedAt);
    db.prepare("INSERT INTO notifications (user_id, title, body, created_at) VALUES (?, ?, ?, ?)").run(
      user.id,
      `Order ${number} placed`,
      "Thank you. We’ll let you know when it’s on its way.",
      placedAt,
    );
    return { order: { ...data, number, status: "placed" }, created: true };
  });

  if (created) {
    // Email must never make a successful order look failed.
    void mailer.send({
      to: order.address.email,
      subject: `Your Verdant order ${order.number}`,
      text: `Thank you, ${order.address.fullName}. Your order total is $${order.total.toFixed(2)}.\n\nThis is a demo order: no payment was taken and nothing will ship.`,
    });
  }
  return { order, created };
}

function listFor(userId) {
  return db
    .prepare("SELECT * FROM orders WHERE user_id = ? ORDER BY created_at DESC, rowid DESC")
    .all(userId)
    .map(toJson);
}

function findFor(userId, number) {
  const row = db.prepare("SELECT * FROM orders WHERE user_id = ? AND number = ?").get(userId, number);
  if (!row) throw new ApiError(404, "Order not found", { code: "not_found" });
  return toJson(row);
}

/** Admin: moves an order forward; cancelling puts the items back in stock. */
function setStatus(number, status) {
  if (!STATUSES.includes(status)) throw invalid("status", "Unknown order status.");
  return transaction(() => {
    const row = db.prepare("SELECT * FROM orders WHERE number = ?").get(number);
    if (!row) throw new ApiError(404, "Order not found", { code: "not_found" });
    if (row.status !== status) {
      const delta = status === "cancelled" ? 1 : row.status === "cancelled" ? -1 : 0;
      if (delta) {
        for (const item of JSON.parse(row.data).items) {
          const product = products.byId(item.productId);
          if (delta < 0 && product && product.stock < item.quantity) {
            throw new ApiError(409, `Only ${product.stock} left of ${product.name}.`, {
              code: "out_of_stock",
            });
          }
          products.adjustStock(item.productId, delta * item.quantity);
        }
      }
      db.prepare("UPDATE orders SET status = ? WHERE number = ?").run(status, number);
      db.prepare("INSERT INTO notifications (user_id, title, created_at) VALUES (?, ?, ?)").run(
        row.user_id,
        `Order ${number} is now ${status}`,
        new Date().toISOString(),
      );
    }
    return toJson(db.prepare("SELECT * FROM orders WHERE number = ?").get(number));
  });
}

module.exports = { findDiscount, place, listFor, findFor, setStatus };
