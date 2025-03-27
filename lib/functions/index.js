const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendOrderUpdateNotification = functions.firestore
    .document("Orders/{orderId}")
    .onUpdate(async (change, context) => {
        const orderData = change.after.data();
        if (!orderData || !orderData.KitchenorderStatus) return null;

        const status = orderData.KitchenorderStatus;
        const payload = {
            notification: {
                title: "Order Update",
                body: `Your order status is now ${status}.`,
            },
            topic: "Orderstatus" // Sends notification to all users subscribed to "Orderstatus"
        };

        try {
            await admin.messaging().send(payload);
            console.log("✅ Order status notification sent.");
        } catch (error) {
            console.error("🔥 Error sending notification:", error);
        }
        return null;
    });
