/**
 * Sends a data-only FCM push that routes the app to a destination.
 *
 * Data-only (no `notification` block) is deliberate: it guarantees
 * onMessageReceived runs in every app state, so our own PendingIntent with
 * the deep link URI is always the one that gets built. Adding a
 * `notification` block would let the system tray handle the message while
 * the app is backgrounded, bypassing the routing code entirely.
 *
 * Usage:
 *   FCM_TOKEN=<token> node send.js
 *   node send.js --token <token> --route screenB/true --link applink
 *
 * Token resolution order: --token flag, FCM_TOKEN env, ./token.txt
 */
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  return i !== -1 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}

function resolveToken() {
  const flag = arg("token");
  if (flag) return flag.trim();
  if (process.env.FCM_TOKEN) return process.env.FCM_TOKEN.trim();

  const file = path.join(__dirname, "token.txt");
  if (fs.existsSync(file)) {
    const t = fs.readFileSync(file, "utf8").trim();
    if (t) return t;
  }
  return null;
}

const token = resolveToken();
if (!token) {
  console.error(
    "No FCM token.\n" +
      "  Copy it from Screen A, then either:\n" +
      "    echo '<token>' > fcm-backend/token.txt\n" +
      "    FCM_TOKEN=<token> node send.js\n" +
      "    node send.js --token <token>"
  );
  process.exit(1);
}

const route = arg("route", "screenB/true");

// "scheme"  -> app://routing/<route>            unverified deep link
// "applink" -> https://<host>/routing/<route>   verified App Link
const linkType = arg("link", "scheme");
if (!["scheme", "applink"].includes(linkType)) {
  console.error(`--link must be "scheme" or "applink", got "${linkType}"`);
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const message = {
  data: {
    title: linkType === "applink" ? "App Link Trigger" : "Deep Link Trigger",
    body: `Tap to open ${route} via ${linkType}`,
    route,
    linkType,
  },
  android: { priority: "high" },
  token,
};

console.log(`project  : ${serviceAccount.project_id}`);
console.log(`route    : ${route}`);
console.log(`linkType : ${linkType}`);
console.log(`token    : ${token.slice(0, 12)}...${token.slice(-6)}`);

admin
  .messaging()
  .send(message)
  .then((response) => {
    console.log("Sent:", response);
    process.exit(0);
  })
  .catch((error) => {
    console.error("Error sending message:", error.message);
    process.exit(1);
  });
