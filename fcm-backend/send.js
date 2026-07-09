const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const REGISTRATION_TOKEN = "TOKEN";

// Construct a data-only payload to force client-side processing in all app states
const message = {
  data: {
    title: "DeepLink Trigger",
    body: "Tap to open Screen B and launch BottomSheet C",
    route: "screenB/true"
  },
  token: REGISTRATION_TOKEN
};

admin.messaging().send(message)
  .then((response) => {
    console.log("Successfully sent message:", response);
    process.exit(0);
  })
  .catch((error) => {
    console.error("Error sending message:", error);
    process.exit(1);
  });
