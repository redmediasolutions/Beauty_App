import { onCall, onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import Razorpay from "razorpay";
import crypto from "crypto";
import axios from "axios";
import { sendOrderCreatedMessage } from "./whatsapp";

// =======================================================
// 🔐 CENTRAL RATE CONFIG
// =======================================================

interface CheckoutSettings {
  shippingThreshold: number;
  shippingChargeBelowThreshold: number;
  shippingChargeAboveThreshold: number;
  codThreshold: number;
  codChargeBelowThreshold: number;
  codChargeAboveThreshold: number;
}

async function getCheckoutSettings(): Promise<CheckoutSettings> {
  const snap = await admin
    .firestore()
    .collection("app_settings")
    .doc("checkout")
    .get();

  const data = snap.data() ?? {};

  return {
    shippingThreshold: Number(data.shipping_threshold ?? 499),
    shippingChargeBelowThreshold: Number(
      data.shipping_charge_below_threshold ?? 49
    ),
    shippingChargeAboveThreshold: Number(
      data.shipping_charge_above_threshold ?? 0
    ),
    codThreshold: Number(data.cod_threshold ?? 999),
    codChargeBelowThreshold: Number(data.cod_charge_below_threshold ?? 49),
    codChargeAboveThreshold: Number(data.cod_charge_above_threshold ?? 29),
  };
}

// =======================================================
// 🔐 CALCULATION LOGIC
// =======================================================

async function calculateCartTotals({
  uid,
  paymentMethod,
  useWallet,
  walletAmount = 0,
  couponDiscount = 0,
}: {
  uid: string;
  paymentMethod: string;
  useWallet: boolean;
  walletAmount?: number;
  couponDiscount?: number;
}) {
  const to2 = (value: number) => Number(value.toFixed(2));

  const settings = await getCheckoutSettings();

  const cartSnap = await admin
    .firestore()
    .collection("carts")
    .doc(uid)
    .collection("items")
    .get();

  let subtotal = 0;
  let totalMrp = 0;
  let productSavings = 0;

  const gstSubtotals: Record<number, number> = {};

  // =====================================
  // CART LOOP
  // =====================================

  cartSnap.forEach((doc) => {
    const item = doc.data();

    const qty = Number(item.quantity || 1);
    const mrp = Number(item.mrp || 0);
    const salePrice = Number(item.salePrice || mrp);
    const lineTotal = salePrice * qty;

    subtotal += lineTotal;
    totalMrp += mrp * qty;
    productSavings += (mrp - salePrice) * qty;

    // =====================================
    // GST RATE LOGIC
    // SAME AS CART PAGE
    // =====================================

    let gstRate = Number(item.taxRate ?? item.TaxRate ?? 0);

    if (gstRate <= 0) {
      const taxClass = String(item.taxClass || "").toLowerCase();

      if (taxClass === "reduced-rate") {
        gstRate = 5;
      } else {
        gstRate = 18;
      }
    }

    gstSubtotals[gstRate] = (gstSubtotals[gstRate] || 0) + lineTotal;

    console.log(`${item.name} => GST ${gstRate}% => ₹${lineTotal}`);
  });

  subtotal = to2(subtotal);
  totalMrp = to2(totalMrp);
  productSavings = to2(productSavings);

  // =====================================
  // SHIPPING
  // SAME AS CART PAGE
  // =====================================

  const shipping =
    subtotal >= settings.shippingThreshold
      ? settings.shippingChargeAboveThreshold
      : settings.shippingChargeBelowThreshold;

  // =====================================
  // COUPON
  // =====================================

  couponDiscount = to2(couponDiscount);

  const taxableBreakup: Record<number, number> = {};
  const gstBreakup: Record<number, number> = {};

  let tax = 0;

  // =====================================
  // GST BREAKUP
  // =====================================

  for (const [rateStr, amount] of Object.entries(gstSubtotals)) {
    const rate = Number(rateStr);
    const taxableAmount = amount;
    const gstAmount = taxableAmount * (rate / 100);

    taxableBreakup[rate] = to2(taxableAmount);
    gstBreakup[rate] = to2(gstAmount);

    tax += gstAmount;
  }

  tax = to2(tax);

  // =====================================
  // SUBTOTAL AFTER DISCOUNT
  // =====================================

  const discountedSubtotal = subtotal;

  // =====================================
  // COD
  // SAME AS CART PAGE
  // =====================================

  const codCharge =
    paymentMethod === "cod"
      ? discountedSubtotal >= settings.codThreshold
        ? settings.codChargeAboveThreshold
        : settings.codChargeBelowThreshold
      : 0;

  // =====================================
  // TOTALS
  // =====================================

  const grossTotal = to2(subtotal + tax + shipping + codCharge);

  const userDoc = await admin.firestore().collection("Users").doc(uid).get();

  const walletBalance = Number(userDoc.data()?.walletBalance || 0);

  const walletUsed = useWallet
    ? to2(Math.min(walletAmount, walletBalance, grossTotal))
    : 0;

  const finalPayable = to2(grossTotal - couponDiscount - walletUsed);

  return {
    subtotal,
    totalMrp,
    productSavings,
    gstSubtotals,
    taxableBreakup,
    gstBreakup,
    taxable18: taxableBreakup[18] || 0,
    taxable5: taxableBreakup[5] || 0,
    gst18: gstBreakup[18] || 0,
    gst5: gstBreakup[5] || 0,
    tax,
    couponDiscount,
    shipping,
    codCharge,
    discountedSubtotal,
    discountedTotal: to2(grossTotal - couponDiscount),
    walletBalance,
    walletUsed,
    grossTotal,
    finalPayable,
    cartSnap,
  };
}

// =======================================================
// 📦 GET CART RATES
// =======================================================

export const getCartRates = onCall(
  {
    maxInstances: 10,
    concurrency: 80,
  },
  async (request) => {
    const settings = await getCheckoutSettings();

    return {
      freeShippingThreshold: settings.shippingThreshold,
      shippingBelowThreshold: settings.shippingChargeBelowThreshold,
      shippingAboveThreshold: settings.shippingChargeAboveThreshold,
      codThreshold: settings.codThreshold,
      codChargeBelowThreshold: settings.codChargeBelowThreshold,
      codChargeAboveThreshold: settings.codChargeAboveThreshold,
    };
  }
);

// =======================================================
// 👀 CART PREVIEW TOTALS
// =======================================================

export const getCartPreviewTotals = onCall(
  {
    maxInstances: 10,
    concurrency: 80,
  },
  async (request) => {
    if (!request.auth) {
      throw new Error("Unauthenticated");
    }

    const uid = request.auth.uid;
    const data = request.data as any;

    const paymentMethod = data.paymentMethod || "online";
    const useWallet = data.useWallet === true;
    const walletAmount = Number(data.walletAmount || 0);

    const couponDiscount =
      Math.round(Number(data.couponDiscount || 0) * 100) / 100;

    // =====================================
    // USE SAME CALCULATION ENGINE
    // AS CART + CREATE ORDER
    // =====================================

    const totals = await calculateCartTotals({
      uid,
      paymentMethod,
      useWallet,
      walletAmount,
      couponDiscount,
    });

    return {
      // ==========================
      // PRODUCT TOTALS
      // ==========================
      subtotal: totals.subtotal,
      totalMrp: totals.totalMrp,
      productSavings: totals.productSavings,

      // ==========================
      // COUPON
      // ==========================
      couponDiscount: totals.couponDiscount,
      discountedSubtotal: totals.discountedSubtotal,

      // ==========================
      // GST
      // ==========================
      gst18: totals.gst18,
      gst5: totals.gst5,
      taxable18: totals.taxable18,
      taxable5: totals.taxable5,
      tax: totals.tax,
      gstBreakup: totals.gstBreakup,
      taxableBreakup: totals.taxableBreakup,

      // ==========================
      // SHIPPING / COD
      // ==========================
      shipping: totals.shipping,
      codCharge: totals.codCharge,

      // ==========================
      // WALLET
      // ==========================
      walletBalance: totals.walletBalance,
      walletUsed: totals.walletUsed,

      // ==========================
      // TOTALS
      // ==========================
      grossTotal: totals.grossTotal,
      discountedTotal: totals.discountedTotal,
      finalPayable: totals.finalPayable,
    };
  }
);

// =======================================================
// 🛒 CREATE SECURE ORDER
// =======================================================

export const createSecureOrder = onCall(
  {
    secrets: ["RAZORPAY_KEY_ID", "RAZORPAY_KEY_SECRET"],
    maxInstances: 10,
    concurrency: 80,
  },
  async (request) => {
    // =========================================
    // 🔐 AUTH
    // =========================================

    if (!request.auth) {
      throw new Error("Unauthenticated");
    }

    const uid = request.auth.uid;
    const data = request.data as any;

    // =========================================
    // 🎟 COUPON DATA
    // =========================================

    const couponId = data.couponId || null;
    const couponCode = data.couponCode || null;
    const useWallet = data.useWallet === true;

    const couponDiscount =
      Math.round(Number(data.couponDiscount || 0) * 100) / 100;

    // =========================================
    // 💳 PAYMENT
    // =========================================

    const paymentMethod = data.paymentMethod || "online";
    const walletAmount = Number(data.walletAmount || 0);

    // =========================================
    // 🧮 CALCULATE TOTALS
    // =========================================

    const totals = await calculateCartTotals({
      uid,
      paymentMethod,
      useWallet,
      walletAmount,
      couponDiscount,
    });

    const {
      subtotal,
      shipping,
      tax,
      codCharge,
      grossTotal,
      discountedTotal,
      walletBalance,
      walletUsed,
      finalPayable,
      cartSnap,
    } = totals;

    if (cartSnap.empty) {
      throw new Error("Cart is empty");
    }

    // =========================================
    // 💳 CREATE RAZORPAY ORDER
    // =========================================

    let razorpayOrderId = null;
    let razorpayAmount = null;

    if (paymentMethod === "online" && finalPayable > 0) {
      console.log("===== RAZORPAY TOTALS =====");
      console.log("subtotal:", subtotal);
      console.log("couponDiscount:", couponDiscount);
      console.log("tax:", tax);
      console.log("shipping:", shipping);
      console.log("walletUsed:", walletUsed);
      console.log("grossTotal:", grossTotal);
      console.log("finalPayable:", finalPayable);
      console.log("===========================");

      const razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID!,
        key_secret: process.env.RAZORPAY_KEY_SECRET!,
      });

      const order = await razorpay.orders.create({
        amount: Math.round(finalPayable * 100),
        currency: "INR",
        receipt: `gladskin_${Date.now()}`,
        notes: {
          uid,
          couponCode: couponCode || "",
          couponDiscount: couponDiscount.toString(),
        },
      });

      razorpayOrderId = order.id;
      razorpayAmount = order.amount;
    }

    // =========================================
    // 🔥 SAVE DRAFT ORDER
    // =========================================

    const orderRef = admin.firestore().collection("Orders").doc();

    await orderRef.set({
      uid,
      subtotal,
      taxableBreakup: totals.taxableBreakup,
      shipping,
      tax,
      codCharge,
      grossTotal,

      // =====================================
      // 🎟 COUPON
      // =====================================
      couponId,
      couponCode,
      couponDiscount,
      discountedTotal,

      // =====================================
      // 👛 WALLET
      // =====================================
      walletBalance,
      walletUsed,

      // =====================================
      // 💳 PAYMENT
      // =====================================
      paymentMethod,
      finalPayable,
      razorpayOrderId,
      razorpayAmount,
      paymentStatus: paymentMethod === "cod" ? "pending" : "created",
      status: "processing",

      // =====================================
      // 🛒 ITEMS SNAPSHOT
      // =====================================
      items: cartSnap.docs.map((doc) => {
        const item = doc.data();

        let taxRate = Number(item.taxRate ?? item.TaxRate ?? 0);

        // =====================================
        // GST FALLBACK
        // =====================================
        if (taxRate <= 0) {
          const taxClass = String(item.taxClass || "").toLowerCase();
          taxRate = taxClass === "reduced-rate" ? 5 : 18;
        }

        return {
          productId: item.productId,
          name: item.name || "",
          image: item.image || "",
          quantity: item.quantity || 1,
          salePrice: item.salePrice || 0,
          mrp: item.mrp || 0,
          taxClass: item.taxClass || "",
          taxRate,
        };
      }),

      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // =========================================
    // ✅ RESPONSE
    // =========================================

    return {
      success: true,
      orderId: orderRef.id,
      subtotal,
      shipping,
      tax,
      codCharge,
      grossTotal,
      discountedTotal,
      couponId,
      couponCode,
      couponDiscount,
      walletBalance,
      walletUsed,
      finalPayable,
      razorpayOrderId,
      razorpayAmount,
      razorpayKey:
        paymentMethod === "online" ? process.env.RAZORPAY_KEY_ID : null,
    };
  }
);

// =======================================================
// 💳 FINALIZE ORDER
// =======================================================

export const finalizeOrder = onCall(
  {
    secrets: ["RAZORPAY_KEY_SECRET", "WOO_KEY", "WOO_SECRET"],
    maxInstances: 10,
    concurrency: 80,
  },
  async (request) => {
    try {
      // ===================================================
      // 🔐 AUTH
      // ===================================================
      if (!request.auth) {
        throw new Error("Unauthenticated");
      }

      const uid = request.auth.uid;
      const userEmail = (request.auth.token as any)?.email || "";
      const data = request.data as any;
      const useWallet = data.useWallet === true;

      const {
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
        billing,
        shipping: shippingAddress,
      } = data;

      if (!billing || !shippingAddress) {
        throw new Error("Billing or Shipping missing");
      }

      const isOnlinePayment =
        razorpayOrderId && razorpayPaymentId && razorpaySignature;

      const walletAmount = Number(data.walletAmount || 0);

      // ===================================================
      // 🔐 VERIFY PAYMENT
      // ===================================================
      if (isOnlinePayment) {
        const body = razorpayOrderId + "|" + razorpayPaymentId;
        const expectedSignature = crypto
          .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET!)
          .update(body)
          .digest("hex");

        if (expectedSignature !== razorpaySignature) {
          throw new Error("Invalid Payment Signature");
        }
      }

      // ===================================================
      // 🎟 COUPON & TOTALS
      // ===================================================
      const couponId = data.couponId || null;
      const couponCode = data.couponCode || null;
      const couponDiscount =
        Math.round(Number(data.couponDiscount || 0) * 100) / 100;

      const totals = await calculateCartTotals({
        uid,
        paymentMethod: isOnlinePayment ? "online" : "cod",
        useWallet,
        walletAmount,
        couponDiscount,
      });

      const {
        subtotal,
        shipping,
        taxableBreakup,
        gstBreakup,
        tax,
        codCharge,
        grossTotal,
        discountedTotal,
        walletBalance,
        walletUsed,
        finalPayable,
        cartSnap,
      } = totals;

      const rewardAmount = Math.round(subtotal * 0.2 * 100) / 100;

      // ===================================================
      // 🌐 CREATE WOO ORDER
      // ===================================================
      const wooOrder = await createWooOrder({
        uid,
        cartSnap,
        subtotal,
        shipping,
        taxableBreakup,
        gstBreakup,
        tax,
        codCharge,
        walletUsed,
        finalPayable,
        paymentMethod: isOnlinePayment ? "online" : "cod",
        razorpayOrderId,
        razorpayPaymentId,
        billing,
        shippingAddress,
        couponCode,
        couponDiscount,
      });

      if (!wooOrder?.id) {
        throw new Error("Woo order failed");
      }

      const wooOrderId = wooOrder.id;

      // ===================================================
      // 🔍 PRE-TRANSACTION READS (Referral Check)
      // ===================================================
      const userRef = admin.firestore().collection("Users").doc(uid);
      const buyerSnap = await userRef.get();
      const buyerData = buyerSnap.data();
      let referrerUid = null;

      if (buyerData && buyerData.referredBy) {
        const referrerSnap = await admin
          .firestore()
          .collection("Users")
          .where("referralCode", "==", buyerData.referredBy)
          .limit(1)
          .get();

        if (!referrerSnap.empty) {
          referrerUid = referrerSnap.docs[0].id;
        }
      }

      // References for the transaction
      const invoiceCounterRef = admin
        .firestore()
        .collection("app_settings")
        .doc("invoice_counter");
      const orderRef = admin
        .firestore()
        .collection("Orders")
        .doc(String(wooOrderId));

      let invoiceNumber = "";

      // ===================================================
      // 🔥 SINGLE ATOMIC TRANSACTION
      // ===================================================
      await admin.firestore().runTransaction(async (transaction) => {
        // 1. READ: Get the current invoice counter state
        const counterSnap = await transaction.get(invoiceCounterRef);
        const lastNumber = counterSnap.exists
          ? Number(counterSnap.data()?.lastNumber ?? 0)
          : 0;
        const nextNumber = lastNumber + 1;

        invoiceNumber = `GLAD-16${nextNumber.toString().padStart(2, "0")}`;

        // 2. WRITE: Update invoice counter
        transaction.set(
          invoiceCounterRef,
          { lastNumber: nextNumber },
          { merge: true }
        );

        // 3. WRITE: Deduct Wallet if used
        if (walletUsed > 0) {
          transaction.update(userRef, {
            walletBalance: admin.firestore.FieldValue.increment(-walletUsed),
          });
        }

        // 4. WRITE: Clear Cart Items
        cartSnap.forEach((doc) => {
          transaction.delete(doc.ref);
        });

        // 5. WRITE: Save the Order with the new invoice number
        transaction.set(orderRef, {
          uid,
          wooOrderId,
          subtotal,
          shipping,
          gstBreakup,
          taxableBreakup,
          tax,
          codCharge,
          grossTotal,
          discountedTotal,
          walletBalance,
          walletUsed,
          finalPayable,
          couponId,
          couponCode,
          couponDiscount,
          paymentMethod: isOnlinePayment ? "online" : "cod",
          paymentStatus: isOnlinePayment ? "paid" : "pending",
          razorpayOrderId: razorpayOrderId || null,
          razorpayPaymentId: razorpayPaymentId || null,
          rewardAmount,
          rewardReleased: false,
          rewardReversed: false,
          rewardReleasedAt: null,
          referralRewardGivenTo: referrerUid,
          orderNumber: invoiceNumber, // Saved cleanly here
          status: "processing",
          wooStatus: "processing",
          wooCreatedAt: admin.firestore.Timestamp.now(),
          wooUpdatedAt: admin.firestore.Timestamp.now(),
          customer: {
            uid,
            name: billing.first_name || "",
            phone: billing.phone || "",
            email: userEmail,
          },
          statusHistory: [
            {
              status: "processing",
              at: admin.firestore.Timestamp.now(),
            },
          ],
          trackingNumber: null,
          trackingUrl: null,
          courierName: null,
          shippedAt: null,
          deliveredAt: null,
          paymentCapturedAt: isOnlinePayment
            ? admin.firestore.Timestamp.now()
            : null,
          referralRewardStatus: rewardAmount > 0 ? "pending" : "none",
          itemCount: cartSnap.docs.length,
          totalQuantity: cartSnap.docs.reduce(
            (sum, doc) => sum + Number(doc.data().quantity || 1),
            0
          ),
          coupon: { id: couponId, code: couponCode, discount: couponDiscount },
          items: cartSnap.docs.map((doc) => {
            const item = doc.data();
            const qty = Number(item.quantity || 1);
            const mrp = Number(item.mrp || 0);
            const salePrice = Number(item.salePrice || mrp);
            let taxRate = Number(item.taxRate ?? item.TaxRate ?? 0);

            if (taxRate <= 0) {
              const taxClass = String(item.taxClass || "").toLowerCase();
              taxRate = taxClass === "reduced-rate" ? 5 : 18;
            }

            const lineSubtotal = Number((salePrice * qty).toFixed(2));
            const lineTax = Number((lineSubtotal * (taxRate / 100)).toFixed(2));
            const lineTotal = Number((lineSubtotal + lineTax).toFixed(2));

            return {
              productId: item.productId,
              name: item.name || "",
              image: item.image || "",
              brand: item.brand || "",
              packing: item.packing || "",
              quantity: qty,
              mrp,
              salePrice,
              taxStatus: item.taxStatus || "taxable",
              taxClass: item.taxClass || "",
              taxRate,
              lineSubtotal,
              lineTax,
              lineTotal,
            };
          }),
          billing,
          shippingAddress,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 6. WRITE: Create Referral reward document if applicable
        if (referrerUid && rewardAmount > 0) {
          const pendingTxRef = admin
            .firestore()
            .collection("Users")
            .doc(referrerUid)
            .collection("walletTransactions")
            .doc(String(wooOrderId));

          transaction.set(pendingTxRef, {
            type: "credit",
            source: "referral_reward",
            orderId: wooOrderId,
            amount: rewardAmount,
            status: "pending",
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
      });

      // ===================================================
      // 📲 SEND ORDER CREATED WHATSAPP
      // ===================================================

      try {
        const paymentStatus = isOnlinePayment
          ? "Paid Online"
          : "Cash on Delivery";

        const savings = (
          totals.productSavings +
          couponDiscount +
          walletUsed
        ).toFixed(2);

        if (buyerData?.phoneNumber) {
          await sendOrderCreatedMessage({
            phone: buyerData.phoneNumber,
            customerName:
              `${billing.first_name || ""} ${billing.last_name || ""}`.trim(),
            orderNumber: invoiceNumber,
            paymentStatus,
            savings,
          });
        } else {
          console.warn(
            `No phone number found for user ${uid}. Skipping WhatsApp notification.`
          );
        }
      } catch (e) {
        console.error("WhatsApp Order Created Error:", e);
      }

      return {
        success: true,
        orderId: wooOrderId,
      };
    } catch (error: any) {
      console.error("❌ finalizeOrder ERROR:", error);
      throw new Error(error.message || "Order finalization failed");
    }
  }
);

// =======================================================
// 🌐 WOO WEBHOOK
// =======================================================

export const wooOrderStatusWebhook = onRequest(
  {
    cors: false,
    maxInstances: 20,
    secrets: ["WOO_WEBHOOK_SECRET"],
  },
  async (req, res) => {
    console.log("🔥 WEBHOOK HIT");
    console.log("Headers:", req.headers);

    if (req.rawBody) {
      console.log("RawBody:", req.rawBody.toString());
    }

    try {
      // ===============================================
      // 🔐 VERIFY SIGNATURE
      // ===============================================

      const signature = req.headers["x-wc-webhook-signature"] as string;

      console.log("Received Signature:", signature);

      if (!signature) {
        console.log("❌ Missing Signature");
        res.status(401).send("Missing signature");
        return;
      }

      const expectedSignature = crypto
        .createHmac("sha256", process.env.WOO_WEBHOOK_SECRET!)
        .update(req.rawBody)
        .digest("base64");

      console.log("Secret Exists:", !!process.env.WOO_WEBHOOK_SECRET);
      console.log("Expected Signature:", expectedSignature);
      console.log("Signature Match:", signature === expectedSignature);

      if (signature !== expectedSignature) {
        console.error("❌ Invalid WooCommerce Signature");
        res.status(401).send("Invalid signature");
        return;
      }

      console.log("✅ Signature Verified");

      // ===============================================
      // 📦 ORDER DATA
      // ===============================================

      const order = req.body;

      console.log("Incoming Order:", order);

      if (!order?.id) {
        console.log("❌ Missing Order ID");
        res.status(400).send("Invalid payload");
        return;
      }

      const wooOrderId = String(order.id);
      const wooStatus = order.status;

      console.log("📦 Woo Order ID:", wooOrderId);
      console.log("📦 Woo Status:", wooStatus);

      const orderRef = admin.firestore().collection("Orders").doc(wooOrderId);

      console.log("🔍 Looking up Firestore order");

      const orderSnap = await orderRef.get();

      console.log("Order Exists:", orderSnap.exists);

      if (!orderSnap.exists) {
        console.log("❌ Order not found:", wooOrderId);
        res.status(404).send("Order not found");
        return;
      }

      const orderData = orderSnap.data();

      console.log("📄 Order Data:", {
        rewardAmount: orderData?.rewardAmount,
        referralRewardGivenTo: orderData?.referralRewardGivenTo,
        rewardReleased: orderData?.rewardReleased,
      });

      await orderRef.update({
  status: wooStatus,
  wooStatus,
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
});

      console.log("✅ Order status updated");

      const rewardAmount = Number(orderData?.rewardAmount || 0);
      const referrerUid = orderData?.referralRewardGivenTo;

      console.log("🎁 Reward Amount:", rewardAmount);
      console.log("👤 Referrer UID:", referrerUid);
      console.log("REWARD CHECK", {
        wooStatus,
        rewardAmount,
        referrerUid,
        rewardReleased: orderData?.rewardReleased,
      });

      // ===============================================
      // 🎁 RELEASE REFERRAL REWARD
      // ===============================================

      if (wooStatus === "completed" && rewardAmount > 0 && referrerUid) {
        console.log("🚀 ENTERING REWARD RELEASE BLOCK");

        let rewardActuallyCredited = false;

        const referrerRef = admin
          .firestore()
          .collection("Users")
          .doc(referrerUid);

        await admin.firestore().runTransaction(async (transaction) => {
          console.log("🔄 Transaction Started");

          const freshOrderSnap = await transaction.get(orderRef);
          const freshOrderData = freshOrderSnap.data();

          console.log("Fresh Order Data:", {
            rewardReleased: freshOrderData?.rewardReleased,
          });

          if (!freshOrderData) {
            console.log("❌ No fresh order data");
            return;
          }

          if (freshOrderData.rewardReleased === true) {
            console.log("⚠️ Reward already released");
            return;
          }

          const referrerSnap = await transaction.get(referrerRef);

          console.log("👤 Referrer Exists:", referrerSnap.exists);

          if (!referrerSnap.exists) {
            console.log("❌ Referrer not found");
            return;
          }

          rewardActuallyCredited = true;

          console.log("💰 Crediting Wallet", {
            referrerUid,
            rewardAmount,
          });

          transaction.update(referrerRef, {
            walletBalance:
              admin.firestore.FieldValue.increment(rewardAmount),
            walletTotalEarned:
              admin.firestore.FieldValue.increment(rewardAmount),
          });

          console.log("🔍 Looking for pending referral transaction");

          const pendingTxQuery = await admin
            .firestore()
            .collection("Users")
            .doc(referrerUid)
            .collection("walletTransactions")
            .where("source", "==", "referral_reward")
            .where("orderId", "==", Number(wooOrderId))
            .limit(1)
            .get();

          console.log("Pending Tx Found:", !pendingTxQuery.empty);

          if (!pendingTxQuery.empty) {
            transaction.update(pendingTxQuery.docs[0].ref, {
              status: "credited",
              creditedAt: admin.firestore.FieldValue.serverTimestamp(),
            });

            console.log("✅ Pending referral transaction updated");
          }

          console.log("✅ Marking reward released");

          transaction.update(orderRef, {
            rewardReleased: true,
            rewardReleasedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log("🏁 Transaction Completed");
        console.log("Reward Actually Credited:", rewardActuallyCredited);

        if (rewardActuallyCredited) {
          console.log("📲 Sending Reward Push");
          await sendRewardPush(referrerUid, rewardAmount, wooOrderId);
          console.log("✅ Reward Push Sent");
        }

        console.log("🎉 Referral Reward Credited Successfully");

        res.status(200).send("Referral reward credited");
        return;
      }

      console.log("ℹ️ Reward conditions not met");

      res.status(200).send("OK");
    } catch (e) {
      console.error("❌ Webhook Error:", e);
      res.status(500).send("Error");
    }
  }
);

async function sendRewardPush(uid: string, amount: number, orderId: string) {
  const userSnap = await admin.firestore().collection("Users").doc(uid).get();

  if (!userSnap.exists) {
    return;
  }

  const fcmToken = userSnap.data()?.fcmToken;

  if (!fcmToken) {
    return;
  }

  await admin
    .messaging()
    .send({
      token: fcmToken,
      notification: {
        title: "🎉 Reward Credited",
        body: `₹${amount} has been added to your wallet after successful delivery.`,
      },
      data: {
        type: "reward_credit",
        orderId: String(orderId),
        amount: String(amount),
      },
      android: {
        priority: "high",
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    });

  console.log("📲 Reward Push Sent:", uid, amount);
}

// =======================================================
// 🌐 CREATE WOO ORDER
// =======================================================

async function createWooOrder({
  uid,
  cartSnap,
  subtotal,
  shipping,
  taxableBreakup,
  gstBreakup,
  tax,
  codCharge,
  walletUsed,
  finalPayable,
  paymentMethod,
  razorpayOrderId,
  razorpayPaymentId,
  billing,
  shippingAddress,
  couponCode,
  couponDiscount,
}: any): Promise<any> {
  const lineItems: any[] = [];

  cartSnap.forEach((doc: any) => {
    const item = doc.data();

    lineItems.push({
      product_id: item.productId,
      quantity: item.quantity || 1,
    });
  });

  const feeLines: any[] = [];

  // ========================================
  // COUPON DISCOUNT
  // ========================================

  if (couponDiscount > 0) {
    feeLines.push({
      name: "Coupon Discount",
      total: (-couponDiscount).toFixed(2),
      tax_status: "none",
    });
  }

  feeLines.push({
    name: "Total Tax",
    total: tax.toFixed(2),
    tax_status: "none",
  });

  // ========================================
  // WALLET DISCOUNT
  // ========================================

  if (walletUsed > 0) {
    feeLines.push({
      name: "Wallet Discount",
      total: (-walletUsed).toFixed(2),
      tax_status: "none",
    });
  }

  // ========================================
  // COD CHARGE
  // ========================================

  if (codCharge > 0) {
    feeLines.push({
      name: "Cash on Delivery Charges",
      total: codCharge.toFixed(2),
      tax_status: "none",
    });
  }

  // ========================================
  // CREATE ORDER
  // ========================================

  const body = {
    prices_include_tax: false,
    payment_method: paymentMethod === "online" ? "razorpay" : "cod",
    payment_method_title:
      paymentMethod === "online" ? "Razorpay" : "Cash on Delivery",
    set_paid: paymentMethod === "online",
    status: "processing",
    billing,
    shipping: shippingAddress,
    line_items: lineItems,
    shipping_lines: [
      {
        method_title: "Standard Shipping",
        method_id: "flat_rate",
        total: shipping.toFixed(2),
      },
    ],

    // ========================================
    // NO TAX LINES
    // CLOUD FUNCTIONS IS SOURCE OF TRUTH
    // ========================================

    fee_lines: feeLines,

    meta_data: [
      // ------------------------------------
      // USER
      // ------------------------------------

      {
        key: "app_uid",
        value: uid,
      },
      {
        key: "created_by_app",
        value: "yes",
      },

      // ------------------------------------
      // TAX BREAKDOWN
      // ------------------------------------

      ...Object.entries(gstBreakup).map(([rate, amount]) => ({
        key: `gst_${rate}`,
        value: Number(amount).toFixed(2),
      })),

      ...Object.entries(taxableBreakup).map(([rate, amount]) => ({
        key: `taxable_${rate}`,
        value: Number(amount).toFixed(2),
      })),

      {
        key: "tax_total",
        value: tax.toFixed(2),
      },

      // ------------------------------------
      // DISCOUNTS
      // ------------------------------------

      {
        key: "coupon_code",
        value: couponCode || "",
      },
      {
        key: "coupon_discount",
        value: couponDiscount,
      },
      {
        key: "wallet_used",
        value: walletUsed,
      },

      // ------------------------------------
      // COD
      // ------------------------------------

      {
        key: "cod_charge",
        value: codCharge,
      },

      // ------------------------------------
      // PAYMENT
      // ------------------------------------

      {
        key: "razorpay_order_id",
        value: razorpayOrderId || "",
      },
      {
        key: "razorpay_payment_id",
        value: razorpayPaymentId || "",
      },

      // ------------------------------------
      // APP TOTALS
      // ------------------------------------

      {
        key: "app_subtotal",
        value: subtotal.toFixed(2),
      },
      {
        key: "app_shipping",
        value: shipping.toFixed(2),
      },
      {
        key: "app_final_payable",
        value: finalPayable.toFixed(2),
      },
    ],
  };

  console.log(JSON.stringify(body, null, 2));

  const response = await axios.post(
    "https://store.gladskin.in/wp-json/wc/v3/orders",
    body,
    {
      auth: {
        username: "ck_1f90c93d45a4593f00f89ba5c942001e13898e09",
        password: "cs_1c4ddd44c08c3399ecbca3e6e16f1234274ae392",
      },
    }
  );

  return response.data;
}