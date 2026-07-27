import axios from "axios";

// =======================================================
// 🔐 CONFIG
// =======================================================

const MSG91_AUTH_KEY = "507198AvcFM6KC2X69f344baP1";
const INTEGRATED_NUMBER = "917019114523";
const MSG91_NAMESPACE =
  "60b3a0a1_7f78_459c_89e4_6d26628e56f3";

// =======================================================
// 📱 FORMAT PHONE
// =======================================================

function formatPhone(phone: string): string {
  let clean = phone.replace(/\D/g, "");

  if (clean.length === 10) {
    clean = "91" + clean;
  }

  return clean;
}

// =======================================================
// 🚀 GENERIC TEMPLATE
// =======================================================

interface WhatsAppTemplateOptions {
  templateName: string;
  phoneNumbers: string[];
  headerImage?: string;
  bodyVariables?: (string | number)[];
}

export async function sendWhatsAppTemplate({
  templateName,
  phoneNumbers,
  headerImage,
  bodyVariables,
}: WhatsAppTemplateOptions) {
  try {
    const components: Record<string, any> = {};

    // Header Image
    if (headerImage) {
      components["header_1"] = {
        type: "image",
        value: headerImage,
      };
    }

    // Body Variables
    bodyVariables?.forEach((value, index) => {
      components[`body_${index + 1}`] = {
        type: "text",
        value: String(value),
      };
    });

    const body = {
      integrated_number: INTEGRATED_NUMBER,

      content_type: "template",

      payload: {
        messaging_product: "whatsapp",

        type: "template",

        template: {
          name: templateName,

          language: {
            code: "en",
            policy: "deterministic",
          },

          namespace: MSG91_NAMESPACE,

          to_and_components: [
            {
              to: phoneNumbers.map(formatPhone),

              components,
            },
          ],
        },
      },
    };

    console.log(
      "📤 WhatsApp Payload:",
      JSON.stringify(body, null, 2)
    );

    const response = await axios.post(
      "https://api.msg91.com/api/v5/whatsapp/whatsapp-outbound-message/bulk/",
      body,
      {
        headers: {
          authkey: MSG91_AUTH_KEY,
          "Content-Type": "application/json",
        },
      }
    );

    console.log("✅ WhatsApp Response:", response.data);

    return response.data;
  } catch (e: any) {
    console.error(
      "❌ WhatsApp Error:",
      e.response?.data || e.message
    );

    throw e;
  }
}

// =======================================================
// 🌸 WELCOME MESSAGE
// =======================================================

export async function sendWelcomeMessage(phone: string) {
  return sendWhatsAppTemplate({
    templateName: "welcomeapp",

    phoneNumbers: [phone],

    headerImage:
      "https://store.gladskin.in/wp-content/uploads/2026/07/Welcome-msg.jpg",
  });
}

// =======================================================
// 📦 ORDER CREATED
// =======================================================

export async function sendOrderCreatedMessage({
  phone,
  customerName,
  orderNumber,
  paymentStatus,
  savings,
}: {
  phone: string;
  customerName: string;
  orderNumber: string;
  paymentStatus: string;
  savings: string | number;
}) {
  return sendWhatsAppTemplate({
    templateName: "ordercreated",

    phoneNumbers: [phone],

    headerImage:
      "https://store.gladskin.in/wp-content/uploads/2026/07/order-received.jpeg",

    bodyVariables: [
      customerName,
      orderNumber,
      paymentStatus,
      savings,
    ],
  });
}

export async function sendOrderShippedMessage({
  phone,
  customerName,
  orderNumber,
  courierName,
  trackingNumber,
}: {
  phone: string;
  customerName: string;
  orderNumber: string;
  courierName: string;
  trackingNumber: string;
}) {
  return sendWhatsAppTemplate({
    templateName: "order_shipped",
    phoneNumbers: [phone],
    headerImage:
      "https://store.gladskin.in/wp-content/uploads/2026/07/Untitled-20-July-2026-at-15.57.02-2.jpeg", // your image
    bodyVariables: [
      customerName,
      orderNumber,
      courierName,
      trackingNumber,
    ],
  });
}