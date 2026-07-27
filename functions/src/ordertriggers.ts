import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import { sendOrderShippedMessage } from "./whatsapp";

export const orderShippedWhatsApp = onDocumentUpdated(
  "Orders/{orderId}",
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();

    if (!before || !after) return;

    // Only trigger when status changes to "shipped"
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
      await sendOrderShippedMessage({
        phone,
        customerName: after.customer?.name || "",
        orderNumber:
          after.orderNumber ||
          String(after.wooOrderId || ""),

        // Read from nested tracking object
        courierName:
          after.tracking?.courier || "",

        trackingNumber:
          after.tracking?.trackingNumber || "",
      });

      console.log(
        `✅ Shipped WhatsApp sent for order ${event.params.orderId}`
      );
    } catch (e) {
      console.error(
        `❌ Failed to send shipped WhatsApp for order ${event.params.orderId}`,
        e
      );
    }
  }
);