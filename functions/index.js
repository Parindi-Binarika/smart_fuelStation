const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.scheduleChargingEnd = functions.firestore
  .document("orders/{orderId}")
  .onCreate(async (snap, context) => {
    const order = snap.data();
    const orderId = context.params.orderId;

    let durationMs = 15 * 60 * 1000;
    if (order.package.includes("30")) durationMs = 30 * 60 * 1000;
    if (order.package.includes("1 hour")) durationMs = 60 * 60 * 1000;

    setTimeout(async () => {
      await admin.firestore().collection("orders").doc(orderId).update({
        status: "Charging Done",
        completedAt: admin.firestore.Timestamp.now(),
      });
    }, durationMs);
  });
