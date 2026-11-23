const nodemailer = require("nodemailer");
const config = require("../config");

let transport = config.smtpUrl ? nodemailer.createTransport(config.smtpUrl) : null;

const isEnabled = () => transport !== null;

/** Lets tests capture messages instead of sending them. */
function setTransport(value) {
  transport = value;
}

/** Sends an email. Returns false when email is off or delivery failed. */
async function send({ to, subject, text }) {
  if (!transport) return false;
  try {
    await transport.sendMail({ from: config.mailFrom, to, subject, text });
    return true;
  } catch (error) {
    console.error("Email failed:", error.message);
    return false;
  }
}

module.exports = { isEnabled, setTransport, send };
