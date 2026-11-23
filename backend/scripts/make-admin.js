// Usage: npm run make-admin -- someone@example.com
const { db } = require("../src/db");

const email = process.argv[2];
if (!email) {
  console.error("Usage: npm run make-admin -- <email>");
  process.exit(1);
}
const { changes } = db.prepare("UPDATE users SET role = 'admin' WHERE email = ?").run(email);
if (!changes) {
  console.error("No account with that email.");
  process.exit(1);
}
console.log(`${email} is now an admin.`);
