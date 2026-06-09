import {
  onCall,
  onRequest,
} from "firebase-functions/v2/https";

import * as admin from "firebase-admin";

import Razorpay from "razorpay";

import crypto from "crypto";

import axios from "axios";

// =======================================================
// 🔐 CENTRAL RATE CONFIG
// =======================================================

const FREE_SHIPPING_THRESHOLD = 499;
const SHIPPING_BELOW_THRESHOLD = 49;
const SHIPPING_ABOVE_THRESHOLD = 0;
const TAX_PERCENTAGE = 0.05;
const COD_CHARGE = 60;

// =======================================================
// 🔐 CALCULATION LOGIC
// =======================================================

async function calculateCartTotals({
  uid,
  paymentMethod,
  useWallet,
  couponDiscount = 0,
}: {
  uid: string;
  paymentMethod: string;
  useWallet: boolean;
  couponDiscount?: number;
}) {

  const cartSnap = await admin
    .firestore()
    .collection("carts")
    .doc(uid)
    .collection("items")
    .get();

  let subtotal = 0;

  let totalMrp = 0;

  let productSavings = 0;

  let gst18Subtotal = 0;
  let gst5Subtotal = 0;

  cartSnap.forEach((doc) => {

    const item = doc.data();

    const qty =
      Number(item.quantity || 1);

    const mrp =
      Number(item.mrp || 0);

    const salePrice =
      Number(
        item.salePrice || mrp
      );

    const lineTotal =
      salePrice * qty;

    subtotal += lineTotal;

    totalMrp +=
      mrp * qty;

    productSavings +=
      (mrp - salePrice) * qty;

    const taxClass =
      item.taxClass || "";

    if (
      taxClass ===
      "reduced-rate"
    ) {
      gst5Subtotal += lineTotal;
    } else {
      gst18Subtotal += lineTotal;
    }
  });

  const shipping =
    subtotal <=
    FREE_SHIPPING_THRESHOLD
      ? SHIPPING_BELOW_THRESHOLD
      : SHIPPING_ABOVE_THRESHOLD;

  const aggregateDiscount =
    couponDiscount;

  const taxableTotal =
    gst18Subtotal +
    gst5Subtotal;

  let gst18DiscountShare = 0;
  let gst5DiscountShare = 0;

  if (
    taxableTotal > 0 &&
    aggregateDiscount > 0
  ) {
    gst18DiscountShare =
      aggregateDiscount *
      (gst18Subtotal /
        taxableTotal);

    gst5DiscountShare =
      aggregateDiscount *
      (gst5Subtotal /
        taxableTotal);
  }

  const taxable18 =
    Math.max(
      gst18Subtotal -
        gst18DiscountShare,
      0
    );

  const taxable5 =
    Math.max(
      gst5Subtotal -
        gst5DiscountShare,
      0
    );

  const gst18 =
    taxable18 * 0.18;

  const gst5 =
    taxable5 * 0.05;

  const tax =
    gst18 + gst5;

  const codCharge =
    paymentMethod === "cod"
      ? COD_CHARGE
      : 0;

  const discountedSubtotal =
    Math.max(
      subtotal -
        aggregateDiscount,
      0
    );

  const grossTotal =
    discountedSubtotal +
    tax +
    shipping +
    codCharge;

  const userDoc =
    await admin
      .firestore()
      .collection("Users")
      .doc(uid)
      .get();

  const walletBalance =
    Number(
      userDoc.data()
        ?.walletBalance || 0
    );

  const walletUsed =
    useWallet
      ? Math.min(
          walletBalance,
          grossTotal
        )
      : 0;

  const finalPayable =
    grossTotal -
    walletUsed;

  return {
    subtotal,
    totalMrp,
    productSavings,

    couponDiscount,

    gst18,
    gst5,
    tax,

    shipping,
    codCharge,

    discountedSubtotal,

     // --------------------------------

  // AFTER COUPON + TAX + SHIPPING

  // BEFORE WALLET

  // --------------------------------

  discountedTotal: grossTotal,

    walletBalance,
    walletUsed,

    grossTotal,
    finalPayable,

    cartSnap,
  };
}

// =======================================================
// 🔐 RAZORPAY INSTANCE
// =======================================================

// =======================================================
// 📦 GET CART RATES
// =======================================================

export const getCartRates = onCall(
  {
    maxInstances: 10,
    concurrency: 80,
  },
  async (request) => {
    const data = request.data as any;

    const paymentMethod =
      data.paymentMethod || "online";

    return {
      freeShippingThreshold:
        FREE_SHIPPING_THRESHOLD,

      shippingBelowThreshold:
        SHIPPING_BELOW_THRESHOLD,

      shippingAboveThreshold:
        SHIPPING_ABOVE_THRESHOLD,

      taxPercentage: TAX_PERCENTAGE,

      codCharge:
        paymentMethod === "cod"
          ? COD_CHARGE
          : 0,
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

    const paymentMethod =
      data.paymentMethod || "online";

    const useWallet =
      data.useWallet === true;

    const couponDiscount =
      Number(
        data.couponDiscount || 0
      );

    // =====================================
    // USE SAME CALCULATION ENGINE
    // AS CART + CREATE ORDER
    // =====================================

    const totals =
      await calculateCartTotals({
        uid,
        paymentMethod,
        useWallet,
        couponDiscount,
      });

    return {

      // ==========================
      // PRODUCT TOTALS
      // ==========================

      subtotal:
        totals.subtotal,

      totalMrp:
        totals.totalMrp,

      productSavings:
        totals.productSavings,

      // ==========================
      // COUPON
      // ==========================

      couponDiscount:
        totals.couponDiscount,

      discountedSubtotal:
        totals.discountedSubtotal,

      // ==========================
      // GST
      // ==========================

      gst18:
        totals.gst18,

      gst5:
        totals.gst5,

      tax:
        totals.tax,

      // ==========================
      // SHIPPING / COD
      // ==========================

      shipping:
        totals.shipping,

      codCharge:
        totals.codCharge,

      // ==========================
      // WALLET
      // ==========================

      walletBalance:
        totals.walletBalance,

      walletUsed:
        totals.walletUsed,

      // ==========================
      // TOTALS
      // ==========================

      grossTotal:
        totals.grossTotal,

      discountedTotal:
        totals.discountedTotal,

      finalPayable:
        totals.finalPayable,
    };
  }
);

// =======================================================
// 🛒 CREATE SECURE ORDER
// =======================================================
export const createSecureOrder = onCall(
  {
    secrets: [
      "RAZORPAY_KEY_ID",
      "RAZORPAY_KEY_SECRET",
    ],

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

    const data =
      request.data as any;

    // =========================================
    // 🎟 COUPON DATA
    // =========================================

    const couponId =
      data.couponId || null;

    const couponCode =
      data.couponCode || null;

    const couponDiscount =
      Number(
        data.couponDiscount || 0
      );

    // =========================================
    // 💳 PAYMENT
    // =========================================

    const paymentMethod =
      data.paymentMethod ||
      "online";

    const useWallet =
      data.useWallet === true;

    // =========================================
    // 🧮 CALCULATE TOTALS
    // =========================================

    const totals =
      await calculateCartTotals({
        uid,
        paymentMethod,
        useWallet,
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
      throw new Error(
        "Cart is empty"
      );
    }

    // =========================================
    // 💳 CREATE RAZORPAY ORDER
    // =========================================

    let razorpayOrderId =
      null;

    let razorpayAmount =
      null;

    if (
      paymentMethod === "online" &&
      finalPayable > 0
    ) {

      const razorpay =
        new Razorpay({
          key_id:
            process.env
              .RAZORPAY_KEY_ID!,

          key_secret:
            process.env
              .RAZORPAY_KEY_SECRET!,
        });

      const order =
        await razorpay
          .orders
          .create({

            amount:
              Math.round(
                finalPayable * 100
              ),

            currency:
              "INR",

            receipt:
              `gladskin_${Date.now()}`,

            notes: {

              uid,

              couponCode:
                couponCode || "",

              couponDiscount:
                couponDiscount
                  .toString(),
            },
          });

      razorpayOrderId =
        order.id;

      razorpayAmount =
        order.amount;
    }

    // =========================================
    // 🔥 SAVE DRAFT ORDER
    // =========================================

    const orderRef =
      admin
        .firestore()
        .collection("Orders")
        .doc();

    await orderRef.set({

      uid,

      subtotal,

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

      paymentStatus:
        paymentMethod === "cod"
          ? "pending"
          : "created",

      status:
        paymentMethod === "cod"
          ? "pending"
          : "payment_pending",

      // =====================================
      // 🛒 ITEMS SNAPSHOT
      // =====================================

      items:
        cartSnap.docs.map(
          (doc) => {

            const item =
              doc.data();

            return {

              productId:
                item.productId,

              name:
                item.name || "",

              image:
                item.image || "",

              quantity:
                item.quantity || 1,

              salePrice:
                item.salePrice || 0,

              mrp:
                item.mrp || 0,

              taxClass:
                item.taxClass || "",
            };
          }
        ),

      createdAt:
        admin.firestore
          .FieldValue
          .serverTimestamp(),

      updatedAt:
        admin.firestore
          .FieldValue
          .serverTimestamp(),
    });

    // =========================================
    // ✅ RESPONSE
    // =========================================

    return {

      success: true,

      orderId:
        orderRef.id,

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
        paymentMethod ===
        "online"
          ? process.env
              .RAZORPAY_KEY_ID
          : null,
    };
  },
);

// =======================================================
// 💳 FINALIZE ORDER
// =======================================================

export const finalizeOrder = onCall(
  {
    secrets: [
      "RAZORPAY_KEY_SECRET",
      "WOO_KEY",
      "WOO_SECRET",
    ],

    maxInstances: 10,
    concurrency: 80,
  },

  async (request) => {
    try {

      // ===================================================
      // 🔐 AUTH
      // ===================================================

      if (!request.auth) {
        throw new Error(
          "Unauthenticated"
        );
      }

      const uid =
        request.auth.uid;

      const data =
        request.data as any;

      const useWallet =
        data.useWallet === true;

      const {
        razorpayOrderId,
        razorpayPaymentId,
        razorpaySignature,
        billing,
        shipping: shippingAddress,
      } = data;

      if (!billing || !shippingAddress) {

  throw new Error(

    "Billing or Shipping missing"

  );

}

      const isOnlinePayment =
        razorpayOrderId &&
        razorpayPaymentId &&
        razorpaySignature;

      // ===================================================
      // 🔐 VERIFY PAYMENT
      // ===================================================

      if (isOnlinePayment) {

        const body =
          razorpayOrderId +
          "|" +
          razorpayPaymentId;

        const expectedSignature =
          crypto
            .createHmac(
              "sha256",
              process.env
                .RAZORPAY_KEY_SECRET!
            )
            .update(body)
            .digest("hex");

        if (
          expectedSignature !==
          razorpaySignature
        ) {
          throw new Error(
            "Invalid Payment Signature"
          );
        }
      }

      // ===================================================
      // 🛒 FETCH CART
      // ===================================================

      // ===================================================
// 🎟 COUPON DATA
// ===================================================

const couponId =
  data.couponId || null;

const couponCode =
  data.couponCode || null;

const couponDiscount =
  Number(
    data.couponDiscount || 0
  );

// ===================================================
// 🧮 CALCULATE TOTALS
// ===================================================

const totals =
  await calculateCartTotals({
    uid,
    paymentMethod:
      isOnlinePayment
        ? "online"
        : "cod",
    useWallet,
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

// ===================================================
// 👤 USER REF
// ===================================================

const userRef =
  admin
    .firestore()
    .collection("Users")
    .doc(uid);

// ===================================================
// 🎁 REWARD
// ===================================================

const rewardAmount =
  Math.round(
    subtotal *
      0.20 *
      100
  ) / 100;

// ===================================================
// 🌐 CREATE WOO ORDER
// ===================================================

const wooOrder =
  await createWooOrder({
    uid,
    cartSnap,

    subtotal,

    shipping,

    tax,

    codCharge,

    walletUsed,

    finalPayable,

    paymentMethod:
      isOnlinePayment
        ? "online"
        : "cod",

    razorpayOrderId,
    razorpayPaymentId,

    billing,

    shippingAddress,

    couponCode,
    couponDiscount,
  });

if (!wooOrder?.id) {
  throw new Error(
    "Woo order failed"
  );
}

const wooOrderId =
  wooOrder.id;

// ===================================================
// 🔥 TRANSACTION
// ===================================================

await admin
  .firestore()
  .runTransaction(
    async (transaction) => {

      const buyerSnap =
        await transaction.get(
          userRef
        );

      const buyerData =
        buyerSnap.data();

      let referrerUid = null;

        if (
          buyerData &&
          buyerData.referredBy
        ) {

          const referralCode =
            buyerData.referredBy;

          const referrerSnap =
            await admin
              .firestore()
              .collection("Users")
              .where(
                "referralCode",
                "==",
                referralCode
              )
              .limit(1)
              .get();

          if (!referrerSnap.empty) {

            referrerUid =
              referrerSnap.docs[0].id;
          }
}

      // ===============================================
      // 👛 WALLET DEDUCTION
      // ===============================================

      if (walletUsed > 0) {

        transaction.update(
          userRef,
          {
            walletBalance:
              admin.firestore
                .FieldValue.increment(
                  -walletUsed
                ),
          }
        );
      }

      // ===============================================
      // 🧹 CLEAR CART
      // ===============================================

      cartSnap.forEach(
        (doc) => {
          transaction.delete(
            doc.ref
          );
        }
      );

      // ===============================================
      // 📦 ORDER REF
      // ===============================================

      const orderRef =
        admin
          .firestore()
          .collection(
            "Orders"
          )
          .doc(
            String(
              wooOrderId
            )
          );

      // ===============================================
      // 📦 SAVE ORDER
      // ===============================================

      transaction.set(
        orderRef,
        {
          uid,

          wooOrderId,

          subtotal,

          shipping,

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

          paymentMethod:
            isOnlinePayment
              ? "online"
              : "cod",

          paymentStatus:
            isOnlinePayment
              ? "paid"
              : "pending",

          razorpayOrderId:
            razorpayOrderId ||
            null,

          razorpayPaymentId:
            razorpayPaymentId ||
            null,

          rewardAmount,

          rewardReleased:
            false,

          rewardReversed:
            false,
          
          rewardReleasedAt: null,

          referralRewardGivenTo:
            referrerUid,

          items:
            cartSnap.docs.map(
              (doc) => {

                const item =
                  doc.data();

                return {
                  productId:
                    item.productId,

                  name:
                    item.name || "",

                  image:
                    item.image || "",

                  quantity:
                    item.quantity || 1,

                  salePrice:
                    item.salePrice || 0,

                  mrp:
                    item.mrp || 0,

                  taxClass:
                    item.taxClass || "",
                };
              }
            ),

          billing,

          shippingAddress:
            shippingAddress,

          createdAt:
            admin.firestore
              .FieldValue.serverTimestamp(),

          updatedAt:
            admin.firestore
              .FieldValue.serverTimestamp(),
        }
      );

      // ===============================================
      // 🎁 REFERRAL REWARD
      // ===============================================

      if (
        referrerUid &&
        rewardAmount > 0
      ) {

        const pendingTxRef =
  admin
    .firestore()
    .collection("Users")
    .doc(referrerUid)
    .collection("walletTransactions")
    .doc(String(wooOrderId));

        transaction.set(
          pendingTxRef,
          {
            type:
              "credit",

            source:
              "referral_reward",

            orderId:
              wooOrderId,

            amount:
              rewardAmount,

            status:
              "pending",

            createdAt:
              admin.firestore
                .FieldValue.serverTimestamp(),
          }
        );
      }
    }
  );
     

      // ===================================================
      // ✅ SUCCESS
      // ===================================================

      return {
        success: true,
        orderId: wooOrderId,
      };

    } catch (error: any) {

      console.error(
        "❌ finalizeOrder ERROR:",
        error
      );

      throw new Error(
        error.message ||
          "Order finalization failed"
      );
    }
  }
);

// =======================================================
// 🌐 WOO WEBHOOK
// =======================================================

export const wooOrderStatusWebhook =
  onRequest(
    {
      cors: false,
      maxInstances: 20,
      secrets: [
        "WOO_WEBHOOK_SECRET",
      ],
    },

    async (req, res) => {

      console.log("🔥 WEBHOOK HIT");
      console.log("Headers:", req.headers);

      if (req.rawBody) {
        console.log(
          "RawBody:",
          req.rawBody.toString()
        );
      }

      try {

        // ===============================================
        // 🔐 VERIFY SIGNATURE
        // ===============================================

        const signature =
          req.headers[
            "x-wc-webhook-signature"
          ] as string;

        console.log(
          "Received Signature:",
          signature
        );

        if (!signature) {

          console.log(
            "❌ Missing Signature"
          );

          res
            .status(401)
            .send("Missing signature");

          return;
        }

        const expectedSignature =
          crypto
            .createHmac(
              "sha256",
              process.env
                .WOO_WEBHOOK_SECRET!
            )
            .update(req.rawBody)
            .digest("base64");

        console.log(
          "Secret Exists:",
          !!process.env.WOO_WEBHOOK_SECRET
        );

        console.log(
          "Expected Signature:",
          expectedSignature
        );

        console.log(
          "Signature Match:",
          signature === expectedSignature
        );

        if (
          signature !==
          expectedSignature
        ) {

          console.error(
            "❌ Invalid WooCommerce Signature"
          );

          res
            .status(401)
            .send("Invalid signature");

          return;
        }

        console.log(
          "✅ Signature Verified"
        );

        // ===============================================
        // 📦 ORDER DATA
        // ===============================================

        const order = req.body;

        console.log(
          "Incoming Order:",
          order
        );

        if (!order?.id) {

          console.log(
            "❌ Missing Order ID"
          );

          res
            .status(400)
            .send("Invalid payload");

          return;
        }

        const wooOrderId =
          String(order.id);

        const wooStatus =
          order.status;

        console.log(
          "📦 Woo Order ID:",
          wooOrderId
        );

        console.log(
          "📦 Woo Status:",
          wooStatus
        );

        const orderRef =
          admin
            .firestore()
            .collection("Orders")
            .doc(wooOrderId);

        console.log(
          "🔍 Looking up Firestore order"
        );

        const orderSnap =
          await orderRef.get();

        console.log(
          "Order Exists:",
          orderSnap.exists
        );

        if (!orderSnap.exists) {

          console.log(
            "❌ Order not found:",
            wooOrderId
          );

          res
            .status(404)
            .send("Order not found");

          return;
        }

        const orderData =
          orderSnap.data();

        console.log(
          "📄 Order Data:",
          {
            rewardAmount:
              orderData?.rewardAmount,

            referralRewardGivenTo:
              orderData?.referralRewardGivenTo,

            rewardReleased:
              orderData?.rewardReleased,
          }
        );

        await orderRef.update({
          status: wooStatus,
          updatedAt:
            admin.firestore
              .FieldValue.serverTimestamp(),
        });

        console.log(
          "✅ Order status updated"
        );

        const rewardAmount =
          Number(
            orderData?.rewardAmount || 0
          );

        const referrerUid =
          orderData?.referralRewardGivenTo;

        console.log(
          "🎁 Reward Amount:",
          rewardAmount
        );

        console.log(
          "👤 Referrer UID:",
          referrerUid
        );

        console.log(
          "REWARD CHECK",
          {
            wooStatus,
            rewardAmount,
            referrerUid,
            rewardReleased:
              orderData?.rewardReleased,
          }
        );

        // ===============================================
        // 🎁 RELEASE REFERRAL REWARD
        // ===============================================

        if (
          wooStatus === "completed" &&
          rewardAmount > 0 &&
          referrerUid
        ) {

          console.log(
            "🚀 ENTERING REWARD RELEASE BLOCK"
          );

          let rewardActuallyCredited =
            false;

          const referrerRef =
            admin
              .firestore()
              .collection("Users")
              .doc(referrerUid);

          await admin
            .firestore()
            .runTransaction(
              async (
                transaction
              ) => {

                console.log(
                  "🔄 Transaction Started"
                );

                const freshOrderSnap =
                  await transaction.get(
                    orderRef
                  );

                const freshOrderData =
                  freshOrderSnap.data();

                console.log(
                  "Fresh Order Data:",
                  {
                    rewardReleased:
                      freshOrderData?.rewardReleased,
                  }
                );

                if (
                  !freshOrderData
                ) {

                  console.log(
                    "❌ No fresh order data"
                  );

                  return;
                }

                if (
                  freshOrderData
                    .rewardReleased === true
                ) {

                  console.log(
                    "⚠️ Reward already released"
                  );

                  return;
                }

                const referrerSnap =
                  await transaction.get(
                    referrerRef
                  );

                console.log(
                  "👤 Referrer Exists:",
                  referrerSnap.exists
                );

                if (
                  !referrerSnap.exists
                ) {

                  console.log(
                    "❌ Referrer not found"
                  );

                  return;
                }

                rewardActuallyCredited =
                  true;

                console.log(
                  "💰 Crediting Wallet",
                  {
                    referrerUid,
                    rewardAmount,
                  }
                );

                transaction.update(
                  referrerRef,
                  {
                    walletBalance:
                      admin.firestore
                        .FieldValue.increment(
                          rewardAmount
                        ),

                    walletTotalEarned:
                      admin.firestore
                        .FieldValue.increment(
                          rewardAmount
                        ),
                  }
                );

                console.log(
                  "🔍 Looking for pending referral transaction"
                );

                const pendingTxQuery =
                  await admin
                    .firestore()
                    .collection("Users")
                    .doc(referrerUid)
                    .collection(
                      "walletTransactions"
                    )
                    .where(
                      "source",
                      "==",
                      "referral_reward"
                    )
                    .where(
                      "orderId",
                      "==",
                      Number(wooOrderId)
                    )
                    .limit(1)
                    .get();

                console.log(
                  "Pending Tx Found:",
                  !pendingTxQuery.empty
                );

                if (
                  !pendingTxQuery.empty
                ) {

                  transaction.update(
                    pendingTxQuery
                      .docs[0]
                      .ref,
                    {
                      status:
                        "credited",

                      creditedAt:
                        admin.firestore
                          .FieldValue.serverTimestamp(),
                    }
                  );

                  console.log(
                    "✅ Pending referral transaction updated"
                  );
                }

                console.log(
                  "✅ Marking reward released"
                );

                transaction.update(
                  orderRef,
                  {
                    rewardReleased:
                      true,

                    rewardReleasedAt:
                      admin.firestore
                        .FieldValue.serverTimestamp(),
                  }
                );
              }
            );

          console.log(
            "🏁 Transaction Completed"
          );

          console.log(
            "Reward Actually Credited:",
            rewardActuallyCredited
          );

          if (
            rewardActuallyCredited
          ) {

            console.log(
              "📲 Sending Reward Push"
            );

            await sendRewardPush(
              referrerUid,
              rewardAmount,
              wooOrderId
            );

            console.log(
              "✅ Reward Push Sent"
            );
          }

          console.log(
            "🎉 Referral Reward Credited Successfully"
          );

          res
            .status(200)
            .send(
              "Referral reward credited"
            );

          return;
        }

        console.log(
          "ℹ️ Reward conditions not met"
        );

        res
          .status(200)
          .send("OK");

      } catch (e) {

        console.error(
          "❌ Webhook Error:",
          e
        );

        res
          .status(500)
          .send("Error");
      }
    }
  );

  async function sendRewardPush(
  uid: string,
  amount: number,
  orderId: string,
) {

  const userSnap =
    await admin
      .firestore()
      .collection("Users")
      .doc(uid)
      .get();

  if (!userSnap.exists) {
    return;
  }

  const fcmToken =
    userSnap.data()
      ?.fcmToken;

  if (!fcmToken) {
    return;
  }

  await admin
    .messaging()
    .send({

      token:
        fcmToken,

      notification: {

        title:
          "🎉 Reward Credited",

        body:
          `₹${amount} has been added to your wallet after successful delivery.`,
      },

      data: {

        type:
          "reward_credit",

        orderId:
          String(orderId),

        amount:
          String(amount),
      },

      android: {

        priority:
          "high",
      },

      apns: {

        payload: {

          aps: {

            sound:
              "default",
          },
        },
      },
    });

  console.log(
    "📲 Reward Push Sent:",
    uid,
    amount
  );
}

// =======================================================
// 🌐 CREATE WOO ORDER
// =======================================================

async function createWooOrder({
  uid,
  cartSnap,
  subtotal,
  shipping,
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
      product_id:
        item.productId,

      quantity:
        item.quantity || 1,
    });
  });

  const feeLines = [];

// ========================================

// 🎟 COUPON DISCOUNT

// ========================================

if (couponDiscount > 0) {

  feeLines.push({

    name:

      `Coupon (${couponCode})`,

    total:

      (-couponDiscount).toFixed(2),

    tax_status:

      "none",

  });

}
  

  if (walletUsed > 0) {
    feeLines.push({
      name:
        "Wallet Discount",

      total:
        (-walletUsed).toFixed(
          2
        ),

      tax_status:
        "none",
    });
  }

  if (codCharge > 0) {
    feeLines.push({
      name:
        "Cash on Delivery Charges",

      total:
        codCharge.toFixed(2),

      tax_status:
        "none",
    });
  }

  const body = {
    payment_method:
      paymentMethod ===
      "online"
        ? "razorpay"
        : "cod",

    payment_method_title:
      paymentMethod ===
      "online"
        ? "Razorpay"
        : "Cash on Delivery",

    set_paid:
      paymentMethod ===
      "online",

    billing,

    shipping:
      shippingAddress,

    line_items:
      lineItems,

    shipping_lines: [
      {
        method_title:
          "Standard Shipping",

        method_id:
          "flat_rate",

        total:
          shipping.toFixed(2),
      },
    ],

    tax_lines:
      tax > 0
        ? [
            {
              rate_code:
                "app-tax",

              label:
                "GST 18%",

              compound:
                false,

              tax_total:
                tax.toFixed(
                  2
                ),

              shipping_tax_total:
                "0.00",
            },
          ]
        : [],

    fee_lines:
      feeLines,

    meta_data: [
      {
        key:
          "app_uid",

        value: uid,
      },

      {
        key:
          "wallet_used",

        value:
          walletUsed,
      },

      {
        key:
          "cod_charge",

        value:
          codCharge,
      },

      {
        key:
          "razorpay_order_id",

        value:
          razorpayOrderId ||
          "",
      },

      {
        key:
          "razorpay_payment_id",

        value:
          razorpayPaymentId ||
          "",
      },
    ],
  };

  const response: any =
   await axios.post(
  "https://store.gladskin.in/wp-json/wc/v3/orders",
      body,
      {
        auth: {
          username:"ck_1f90c93d45a4593f00f89ba5c942001e13898e09",
          password:"cs_1c4ddd44c08c3399ecbca3e6e16f1234274ae392",
        },
      }
    );

  return response.data;
}
