import * as admin from "firebase-admin";
import {
  onCall,
  HttpsError,
} from "firebase-functions/v2/https";

const db = admin.firestore();

const FCM_BATCH_SIZE = 500;
const USER_QUERY_BATCH = 30;

// ============================================================
// WOOCOMMERCE CONFIG
// ============================================================
//
// Use Firebase Functions environment variables / params for these.
// Replace these with however your existing project stores WooCommerce
// credentials.
//
// ============================================================

const WOOCOMMERCE_BASE_URL =
  process.env.WOOCOMMERCE_BASE_URL || "";

const WOOCOMMERCE_CONSUMER_KEY =
  process.env.WOOCOMMERCE_CONSUMER_KEY || "";

const WOOCOMMERCE_CONSUMER_SECRET =
  process.env.WOOCOMMERCE_CONSUMER_SECRET || "";

// ============================================================
// FETCH PRODUCT FROM WOOCOMMERCE
// ============================================================

async function fetchWooCommerceProduct(
  productId: string,
): Promise<{
  slug: string;
  image: string;
}> {
  if (
    !WOOCOMMERCE_BASE_URL ||
    !WOOCOMMERCE_CONSUMER_KEY ||
    !WOOCOMMERCE_CONSUMER_SECRET
  ) {
    throw new Error(
      "WooCommerce configuration is missing.",
    );
  }

  const url =
    `${WOOCOMMERCE_BASE_URL}/wp-json/wc/v3/products/${encodeURIComponent(productId)}` +
    `?consumer_key=${encodeURIComponent(WOOCOMMERCE_CONSUMER_KEY)}` +
    `&consumer_secret=${encodeURIComponent(WOOCOMMERCE_CONSUMER_SECRET)}`;

  console.log(
    `🔎 Fetching WooCommerce product: ${productId}`,
  );

  const response = await fetch(url);

  if (!response.ok) {
    const errorText = await response.text();

    throw new Error(
      `WooCommerce product fetch failed: ${response.status} ${errorText}`,
    );
  }

  const product =
    (await response.json()) as {
      slug?: string;
      images?: Array<{
        src?: string;
      }>;
    };

  const slug =
    product.slug?.toString().trim() ?? "";

  const image =
    product.images?.[0]?.src
      ?.toString()
      .trim() ?? "";

  console.log(
    `✅ WooCommerce Product Slug: ${slug}`,
  );

  console.log(
    `🖼️ WooCommerce Product Image: ${image}`,
  );

  return {
    slug,
    image,
  };
}

// ============================================================
// STOCK NOTIFICATION
// ============================================================

export const sendStockNotification = onCall(
  {
    region: "asia-south1",
  },

  async (request) => {
    console.log(
      "🔥 Stock Notification Function Triggered",
    );

    // ============================================================
    // AUTH CHECK
    // ============================================================

    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be authenticated to send stock notifications.",
      );
    }

    // ============================================================
    // INPUT
    // ============================================================

    const {
      productId,
      productName,
    } = request.data;

    if (!productId) {
      throw new HttpsError(
        "invalid-argument",
        "productId is required.",
      );
    }

    if (!productName) {
      throw new HttpsError(
        "invalid-argument",
        "productName is required.",
      );
    }

    const productIdString =
      productId.toString().trim();

    const productNameString =
      productName.toString().trim();

    console.log(
      `📦 Product: ${productNameString} (${productIdString})`,
    );

    // ============================================================
    // FETCH PRODUCT SLUG + IMAGE
    // ============================================================

    let productSlug = "";
    let productImage = "";

    try {
      const product =
        await fetchWooCommerceProduct(
          productIdString,
        );

      productSlug = product.slug;
      productImage = product.image;

      console.log(
        `🔗 Product slug: ${productSlug}`,
      );

      console.log(
        `🖼️ Product image: ${productImage}`,
      );
    } catch (error) {
      console.error(
        "⚠️ Could not fetch WooCommerce product details:",
        error,
      );

      // Do NOT stop the stock notification.
      // The notification can still be sent using productId.
    }

    // ============================================================
    // BATCH ID
    // ============================================================

    const batchId =
      `stock_${productIdString}_${Date.now()}`;

    try {
      // ============================================================
      // FIND ALL PENDING REQUESTS
      // ============================================================

      const snapshot =
        await db
          .collection(
            "stock_notifications",
          )
          .where(
            "productId",
            "==",
            productId,
          )
          .where(
            "status",
            "==",
            "pending",
          )
          .get();

      console.log(
        `👥 Stock notification requests found: ${snapshot.size}`,
      );

      if (snapshot.empty) {
        return {
          success: true,

          message:
            "No pending stock notification requests found.",

          productId:
            productIdString,

          productName:
            productNameString,

          slug:
            productSlug,

          image:
            productImage,

          totalRequests: 0,

          successCount: 0,

          failureCount: 0,
        };
      }

      // ============================================================
      // MARK REQUESTS AS SENDING
      // ============================================================

      const requests =
        snapshot.docs;

      for (
        let i = 0;
        i < requests.length;
        i += 500
      ) {
        const batchDocs =
          requests.slice(
            i,
            i + 500,
          );

        const writeBatch =
          db.batch();

        for (
          const doc of batchDocs
        ) {
          writeBatch.update(
            doc.ref,
            {
              status: "sending",

              notificationBatchId:
                batchId,

              // Save product information
              // for debugging/history.
              productSlug:
                productSlug || null,

              productImage:
                productImage || null,
            },
          );
        }

        await writeBatch.commit();
      }

      // ============================================================
      // GET USER IDS
      // ============================================================

      const userIds =
        requests
          .map(
            (doc) =>
              doc.data().userId,
          )
          .filter(
            (userId) =>
              userId != null &&
              userId
                .toString()
                .trim() !== "",
          );

      const uniqueUserIds =
        Array.from(
          new Set(
            userIds.map(
              (id) =>
                id.toString(),
            ),
          ),
        );

      console.log(
        `👤 Unique customers: ${uniqueUserIds.length}`,
      );

      // ============================================================
      // LOAD USERS
      // ============================================================

      const userTokenMap =
        new Map<string, string>();

      for (
        let i = 0;
        i < uniqueUserIds.length;
        i += USER_QUERY_BATCH
      ) {
        const ids =
          uniqueUserIds.slice(
            i,
            i + USER_QUERY_BATCH,
          );

        const usersSnapshot =
          await db
            .collection("Users")
            .where(
              admin.firestore.FieldPath
                .documentId(),
              "in",
              ids,
            )
            .get();

        usersSnapshot.docs.forEach(
          (userDoc) => {
            const token =
              userDoc.data().fcmToken;

            if (
              token != null &&
              token
                .toString()
                .trim() !== ""
            ) {
              userTokenMap.set(
                userDoc.id,
                token
                  .toString()
                  .trim(),
              );
            }
          },
        );
      }

      console.log(
        `📲 Customers with FCM tokens: ${userTokenMap.size}`,
      );

      // ============================================================
      // CUSTOMER → TOKEN
      // ============================================================

      const customerTokenMap =
        new Map<
          string,
          string
        >();

      for (
        const userId of uniqueUserIds
      ) {
        const token =
          userTokenMap.get(
            userId,
          );

        if (token) {
          customerTokenMap.set(
            userId,
            token,
          );
        }
      }

      const tokens =
        Array.from(
          new Set(
            customerTokenMap.values(),
          ),
        );

      console.log(
        `📲 Unique FCM tokens: ${tokens.length}`,
      );

      // ============================================================
      // NO FCM TOKENS
      // ============================================================

      if (tokens.length === 0) {
        console.log(
          "❌ No FCM tokens found.",
        );

        for (
          let i = 0;
          i < requests.length;
          i += 500
        ) {
          const requestBatch =
            requests.slice(
              i,
              i + 500,
            );

          const failedBatch =
            db.batch();

          for (
            const doc of requestBatch
          ) {
            failedBatch.update(
              doc.ref,
              {
                status: "failed",

                notificationError:
                  "Customer has no FCM token.",

                notificationBatchId:
                  batchId,
              },
            );
          }

          await failedBatch.commit();
        }

        return {
          success: false,

          message:
            "No FCM tokens found.",

          productId:
            productIdString,

          productName:
            productNameString,

          slug:
            productSlug,

          image:
            productImage,

          totalRequests:
            requests.length,

          successCount: 0,

          failureCount:
            requests.length,
        };
      }

      // ============================================================
      // NOTIFICATION
      // ============================================================

      const title =
        `${productNameString} is back in stock! 🎉`;

      const body =
        `Good news! ${productNameString} is now available. Tap to shop before it sells out.`;

      // ============================================================
      // FCM DATA PAYLOAD
      // ============================================================

      const notificationData: Record<
        string,
        string
      > = {
        type:
          "stock_available",

        productId:
          productIdString,

        productName:
          productNameString,
      };

      // Add slug when available
      if (
        productSlug.trim() !== ""
      ) {
        notificationData.slug =
          productSlug;
      }

      // Add image when available
      if (
        productImage.trim() !== ""
      ) {
        notificationData.image =
          productImage;
      }

      console.log(
        "📦 FCM Payload:",
        JSON.stringify(
          notificationData,
          null,
          2,
        ),
      );

      // ============================================================
      // SEND NOTIFICATION
      // ============================================================

      let totalSuccess = 0;
      let totalFailure = 0;

      const successfulTokens =
        new Set<string>();

      const failedTokens =
        new Set<string>();

      const totalBatches =
        Math.ceil(
          tokens.length /
            FCM_BATCH_SIZE,
        );

      console.log(
        `📦 Sending ${tokens.length} tokens in ${totalBatches} FCM batch(es)`,
      );

      for (
        let i = 0;
        i < tokens.length;
        i += FCM_BATCH_SIZE
      ) {
        const tokenBatch =
          tokens.slice(
            i,
            i + FCM_BATCH_SIZE,
          );

        const batchNumber =
          Math.floor(
            i / FCM_BATCH_SIZE,
          ) + 1;

        console.log(
          `📤 Sending FCM batch ${batchNumber}/${totalBatches}`,
        );

        try {
          const message: admin.messaging.MulticastMessage =
            {
              tokens:
                tokenBatch,

              // ==============================================
              // NOTIFICATION
              // ==============================================

              notification: {
                title,
                body,

                ...(productImage
                  ? {
                      imageUrl:
                        productImage,
                    }
                  : {}),
              },

              // ==============================================
              // DATA
              // ==============================================

              data:
                notificationData,

              // ==============================================
              // ANDROID
              // ==============================================

              android: {
                priority:
                  "high",

                notification: {
                  channelId:
                    "glowfit_notifications",

                  sound:
                    "default",

                  ...(productImage
                    ? {
                        imageUrl:
                          productImage,
                      }
                    : {}),
                },
              },

              // ==============================================
              // IOS
              // ==============================================

              apns: {
                payload: {
                  aps: {
                    alert: {
                      title,
                      body,
                    },

                    sound:
                      "default",

                    badge: 1,

                    mutableContent:
                      true,
                  },
                },

                ...(productImage
                  ? {
                      fcmOptions: {
                        imageUrl:
                          productImage,
                      },
                    }
                  : {}),
              },
            };

          const response =
            await admin
              .messaging()
              .sendEachForMulticast(
                message,
              );

          totalSuccess +=
            response.successCount;

          totalFailure +=
            response.failureCount;

          // ========================================================
          // PROCESS RESULTS
          // ========================================================

          response.responses.forEach(
            (
              result,
              index,
            ) => {
              const token =
                tokenBatch[index];

              if (
                result.success
              ) {
                successfulTokens.add(
                  token,
                );
              } else {
                failedTokens.add(
                  token,
                );

                console.error(
                  `❌ FCM failed for token ${token}`,
                  result.error,
                );
              }
            },
          );

          console.log(
            `✅ Batch ${batchNumber}: ${response.successCount} sent`,
          );

          console.log(
            `❌ Batch ${batchNumber}: ${response.failureCount} failed`,
          );
        } catch (error) {
          console.error(
            `❌ FCM batch ${batchNumber} failed`,
            error,
          );

          totalFailure +=
            tokenBatch.length;

          tokenBatch.forEach(
            (token) =>
              failedTokens.add(
                token,
              ),
          );
        }
      }

      // ============================================================
      // UPDATE STOCK NOTIFICATION REQUESTS
      // ============================================================

      let notifiedRequests = 0;
      let failedRequests = 0;

      for (
        let i = 0;
        i < requests.length;
        i += 500
      ) {
        const requestBatch =
          requests.slice(
            i,
            i + 500,
          );

        const writeBatch =
          db.batch();

        for (
          const doc of requestBatch
        ) {
          const requestData =
            doc.data();

          const userId =
            requestData.userId
              ?.toString();

          const token =
            userId
              ? customerTokenMap.get(
                  userId,
                )
              : null;

          if (
            token &&
            successfulTokens.has(
              token,
            )
          ) {
            writeBatch.update(
              doc.ref,
              {
                status:
                  "notified",

                notifiedAt:
                  admin.firestore
                    .FieldValue
                    .serverTimestamp(),

                notificationBatchId:
                  batchId,

                productSlug:
                  productSlug || null,

                productImage:
                  productImage || null,

                notificationError:
                  admin.firestore
                    .FieldValue
                    .delete(),
              },
            );

            notifiedRequests++;
          } else {
            writeBatch.update(
              doc.ref,
              {
                status: "failed",

                notificationBatchId:
                  batchId,

                productSlug:
                  productSlug || null,

                productImage:
                  productImage || null,

                notificationError:
                  token
                    ? "FCM notification failed."
                    : "Customer has no FCM token.",
              },
            );

            failedRequests++;
          }
        }

        await writeBatch.commit();
      }

      // ============================================================
      // RESULT
      // ============================================================

      console.log(
        "====================================",
      );

      console.log(
        "🎉 STOCK NOTIFICATION COMPLETE",
      );

      console.log(
        `📦 Product: ${productNameString}`,
      );

      console.log(
        `🆔 Product ID: ${productIdString}`,
      );

      console.log(
        `🔗 Slug: ${productSlug}`,
      );

      console.log(
        `🖼️ Image: ${productImage}`,
      );

      console.log(
        `👥 Requests: ${requests.length}`,
      );

      console.log(
        `📲 Tokens: ${tokens.length}`,
      );

      console.log(
        `✅ FCM Success: ${totalSuccess}`,
      );

      console.log(
        `❌ FCM Failed: ${totalFailure}`,
      );

      console.log(
        `✅ Requests Notified: ${notifiedRequests}`,
      );

      console.log(
        `❌ Requests Failed: ${failedRequests}`,
      );

      console.log(
        `🆔 Batch ID: ${batchId}`,
      );

      console.log(
        "====================================",
      );

      return {
        success:
          notifiedRequests > 0,

        productId:
          productIdString,

        productName:
          productNameString,

        slug:
          productSlug,

        image:
          productImage,

        batchId,

        totalRequests:
          requests.length,

        uniqueCustomers:
          uniqueUserIds.length,

        tokens:
          tokens.length,

        successCount:
          totalSuccess,

        failureCount:
          totalFailure,

        notifiedRequests,

        failedRequests,
      };
    } catch (error) {
      console.error(
        "❌ Stock Notification Error",
        error,
      );

      // ============================================================
      // MARK BATCH REQUESTS AS FAILED
      // ============================================================

      try {
        const failedSnapshot =
          await db
            .collection(
              "stock_notifications",
            )
            .where(
              "productId",
              "==",
              productId,
            )
            .where(
              "notificationBatchId",
              "==",
              batchId,
            )
            .get();

        for (
          let i = 0;
          i <
          failedSnapshot.docs.length;
          i += 500
        ) {
          const docs =
            failedSnapshot.docs.slice(
              i,
              i + 500,
            );

          const batch =
            db.batch();

          for (
            const doc of docs
          ) {
            batch.update(
              doc.ref,
              {
                status: "failed",

                notificationError:
                  error instanceof Error
                    ? error.message
                    : String(error),

                notificationBatchId:
                  batchId,
              },
            );
          }

          await batch.commit();
        }
      } catch (updateError) {
        console.error(
          "❌ Failed to update stock notification documents:",
          updateError,
        );
      }

      throw new HttpsError(
        "internal",

        error instanceof Error
          ? error.message
          : "Failed to send stock notifications.",
      );
    }
  },
);