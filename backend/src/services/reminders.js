const { db } = require("../db");
const mailer = require("./mailer");

const VERBS = { water: "Water", fertilize: "Fertilize", repot: "Repot" };
const MAX_LATE_MS = 24 * 3600 * 1000;

/** Emails each reminder that came due in the last day, once. Returns how many were sent. */
async function sendDueEmails(now = new Date()) {
  if (!mailer.isEnabled()) return 0;
  const rows = db
    .prepare(
      `SELECT users.id, users.email, users.name, schedule.value AS schedule,
              plants.value AS plants, settings.value AS settings
       FROM users
       JOIN user_data schedule ON schedule.user_id = users.id AND schedule.key = 'care_schedule'
       LEFT JOIN user_data plants ON plants.user_id = users.id AND plants.key = 'plants'
       JOIN user_data settings ON settings.user_id = users.id AND settings.key = 'settings'`,
    )
    .all();

  const claim = db.prepare(
    "INSERT OR IGNORE INTO reminder_emails (user_id, plan_id, due, sent_at) VALUES (?, ?, ?, ?)",
  );
  const release = db.prepare(
    "DELETE FROM reminder_emails WHERE user_id = ? AND plan_id = ? AND due = ?",
  );

  let sent = 0;
  for (const row of rows) {
    if (JSON.parse(row.settings).email !== true) continue;
    const plants = JSON.parse(row.plants ?? "[]");
    for (const plan of JSON.parse(row.schedule).plans ?? []) {
      const due = new Date(plan.nextDueUtc);
      const late = now - due;
      if (!plan.email || !plan.nextDueUtc || Number.isNaN(late) || late < 0 || late > MAX_LATE_MS) {
        continue;
      }
      if (!claim.run(row.id, plan.id, plan.nextDueUtc, now.toISOString()).changes) continue;
      const plant = plants.find((p) => p.id === plan.plantId)?.name ?? "your plant";
      const ok = await mailer.send({
        to: row.email,
        subject: `${VERBS[plan.kind] ?? "Care for"} ${plant} today`,
        text: `Hi ${row.name},\n\n${plan.note ?? "A gentle nudge from Verdant."}\n\nGood things grow with a little care.`,
      });
      if (ok) sent += 1;
      else release.run(row.id, plan.id, plan.nextDueUtc);
    }
  }
  return sent;
}

function startWorker() {
  if (!mailer.isEnabled()) return null;
  const timer = setInterval(() => {
    sendDueEmails().catch((error) => console.error("Reminder emails failed:", error));
  }, 60000);
  timer.unref();
  return timer;
}

module.exports = { sendDueEmails, startWorker };
