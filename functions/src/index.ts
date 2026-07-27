import { onRequest } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import axios from "axios";
import { Request, Response } from "express";
import { sendWelcomeMessage } from "./whatsapp";

// =======================================================
// 📦 IMPORT CART FUNCTIONS
// =======================================================

// =======================================================
// 🔥 INIT
// =======================================================

admin.initializeApp();

export {
  getCartRates,
  getCartPreviewTotals,
  createSecureOrder,
  finalizeOrder,
  wooOrderStatusWebhook,
} from "./cartfunctions";

export * from "./notificationfunctions";
export * from "./ordertriggers";



// =======================================================
// 🔐 MSG91 CONFIG (GLADSKIN)
// =======================================================

const MSG91_AUTH_KEY =
  "507198AvcFM6KC2X69f344baP1";

const MSG91_WIDGET_ID =
  "3664446b584a343130353532";

// =======================================================
// 🔐 OTP - SEND
// =======================================================

export const sendGladskinOtp =
  onRequest(
    { cors: true },
    async (
      req: Request,
      res: Response
    ): Promise<void> => {
      try {
        console.log(
          "🔥 sendGladskinOtp triggered"
        );

        if (req.method !== "POST") {
          res.status(405).json({
            error:
              "Method not allowed",
          });

          return;
        }

        const { phoneNumber } =
          req.body;

        if (!phoneNumber) {
          res.status(400).json({
            error:
              "Phone number required",
          });

          return;
        }

        let cleanPhone =
          phoneNumber.replace(
            /\D/g,
            ""
          );

        if (
          cleanPhone.length === 10
        ) {
          cleanPhone =
            "91" + cleanPhone;
        }

        const response =
          await axios.post(
            "https://api.msg91.com/api/v5/widget/sendOtp",
            {
              widgetId:
                MSG91_WIDGET_ID,

              identifier:
                cleanPhone,
            },
            {
              headers: {
                authkey:
                  MSG91_AUTH_KEY,
              },
            }
          );

        const reqId =
          response.data?.reqId ||
          response.data?.message;

        res.json({
          success: true,
          reqId,
        });
      } catch (error: any) {
        console.error(
          "🔥 ERROR in sendGladskinOtp:",
          error
        );

        res.status(500).json({
          success: false,
        });
      }
    }
  );

// =======================================================
// 🔐 OTP VERIFY
// =======================================================

export const verifyGladskinOtp =
  onRequest(
    {
      cors: true,
      maxInstances: 10,
      concurrency: 80,
    },
    async (
      req: Request,
      res: Response
    ): Promise<void> => {
      const {
        phoneNumber,
        otp,
        reqId,
      } = req.body;

      if (
        !phoneNumber ||
        !otp ||
        !reqId
      ) {
        res.status(400).json({
          success: false,

          message:
            "Missing phone / otp / reqId",
        });

        return;
      }

      let cleanPhone =
        phoneNumber.replace(
          /\D/g,
          ""
        );

      if (
        cleanPhone.length === 10
      ) {
        cleanPhone =
          "91" + cleanPhone;
      }

      try {
        // ===================================================
        // 🔥 VERIFY OTP
        // ===================================================

        const msg91Response =
          await axios.post(
            "https://api.msg91.com/api/v5/widget/verifyOtp",
            {
              widgetId:
                MSG91_WIDGET_ID,

              mobile:
                cleanPhone,

              otp,

              reqId,
            },
            {
              headers: {
                authkey:
                  MSG91_AUTH_KEY,

                "Content-Type":
                  "application/json",
              },
            }
          );

        const msg91Data =
          msg91Response.data;

        if (
          msg91Data.type !==
          "success"
        ) {
          res.status(400).json({
            success: false,

            message:
              msg91Data.message ||
              "Invalid OTP",
          });

          return;
        }

        // ===================================================
        // 🔥 USER HANDLING
        // ===================================================

        const db =
          admin.firestore();

        let userRecord:
          | admin.auth.UserRecord;

        let isNewUser = false;

        try {
          userRecord =
            await admin
              .auth()
              .getUserByPhoneNumber(
                "+" + cleanPhone
              );
        } catch (e) {
          userRecord =
            await admin
              .auth()
              .createUser({
                phoneNumber:
                  "+" + cleanPhone,
              });

          isNewUser = true;
        }

        // ===================================================
        // 🔥 USER DOC
        // ===================================================

        const userDocRef =
          db
            .collection("Users")
            .doc(userRecord.uid);

        const userDoc =
          await userDocRef.get();

        if (!userDoc.exists) {
          await userDocRef.set(
            {
              uid:
                userRecord.uid,

              phone_number:
                "+" + cleanPhone,

              display_name:
                "",

              email: "",

              isUserProfileComplete:
                false,

              created_time:
                admin.firestore
                  .FieldValue.serverTimestamp(),

              updatedAt:
                admin.firestore
                  .FieldValue.serverTimestamp(),

              referralCode:
                null,

              referredBy:
                null,

              referredByPhone:
                null,

              referredByUserId:
                null,

              referralUpdatedAt:
                null,

              walletBalance: 0,

              walletTotalEarned: 0,

              walletTotalUsed: 0,

              rewardPoints: 0,

              fcmToken: null,

              lastSelectedAddress:
                null,
            },
            { merge: true }
          );

            await sendWelcomeMessage(cleanPhone);

        } else {
          await userDocRef.update({
            updatedAt:
              admin.firestore
                .FieldValue.serverTimestamp(),
          });
        }

        // ===================================================
        // 🔐 TOKEN
        // ===================================================

        const customToken =
          await admin
            .auth()
            .createCustomToken(
              userRecord.uid
            );

        res.json({
          success: true,

          token: customToken,

          isNewUser,
        });

        return;
      } catch (error: any) {
        console.error(
          "🔥 VERIFY OTP ERROR:",
          error
        );

        res.status(500).json({
          success: false,

          error:
            "Internal Server Error",
        });

        return;
      }
    }
  );