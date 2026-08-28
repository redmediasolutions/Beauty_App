import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import {
  sendOrderShippedMessage,
  sendGiftNotificationMessage,
} from "./whatsapp";

export const orderShippedWhatsApp = onDocumentUpdated(
  "Orders/{orderId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    // Only trigger when status changes to shipped
    if (before.status === after.status) return;
    if (after.status !== "shipped") return;

    const phone = after.customer?.phone;

    if (!phone) {
      console.warn(
        `No phone found for order ${event.params.orderId}`
      );
      return;
    }

    try {
      // ==========================================
      // 📦 Shipping Notification (Always)
      // ==========================================
      await sendOrderShippedMessage({
        phone,
        customerName: after.customer?.name || "",
        orderNumber:
          after.orderNumber ||
          String(after.wooOrderId || ""),
        courierName:
          after.tracking?.courier || "",
        trackingNumber:
          after.tracking?.trackingNumber || "",
      });

      console.log(
        `✅ Shipping WhatsApp sent for order ${event.params.orderId}`
      );

      // ==========================================
      // 🎁 Gift Notification (Only if gift added)
      // ==========================================
      if (after.giftAdded === true) {
        await sendGiftNotificationMessage({
          phone,
          orderNumber:
            after.orderNumber ||
            String(after.wooOrderId || ""),
        });

        console.log(
          `🎁 Gift WhatsApp sent for order ${event.params.orderId}`
        );
      }
    } catch (e) {
      console.error(
        `❌ Failed to send WhatsApp for order ${event.params.orderId}`,
        e
      );
    }
  }
);