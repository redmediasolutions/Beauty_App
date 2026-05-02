import { onCall, onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";
import { Request, Response } from "express";

admin.initializeApp();

// =======================================================
// 🔐 MSG91 CONFIG (GLADSKIN)
// =======================================================

const MSG91_AUTH_KEY = "507198AvcFM6KC2X69f344baP1";
const MSG91_WIDGET_ID = "3664446b584a343130353532";

// =======================================================
// 🔐 OTP - SEND
// =======================================================


export const sendGladskinOtp = onRequest(
  { cors: true },
  async (req: Request, res: Response): Promise<void> => {
    try {
      console.log("🔥 sendGladskinOtp triggered");

      // 🔍 Method check
      console.log("📡 Method:", req.method);

      if (req.method !== "POST") {
        console.log("❌ Invalid method");
        res.status(405).json({ error: "Method not allowed" });
        return;
      }

      // 📥 Incoming body
      console.log("📥 Request body:", req.body);

      const { phoneNumber } = req.body;

      if (!phoneNumber) {
        console.log("❌ Missing phone number");
        res.status(400).json({ error: "Phone number required" });
        return;
      }

      // 📱 Clean phone
      let cleanPhone = phoneNumber.replace(/\D/g, "");
      if (cleanPhone.length === 10) cleanPhone = "91" + cleanPhone;

      console.log("📱 Clean phone:", cleanPhone);

      // 🚀 Calling MSG91
      console.log("🚀 Sending request to MSG91...");

      const response = await axios.post(
        "https://api.msg91.com/api/v5/widget/sendOtp",
        {
          widgetId: MSG91_WIDGET_ID,
          identifier: cleanPhone,
        },
        {
          headers: {
            authkey: MSG91_AUTH_KEY,
          },
        }
      );

      console.log("📨 MSG91 response:", response.data);

      const reqId = response.data?.reqId || response.data?.message;

      console.log("✅ OTP sent, reqId:", reqId);

      res.json({
        success: true,
        reqId,
      });
      return;

    } catch (error: any) {
      console.error("🔥 ERROR in sendGladskinOtp:");
      console.error("Message:", error?.message);
      console.error("Response:", error?.response?.data);

      res.status(500).json({ success: false });
      return;
    }
  }
);

// =======================================================
// 🔐 OTP - VERIFY
// =======================================================

// =======================================================
// 🔐 VERIFY OTP
// =======================================================

export const verifyGladskinOtp = onRequest(
  {
    cors: true,
    maxInstances: 10,
    concurrency: 80,
  },
  async (req: Request, res: Response): Promise<void> => {
    const { phoneNumber, otp, reqId } = req.body;

    console.log("📥 Incoming Request:", { phoneNumber, otp, reqId });

    // =========================
    // ❌ VALIDATION
    // =========================
    if (!phoneNumber || !otp || !reqId) {
      console.error("❌ Missing params");
      res.status(400).json({
        success: false,
        message: "Missing phone / otp / reqId",
      });
      return;
    }

    // =========================
    // 📱 FORMAT PHONE
    // =========================
    let cleanPhone = phoneNumber.replace(/\D/g, "");
    if (cleanPhone.length === 10) {
      cleanPhone = "91" + cleanPhone;
    }

    console.log("📱 Clean Phone:", cleanPhone);

    try {
      // =========================
      // 🔥 VERIFY OTP (MSG91)
      // =========================
      console.log("🚀 Sending OTP verify request to MSG91...");

      const msg91Response = await axios.post(
        "https://api.msg91.com/api/v5/widget/verifyOtp",
        {
          widgetId: MSG91_WIDGET_ID,
          mobile: cleanPhone,
          otp: otp,
          reqId: reqId,
        },
        {
          headers: {
            authkey: MSG91_AUTH_KEY,
            "Content-Type": "application/json",
          },
        }
      );

      const msg91Data = msg91Response.data;

      console.log("📨 MSG91 VERIFY RESPONSE:", msg91Data);

      // =========================
      // ❌ OTP FAILED
      // =========================
      if (msg91Data.type !== "success") {
        console.error("❌ OTP verification failed:", msg91Data);

        res.status(400).json({
          success: false,
          message: msg91Data.message || "Invalid OTP",
          debug: msg91Data,
        });
        return;
      }

      // =========================
      // 🔥 FIREBASE USER HANDLING
      // =========================
      const db = admin.firestore();

      let userRecord: admin.auth.UserRecord;
      let isNewUser = false;

      try {
        console.log("🔍 Checking existing user...");
        userRecord = await admin
          .auth()
          .getUserByPhoneNumber("+" + cleanPhone);

        console.log("✅ Existing user found:", userRecord.uid);
      } catch (e) {
        console.log("🆕 User not found, creating new user...");

        userRecord = await admin.auth().createUser({
          phoneNumber: "+" + cleanPhone,
        });

        isNewUser = true;

        console.log("✅ New user created:", userRecord.uid);
      }

      // =========================
      // 🔥 ENSURE FIRESTORE DOC
      // =========================
      const userDocRef = db.collection("Users").doc(userRecord.uid);

      console.log("📍 Checking user doc:", userDocRef.path);

      const userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        console.log("🆕 Creating new user document...");

        await userDocRef.set(
          {
            uid: userRecord.uid,
            phone_number: "+" + cleanPhone,
            display_name: "",
            email: "",
            isUserProfileComplete: false,

            created_time: admin.firestore.FieldValue.serverTimestamp(),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),

            referralCode: null,
            referredBy: null,
            referredByPhone: null,
            referredByUserId: null,
            referralUpdatedAt: null,

            walletBalance: 0,
            walletTotalEarned: 0,
            walletTotalUsed: 0,
            rewardPoints: 0,

            fcmToken: null,
            lastSelectedAddress: null,
          },
          { merge: true }
        );
      } else {
        await userDocRef.update({
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log("✅ Existing user updated");
      }

      // =========================
      // 🔐 CREATE TOKEN
      // =========================
      console.log("🔐 Creating custom token...");

      const customToken = await admin
        .auth()
        .createCustomToken(userRecord.uid);

      console.log("✅ Token created, sending response");

      res.json({
        success: true,
        token: customToken,
        isNewUser: isNewUser,
      });
      return;
    } catch (error: any) {
      const errMsg =
        (error.response && error.response.data) || error.message;

      console.error("🔥 VERIFY OTP ERROR:", errMsg);

      res.status(500).json({
        success: false,
        error: "Internal Server Error",
        details: errMsg,
      });
      return;
    }
  }
);

// =======================================================
// 🔐 CONFIG
// =======================================================

const FREE_SHIPPING_THRESHOLD = 499;
const SHIPPING_BELOW_THRESHOLD = 49;
const SHIPPING_ABOVE_THRESHOLD = 0;
const TAX_PERCENTAGE = 0.05;
const COD_CHARGE = 60;

// =======================================================
// 📦 GET CART RATES
// =======================================================

export const getCartRates = onCall(async (request) => {
  const paymentMethod = request.data.paymentMethod || "online";

  return {
    freeShippingThreshold: FREE_SHIPPING_THRESHOLD,
    shippingBelowThreshold: SHIPPING_BELOW_THRESHOLD,
    shippingAboveThreshold: SHIPPING_ABOVE_THRESHOLD,
    taxPercentage: TAX_PERCENTAGE,
    codCharge: paymentMethod === "cod" ? COD_CHARGE : 0,
  };
});

// =======================================================
// 🛒 CREATE SECURE ORDER
// =======================================================

export const createSecureOrder = onCall(async (request) => {
  if (!request.auth) throw new Error("Unauthenticated");

  const uid = request.auth.uid;

  const cartSnap = await admin
    .firestore()
    .collection("carts")
    .doc(uid)
    .collection("items")
    .get();

  if (cartSnap.empty) throw new Error("Cart is empty");

  let subtotal = 0;

  cartSnap.forEach((doc) => {
    const item = doc.data();
    subtotal += (item.salePrice || 0) * (item.quantity || 1);
  });

  const shipping =
    subtotal <= FREE_SHIPPING_THRESHOLD
      ? SHIPPING_BELOW_THRESHOLD
      : SHIPPING_ABOVE_THRESHOLD;

  const tax = subtotal * TAX_PERCENTAGE;
  const codCharge = COD_CHARGE;

  const finalPayable = subtotal + shipping + tax + codCharge;

  return {
    subtotal,
    shipping,
    tax,
    codCharge,
    finalPayable,
  };
});

// =======================================================
// 💳 FINALIZE ORDER
// =======================================================

export const finalizeOrder = onCall(async (request) => {
  if (!request.auth) throw new Error("Unauthenticated");

  const uid = request.auth.uid;

  const {
    billing,
    shipping,
  } = request.data || {};



  const cartRef = admin
    .firestore()
    .collection("carts")
    .doc(uid)
    .collection("items");

  const cartSnap = await cartRef.get();

  if (cartSnap.empty) throw new Error("Cart empty");

  let subtotal = 0;

  cartSnap.forEach((doc) => {
    const item = doc.data();
    subtotal += (item.salePrice || 0) * (item.quantity || 1);
  });

  const shippingAmount =
    subtotal <= FREE_SHIPPING_THRESHOLD
      ? SHIPPING_BELOW_THRESHOLD
      : SHIPPING_ABOVE_THRESHOLD;

  const tax = subtotal * TAX_PERCENTAGE;

  const wooOrder = await createWooOrder({
    uid,
    cartSnap,
    subtotal,
    shipping: shippingAmount,
    tax,
    paymentMethod: "cod",
        billing,
    shippingAddress: shipping,
  });

  const wooOrderId = wooOrder.id;

  await admin.firestore().runTransaction(async (transaction) => {
    cartSnap.forEach((doc) => transaction.delete(doc.ref));

    const orderRef = admin
      .firestore()
      .collection("Orders")
      .doc(String(wooOrderId));

    transaction.set(orderRef, {
      uid,
      wooOrderId,
      subtotal,
      shipping: shippingAmount,
      tax,
      paymentMethod: "cod",
      paymentStatus: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return {
    success: true,
    orderId: wooOrderId,
  };
});

// =======================================================
// 🌐 WOO WEBHOOK
// =======================================================

export const wooOrderStatusWebhook = onRequest(
  async (req: Request, res: Response): Promise<void> => {
    try {
      const order = req.body;

      if (!order?.id) {
        res.status(400).send("Invalid");
        return; // ✅ important
      }

      await admin
        .firestore()
        .collection("Orders")
        .doc(String(order.id))
        .update({
          status: order.status,
        });

      res.status(200).send("OK");
      return; // ✅ explicit return
    } catch (e) {
      console.error(e);
      res.status(500).send("Error");
      return; // ✅ required
    }
  }
);

// =======================================================
// 🛒 CREATE WOO ORDER
// =======================================================

async function createWooOrder({
  uid,
  cartSnap,
  subtotal,
  shipping,
  tax,
  paymentMethod,
  billing,
  shippingAddress,
}: any) {
  const lineItems: any[] = [];

  cartSnap.forEach((doc: any) => {
    const item = doc.data();
    lineItems.push({
      product_id: item.productId,
      quantity: item.quantity || 1,
    });
  });

  const body = {
    payment_method: "cod",
    set_paid: false,
    billing,
    shipping: shippingAddress,
    line_items: lineItems,
  shipping_lines: [

  {

    method_id: "flat_rate:1", // must match your Woo zone

    method_title: "Standard Shipping",

    total: shipping.toFixed(2),

  },

],
    tax_lines: [
      {
        label: "GST",
        tax_total: tax.toFixed(2),
      },
    ],
    meta_data: [{ key: "app_uid", value: uid }],
  };

  const consumerKey = "ck_1f90c93d45a4593f00f89ba5c942001e13898e09";

const consumerSecret = "cs_1c4ddd44c08c3399ecbca3e6e16f1234274ae392";

const url = `https://gs.redmediasolutions.in/wp-json/wc/v3/orders?consumer_key=${consumerKey}&consumer_secret=${consumerSecret}`;

const response = await axios.post(url, body);

  return response.data;
}