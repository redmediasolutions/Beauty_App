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

    const cartSnap = await admin
      .firestore()
      .collection("carts")
      .doc(uid)
      .collection("items")
      .get();

    let subtotal = 0;

    cartSnap.forEach((doc) => {
      const item = doc.data();

      subtotal +=
        Number(item.salePrice || 0) *
        Number(item.quantity || 1);
    });

    const shipping =
      subtotal <= FREE_SHIPPING_THRESHOLD
        ? SHIPPING_BELOW_THRESHOLD
        : SHIPPING_ABOVE_THRESHOLD;

    const tax = subtotal * TAX_PERCENTAGE;

    const codCharge =
      paymentMethod === "cod"
        ? COD_CHARGE
        : 0;

    const grossTotal =
      subtotal + shipping + tax + codCharge;

    const userDoc = await admin
      .firestore()
      .collection("Users")
      .doc(uid)
      .get();

    const walletBalance = Number(
      userDoc.data()?.walletBalance || 0
    );

    const walletUsed = useWallet
      ? Math.min(walletBalance, grossTotal)
      : 0;

    const finalPayable =
      grossTotal - walletUsed;

    return {
      subtotal,
      shipping,
      tax,
      codCharge,
      walletBalance,
      walletUsed,
      finalPayable,
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

      throw new Error(
        "Unauthenticated",
      );
    }

    const uid =
      request.auth.uid;

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
        data.couponDiscount || 0,
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
    // 🛒 FETCH CART
    // =========================================

    const cartSnap =
      await admin
        .firestore()
        .collection("carts")
        .doc(uid)
        .collection("items")
        .get();

    if (cartSnap.empty) {

      throw new Error(
        "Cart is empty",
      );
    }

    // =========================================
    // 💰 CALCULATE SUBTOTAL
    // =========================================

    let subtotal = 0;

    cartSnap.forEach((doc) => {

      const item =
        doc.data();

      subtotal +=
        Number(
          item.salePrice || 0,
        ) *
        Number(
          item.quantity || 1,
        );
    });

    // =========================================
    // 🚚 SHIPPING
    // =========================================

    const shipping =
      subtotal <=
      FREE_SHIPPING_THRESHOLD
        ? SHIPPING_BELOW_THRESHOLD
        : SHIPPING_ABOVE_THRESHOLD;

    // =========================================
    // 🧾 TAX
    // =========================================

    const tax =
      Math.round(
        subtotal *
          TAX_PERCENTAGE *
          100,
      ) / 100;

    // =========================================
    // 💵 COD CHARGE
    // =========================================

    const codCharge =
      paymentMethod === "cod"
        ? COD_CHARGE
        : 0;

    // =========================================
    // 📦 GROSS TOTAL
    // =========================================

    const grossTotal =
      subtotal +
      shipping +
      tax +
      codCharge;

    // =========================================
    // 🎟 APPLY COUPON
    // =========================================

    const discountedTotal =
      Math.max(
        grossTotal -
          couponDiscount,
        0,
      );

    // =========================================
    // 👛 FETCH WALLET
    // =========================================

    const userDoc =
      await admin
        .firestore()
        .collection("Users")
        .doc(uid)
        .get();

    const walletBalance =
      Number(
        userDoc.data()
          ?.walletBalance || 0,
      );

    // =========================================
    // 👛 APPLY WALLET
    // =========================================

    const walletUsed =
      useWallet
        ? Math.min(
            walletBalance,
            discountedTotal,
          )
        : 0;

    // =========================================
    // 💳 FINAL PAYABLE
    // =========================================

    const finalPayable =
      Math.max(
        discountedTotal -
          walletUsed,
        0,
      );

    // =========================================
    // 💳 CREATE RAZORPAY ORDER
    // =========================================

    let razorpayOrderId =
      null;

    let razorpayAmount =
      null;

    if (
      paymentMethod ===
        "online" &&
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
                finalPayable *
                  100,
              ),

            currency: "INR",

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
        paymentMethod ===
        "cod"
          ? "pending"
          : "created",

      status:
        paymentMethod ===
        "cod"
          ? "pending"
          : "payment_pending",

      // =====================================
      // 🛒 ITEMS SNAPSHOT
      // =====================================

      items: cartSnap.docs.map((doc) => {

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
  };
}),

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

      couponId,

      couponCode,

      couponDiscount,

      discountedTotal,

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
        shipping,
      } = data;

      if (!billing || !shipping) {
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

      const cartRef = admin
        .firestore()
        .collection("carts")
        .doc(uid)
        .collection("items");

      const cartSnap =
        await cartRef.get();

      if (cartSnap.empty) {
        throw new Error(
          "Cart empty"
        );
      }

      // ===================================================
      // 💰 SUBTOTAL
      // ===================================================

      let subtotal = 0;

      cartSnap.forEach((doc) => {

        const item =
          doc.data();

        subtotal +=
          Number(
            item.salePrice || 0
          ) *
          Number(
            item.quantity || 1
          );
      });

      // ===================================================
      // 💰 TOTALS
      // ===================================================

      const shippingAmount =
        subtotal <=
        FREE_SHIPPING_THRESHOLD
          ? SHIPPING_BELOW_THRESHOLD
          : SHIPPING_ABOVE_THRESHOLD;

      const tax =
        subtotal *
        TAX_PERCENTAGE;

      const codCharge =
        isOnlinePayment
          ? 0
          : COD_CHARGE;

      // ===================================================
      // 🎟 COUPON
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
      // 💵 GROSS TOTAL
      // ===================================================

      const grossTotal =
        subtotal +
        shippingAmount +
        tax +
        codCharge;

      const discountedTotal =
        Math.max(
          grossTotal -
            couponDiscount,
          0
        );

      // ===================================================
      // 👛 WALLET
      // ===================================================

      const userRef = admin
        .firestore()
        .collection("Users")
        .doc(uid);

      const userSnap =
        await userRef.get();

      const userData =
        userSnap.data() || {};

      const walletBalance =
        Number(
          userData.walletBalance || 0
        );

      const walletUsed =
        useWallet
          ? Math.min(
              walletBalance,
              discountedTotal
            )
          : 0;

      const finalPayable =
        discountedTotal -
        walletUsed;

      // ===================================================
      // 🎁 REWARD
      // ===================================================

      const rewardAmount =
        Math.round(
          subtotal *
            0.1 *
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

          shipping:
            shippingAmount,

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

          shippingAddress:
            shipping,

          couponId,
          couponCode,
          couponDiscount,
          discountedTotal,
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

            let referrerUid =
              null;

            if (
              buyerData &&
              buyerData.referredByUserId
            ) {
              referrerUid =
                buyerData.referredByUserId;
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

                shipping:
                  shippingAmount,

                tax,

                codCharge,

                grossTotal,

                discountedTotal,

                walletUsed,

                finalPayable,

                // ===================================
                // 🎟 COUPON DATA
                // ===================================

                couponId,

                couponCode,

                couponDiscount,

                // ===================================
                // 💳 PAYMENT
                // ===================================

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

                // ===================================
                // 🎁 REWARDS
                // ===================================

                rewardAmount,

                rewardReleased:
                  false,

                rewardReversed:
                  false,

                referralRewardGivenTo:
                  referrerUid,

                // ===================================
                // 📦 ITEMS
                // ===================================

                items: cartSnap.docs.map((doc) => {

  const item = doc.data();

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
  };
}),

                // ===================================
                // 🏠 ADDRESS
                // ===================================

                billing,

                shippingAddress:
                  shipping,

                // ===================================
                // 🕒 TIMESTAMPS
                // ===================================

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
                  .collection(
                    "Users"
                  )
                  .doc(
                    referrerUid
                  )
                  .collection(
                    "walletTransactions"
                  )
                  .doc();

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
    },
    async (req, res) => {
      try {
        const order =
          req.body;

        if (!order?.id) {
          res.status(400).send(
            "Invalid"
          );
          return;
        }

        await admin
          .firestore()
          .collection("Orders")
          .doc(
            String(order.id)
          )
          .update({
            status:
              order.status,
          });

        res.status(200).send("OK");
      } catch (e) {
        console.error(e);

        res.status(500).send(
          "Error"
        );
      }
    }
  );

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
