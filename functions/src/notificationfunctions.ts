import * as admin from "firebase-admin";

import {
  onDocumentCreated,
} from "firebase-functions/v2/firestore";

const FCM_BATCH_SIZE = 500;

export const sendNotificationOnCreate =
  onDocumentCreated(
    {
      document: "notifications/{notificationId}",
      region: "asia-south1",
    },

    async (event) => {
      console.log("🔥 Notification Function Triggered");

      const snapshot = event.data;

      if (!snapshot) {
        console.log("❌ No snapshot received");
        return;
      }

      const data = snapshot.data();

      console.log(
        "📦 Notification Data:",
        JSON.stringify(data, null, 2),
      );

      try {
        // =====================================
        // LOAD ALL USER TOKENS
        // =====================================

        const usersSnapshot =
          await admin
            .firestore()
            .collection("Users")
            .get();

        // =====================================
        // GET UNIQUE TOKENS
        // =====================================

        const tokenSet = new Set<string>();

        usersSnapshot.docs.forEach((doc) => {
          const token = doc.data().fcmToken;

          if (
            token != null &&
            token.toString().trim() !== ""
          ) {
            tokenSet.add(
              token.toString().trim(),
            );
          }
        });

        const tokens = Array.from(tokenSet);

        console.log(
          `👥 Users Found: ${usersSnapshot.docs.length}`,
        );

        console.log(
          `📲 Unique Tokens Found: ${tokens.length}`,
        );

        // =====================================
        // NO TOKENS
        // =====================================

        if (tokens.length === 0) {
          console.log(
            "❌ No FCM tokens found",
          );

          await snapshot.ref.update({
            status: "failed",

            error:
              "No FCM tokens available",

            processedAt:
              admin.firestore.FieldValue
                .serverTimestamp(),
          });

          return;
        }

        // =====================================
        // NOTIFICATION
        // =====================================

        const notification = {
          title:
            data.title?.toString() ?? "",

          body:
            data.body?.toString() ?? "",

          // ===================================
          // Android notification image
          // ===================================

          imageUrl:
            data.image?.toString() ||
            data.imageUrl?.toString() ||
            undefined,
        };

        // =====================================
        // FCM DATA PAYLOAD
        // =====================================
        //
        // IMPORTANT:
        // FCM data values MUST be strings.
        //
        // =====================================

        const notificationData: Record<
          string,
          string
        > = {
          type:
            data.type?.toString() ??
            "general",
        };

        // =====================================
        // PRODUCT DATA
        // =====================================

        if (
          data.slug != null &&
          data.slug
            .toString()
            .trim() !== ""
        ) {
          notificationData.slug =
            data.slug
              .toString()
              .trim();
        }

        if (
          data.productId != null &&
          data.productId
            .toString()
            .trim() !== ""
        ) {
          notificationData.productId =
            data.productId
              .toString()
              .trim();
        }

        // =====================================
        // IMAGE
        // =====================================

        const imageUrl =
          data.image?.toString() ||
          data.imageUrl?.toString() ||
          data.productImage?.toString() ||
          "";

        if (imageUrl.trim() !== "") {
          notificationData.image =
            imageUrl.trim();
        }

        // =====================================
        // ORDER DATA
        // =====================================

        if (
          data.orderId != null &&
          data.orderId
            .toString()
            .trim() !== ""
        ) {
          notificationData.orderId =
            data.orderId
              .toString()
              .trim();
        }

        // =====================================
        // COUPON DATA
        // =====================================

        if (
          data.couponId != null &&
          data.couponId
            .toString()
            .trim() !== ""
        ) {
          notificationData.couponId =
            data.couponId
              .toString()
              .trim();
        }

        if (
          data.couponCode != null &&
          data.couponCode
            .toString()
            .trim() !== ""
        ) {
          notificationData.couponCode =
            data.couponCode
              .toString()
              .trim();
        }

        // =====================================
        // REFERRAL DATA
        // =====================================

        if (
          data.referralCode != null &&
          data.referralCode
            .toString()
            .trim() !== ""
        ) {
          notificationData.referralCode =
            data.referralCode
              .toString()
              .trim();
        }

        // =====================================
        // DEBUG
        // =====================================

        console.log(
          "🔔 Notification:",
          JSON.stringify(
            notification,
            null,
            2,
          ),
        );

        console.log(
          "📦 FCM Data Payload:",
          JSON.stringify(
            notificationData,
            null,
            2,
          ),
        );

        // =====================================
        // SEND IN BATCHES OF 500
        // =====================================

        let totalSuccess = 0;
        let totalFailure = 0;

        const invalidTokens: string[] = [];

        const totalBatches =
          Math.ceil(
            tokens.length /
              FCM_BATCH_SIZE,
          );

        console.log(
          `📦 Sending ${tokens.length} tokens in ${totalBatches} batch(es)`,
        );

        for (
          let i = 0;
          i < tokens.length;
          i += FCM_BATCH_SIZE
        ) {
          const batch =
            tokens.slice(
              i,
              i + FCM_BATCH_SIZE,
            );

          const batchNumber =
            Math.floor(
              i / FCM_BATCH_SIZE,
            ) + 1;

          console.log(
            `📤 Sending batch ${batchNumber}/${totalBatches} (${batch.length} tokens)`,
          );

          try {
            const response =
              await admin
                .messaging()
                .sendEachForMulticast({
                  tokens: batch,

                  // =================================
                  // NOTIFICATION
                  // =================================

                  notification: {
                    title:
                      notification.title,

                    body:
                      notification.body,

                    ...(imageUrl
                      ? {
                          imageUrl:
                            imageUrl,
                        }
                      : {}),
                  },

                  // =================================
                  // DATA
                  // =================================

                  data:
                    notificationData,

                  // =================================
                  // ANDROID
                  // =================================

                  android: {
                    priority:
                      "high",

                    notification: {
                      channelId:
                        "glowfit_notifications",

                      sound:
                        "default",

                      ...(imageUrl
                        ? {
                            imageUrl:
                              imageUrl,
                          }
                        : {}),
                    },
                  },

                  // =================================
                  // IOS / APNS
                  // =================================

                  apns: {
                    payload: {
                      aps: {
                        alert: {
                          title:
                            notification.title,

                          body:
                            notification.body,
                        },

                        sound:
                          "default",

                        badge: 1,

                        mutableContent:
                          true,
                      },
                    },

                    ...(imageUrl
                      ? {
                          fcmOptions: {
                            imageUrl:
                              imageUrl,
                          },
                        }
                      : {}),
                  },
                });

            totalSuccess +=
              response.successCount;

            totalFailure +=
              response.failureCount;

            console.log(
              `✅ Batch ${batchNumber}: ${response.successCount} successful`,
            );

            console.log(
              `❌ Batch ${batchNumber}: ${response.failureCount} failed`,
            );

            // =====================================
            // CHECK FAILED TOKENS
            // =====================================

            response.responses.forEach(
              (result, index) => {
                if (!result.success) {
                  const token =
                    batch[index];

                  console.log(
                    `❌ Token failed: ${token}`,
                  );

                  console.log(
                    result.error,
                  );

                  const errorCode =
                    result.error?.code;

                  if (
                    errorCode ===
                      "messaging/registration-token-not-registered" ||
                    errorCode ===
                      "messaging/invalid-registration-token"
                  ) {
                    invalidTokens.push(
                      token,
                    );
                  }
                }
              },
            );
          } catch (batchError) {
            console.error(
              `❌ Batch ${batchNumber} failed`,
              batchError,
            );
          }
        }

        // =====================================
        // REMOVE INVALID TOKENS
        // =====================================

        if (
          invalidTokens.length >
          0
        ) {
          console.log(
            `🧹 Invalid tokens found: ${invalidTokens.length}`,
          );

          const invalidTokenSet =
            new Set(
              invalidTokens,
            );

          const cleanupPromises =
            usersSnapshot.docs
              .filter((doc) => {
                const token =
                  doc.data()
                    .fcmToken;

                return (
                  token &&
                  invalidTokenSet.has(
                    token
                      .toString()
                      .trim(),
                  )
                );
              })
              .map((doc) =>
                doc.ref.update({
                  fcmToken:
                    admin.firestore
                      .FieldValue
                      .delete(),
                }),
              );

          await Promise.all(
            cleanupPromises,
          );

          console.log(
            `🧹 Removed ${cleanupPromises.length} invalid FCM token(s)`,
          );
        }

        // =====================================
        // FINAL STATUS
        // =====================================

        let status =
          "sent";

        if (
          totalSuccess === 0 &&
          totalFailure > 0
        ) {
          status =
            "failed";
        } else if (
          totalSuccess > 0 &&
          totalFailure > 0
        ) {
          status =
            "partial";
        }

        // =====================================
        // UPDATE FIRESTORE
        // =====================================

        await snapshot.ref.update({
          status,

          sentAt:
            totalSuccess > 0
              ? admin.firestore
                  .FieldValue
                  .serverTimestamp()
              : null,

          processedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),

          totalAudience:
            tokens.length,

          successCount:
            totalSuccess,

          failureCount:
            totalFailure,

          invalidTokenCount:
            invalidTokens.length,

          // Save exactly what was sent
          payload: {
            notification,

            data:
              notificationData,
          },
        });

        console.log(
          "🎉 Notification Complete",
        );

        console.log(
          `👥 Audience: ${tokens.length}`,
        );

        console.log(
          `✅ Success: ${totalSuccess}`,
        );

        console.log(
          `❌ Failed: ${totalFailure}`,
        );

        console.log(
          `🧹 Invalid Tokens: ${invalidTokens.length}`,
        );

        console.log(
          `📊 Status: ${status}`,
        );
      } catch (error) {
        console.error(
          "❌ Notification Failed",
          error,
        );

        await snapshot.ref.update({
          status: "failed",

          error:
            error instanceof Error
              ? error.message
              : String(error),

          failedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        });
      }
    },
  );