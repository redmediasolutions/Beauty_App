import * as admin from "firebase-admin";

import {
  onDocumentCreated,
} from "firebase-functions/v2/firestore";

export const sendNotificationOnCreate =
  onDocumentCreated(
    {
      document:
        "notifications/{notificationId}",

      region:
        "asia-south1",
    },

    async (event) => {

      console.log(
        "🔥 Notification Function Triggered",
      );

      const snapshot =
        event.data;

      if (!snapshot) {

        console.log(
          "❌ No snapshot received",
        );

        return;
      }

      const data =
        snapshot.data();

      console.log(
        "📦 Notification Data:",
        JSON.stringify(
          data,
          null,
          2,
        ),
      );

      try {

        // =====================================
        // LOAD ALL USER TOKENS
        // =====================================

        const usersSnapshot =
          await admin
            .firestore()
            .collection(
              "Users",
            )
            .get();

        const tokens: string[] =
  usersSnapshot.docs
    .map(
      (doc) =>
        doc.data().fcmToken,
    )
    .filter(
      (token) =>
        token != null &&
        token.toString().trim() !== "",
    );

        console.log(
          `👥 Users Found: ${usersSnapshot.docs.length}`,
        );

        console.log(
          `📲 Tokens Found: ${tokens.length}`,
        );

        if (tokens.length === 0) {

  console.log(

    "❌ No FCM tokens found",

  );

  await snapshot.ref.update({

    status: "failed",

    error:

      "No FCM tokens available",

    processedAt:

      admin.firestore

        .FieldValue

        .serverTimestamp(),

  });

  return;

}

        // =====================================
        // SEND NOTIFICATION
        // =====================================

        const response =
          await admin
            .messaging()
            .sendEachForMulticast({

              tokens,

              notification: {

                title:
                  data.title ??
                  "",

                body:
                  data.body ??
                  "",
              },

              data: {

                type:
                  data.type ??
                  "general",
              },
            });

        console.log(
          `✅ Success: ${response.successCount}`,
        );

        console.log(
          `❌ Failed: ${response.failureCount}`,
        );

        // =====================================
        // LOG FAILURES
        // =====================================

        response.responses.forEach(
          (
            result,
            index,
          ) => {

            if (
              !result.success
            ) {

              console.log(
                `❌ Invalid Token: ${tokens[index]}`,
              );

              console.log(
                result.error,
              );
            }
          },
        );

        // =====================================
        // UPDATE FIRESTORE
        // =====================================

        await snapshot.ref.update({

          status:
            "sent",

          sentAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),

          totalAudience:
            tokens.length,

          successCount:
            response.successCount,

          failureCount:
            response.failureCount,
        });

        console.log(
          "✅ Firestore Updated",
        );

      } catch (error) {

        console.error(
          "❌ Notification Failed",
          error,
        );

        await snapshot.ref.update({

          status:
            "failed",

          error:
            error instanceof Error
              ? error.message
              : String(
                  error,
                ),

          failedAt:
            admin.firestore
              .FieldValue
              .serverTimestamp(),
        });
      }
    },
  );