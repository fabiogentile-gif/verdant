process.env.NODE_ENV = "test";
process.env.DATABASE_PATH = ":memory:";
process.env.JWT_SECRET = "test-secret";

const assert = require("node:assert/strict");
const { test } = require("node:test");
const request = require("supertest");
const app = require("../src/app");
const { db } = require("../src/db");
const mailer = require("../src/services/mailer");
const { sendDueEmails } = require("../src/services/reminders");

let counter = 0;
async function signUp() {
  counter += 1;
  const email = `user${counter}@example.com`;
  const res = await request(app)
    .post("/api/auth/register")
    .send({ name: "Sam", email, password: "growing-green" })
    .expect(201);
  return { email, token: res.body.data.token, id: res.body.data.user.id };
}
const bearer = (token) => ["Authorization", `Bearer ${token}`];
const address = {
  fullName: "Sam Doe",
  street: "1 Leaf Road",
  city: "Rome",
  postalCode: "00100",
  country: "Italy",
  phone: "+39 000",
  email: "sam@example.com",
};
const orderBody = (extra = {}) => ({
  items: [{ productId: 1, quantity: 1 }],
  shipping: "standard",
  address,
  paymentTitle: "Visa ending in 1090",
  ...extra,
});

test("products: filters, sorts, paginates and returns summaries", async () => {
  const all = await request(app).get("/api/products").expect(200);
  assert.equal(all.body.count, 16);
  const outdoor = all.body.data.filter((p) => p.tags.some((t) => t.label === "Outdoor"));
  assert.equal(outdoor.length, 3);
  assert.ok(outdoor.every((p) => p.category === "plants"));
  assert.equal(all.body.data[0].careSteps, undefined);

  const plants = await request(app).get("/api/products?category=plants&sort=price_desc");
  const prices = plants.body.data.map((p) => p.price);
  assert.deepEqual(prices, [...prices].sort((a, b) => b - a));

  const page = await request(app).get("/api/products?page=2&limit=4").expect(200);
  assert.equal(page.body.count, 4);
  assert.equal(page.body.pagination.pages, 4);

  const featured = await request(app).get("/api/featured");
  assert.ok(featured.body.count <= 3);
});

test("products: invalid ids get 400, unknown routes 404, images are served", async () => {
  await request(app).get("/api/products/abc").expect(400);
  await request(app).get("/api/products/999").expect(404);
  await request(app).get("/api/nope").expect(404);
  await request(app).get("/static/products/product_white_orchid.png").expect(200);
  await request(app).get("/product_white_orchid.png").expect(301);
});

test("catalogue: every product image and related product exists", async () => {
  const { body } = await request(app).get("/api/products");
  for (const { id, image } of body.data) {
    await request(app).get(image).expect(200);
    const details = await request(app).get(`/api/products/${id}`).expect(200);
    assert.ok(details.body.data.related.length > 0, `product ${id} has no related items`);
  }
});

test("auth: register, login, profile, logout revokes the token", async () => {
  const { email, token } = await signUp();
  await request(app)
    .post("/api/auth/register")
    .send({ name: "Sam", email: email.toUpperCase(), password: "another-pass" })
    .expect(409);
  await request(app).post("/api/auth/login").send({ email, password: "wrong-pass" }).expect(401);
  const login = await request(app)
    .post("/api/auth/login")
    .send({ email, password: "growing-green" })
    .expect(200);
  assert.equal(login.body.data.user.password_hash, undefined);

  const me = await request(app)
    .patch("/api/me")
    .set(...bearer(token))
    .send({ name: "Sam B", location: "Rome" })
    .expect(200);
  assert.equal(me.body.data.location, "Rome");

  await request(app).post("/api/auth/logout").set(...bearer(token)).expect(204);
  await request(app).get("/api/me").set(...bearer(token)).expect(401);
});

test("auth: changing the password signs out other devices", async () => {
  const { email, token } = await signUp();
  const other = await request(app).post("/api/auth/login").send({ email, password: "growing-green" });
  await request(app)
    .post("/api/me/password")
    .set(...bearer(token))
    .send({ currentPassword: "growing-green", newPassword: "brand-new-pass" })
    .expect(204);
  await request(app).get("/api/me").set(...bearer(other.body.data.token)).expect(401);
  await request(app).get("/api/me").set(...bearer(token)).expect(200);
});

test("data is isolated between users and the wallet rejects card numbers", async () => {
  const a = await signUp();
  const b = await signUp();
  await request(app)
    .put("/api/sync/favorites")
    .set(...bearer(a.token))
    .send({ value: [1, 2] })
    .expect(200);
  const other = await request(app).get("/api/favorites").set(...bearer(b.token));
  assert.deepEqual(other.body.data, []);
  await request(app)
    .put("/api/sync/wallet")
    .set(...bearer(a.token))
    .send({ value: { methods: [{ type: "card", id: "1", last4: "1090", number: "5123837273211090" }] } })
    .expect(422);
});

test("orders: server prices, one-time code, idempotency, stock", async () => {
  const { token } = await signUp();
  const before = (await request(app).get("/api/products/1")).body.data;
  const body = orderBody({
    discountCode: "grow10",
    idempotencyKey: "abc",
    items: [{ productId: 1, quantity: 1, unitPrice: 0.01 }],
  });
  const first = await request(app).post("/api/orders").set(...bearer(token)).send(body).expect(201);
  assert.equal(first.body.data.subtotal, before.price);
  assert.equal(first.body.data.discountAmount, Math.round(before.price * 10) / 100);

  const retry = await request(app).post("/api/orders").set(...bearer(token)).send(body).expect(200);
  assert.equal(retry.body.data.number, first.body.data.number);
  const after = (await request(app).get("/api/products/1")).body.data;
  assert.equal(after.stock, before.stock - 1);

  await request(app)
    .post("/api/discounts/validate")
    .set(...bearer(token))
    .send({ code: "GROW10" })
    .expect(422);
});

test("orders: a failed order leaves the stock untouched", async () => {
  const { token } = await signUp();
  const before = (await request(app).get("/api/products/2")).body.data.stock;
  await request(app)
    .post("/api/orders")
    .set(...bearer(token))
    .send(orderBody({ items: [{ productId: 2, quantity: 1 }], discountCode: "NOPE" }))
    .expect(422);
  assert.equal((await request(app).get("/api/products/2")).body.data.stock, before);
});

test("admin: only admins change products and order status", async () => {
  const user = await signUp();
  await request(app)
    .post("/api/products")
    .set(...bearer(user.token))
    .send({ name: "Fern", price: 10, category: "plants" })
    .expect(403);
  const order = await request(app).post("/api/orders").set(...bearer(user.token)).send(orderBody());
  const stock = (await request(app).get("/api/products/1")).body.data.stock;

  db.prepare("UPDATE users SET role = 'admin' WHERE id = ?").run(user.id);
  const created = await request(app)
    .post("/api/products")
    .set(...bearer(user.token))
    .send({ name: "Fern", price: 10, category: "plants", stock: 2 })
    .expect(201);
  await request(app).delete(`/api/products/${created.body.data.id}`).set(...bearer(user.token)).expect(204);

  await request(app)
    .patch(`/api/orders/${order.body.data.number}/status`)
    .set(...bearer(user.token))
    .send({ status: "cancelled" })
    .expect(200);
  assert.equal((await request(app).get("/api/products/1")).body.data.stock, stock + 1);
});

test("reminder emails are sent once and only when enabled", async () => {
  const { token, email } = await signUp();
  const due = new Date(Date.now() - 60000).toISOString();
  await request(app).put("/api/sync/settings").set(...bearer(token)).send({ value: { email: true } });
  await request(app)
    .put("/api/sync/care_schedule")
    .set(...bearer(token))
    .send({ value: { plans: [{ id: "p1", plantId: "x", kind: "water", email: true, nextDueUtc: due }], completed: [] } });

  const sent = [];
  mailer.setTransport({ sendMail: async (message) => sent.push(message) });
  await sendDueEmails();
  await sendDueEmails();
  mailer.setTransport(null);
  assert.equal(sent.filter((m) => m.to === email).length, 1);
});

test("deleting the account needs the password and removes the data", async () => {
  const { token, id } = await signUp();
  await request(app).put("/api/sync/favorites").set(...bearer(token)).send({ value: [1] });
  await request(app).delete("/api/me").set(...bearer(token)).send({ password: "nope-nope" }).expect(403);
  await request(app).delete("/api/me").set(...bearer(token)).send({ password: "growing-green" }).expect(204);
  const { count } = db.prepare("SELECT COUNT(*) AS count FROM user_data WHERE user_id = ?").get(id);
  assert.equal(count, 0);
});
