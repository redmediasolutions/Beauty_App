import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:glowfit/services/gorouter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

final FlutterLocalNotificationsPlugin
    flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class PushNotificationService {
  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> init() async {
    debugPrint(
      '🚀 PushNotificationService.init()',
    );

    // Background FCM handler
    FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler,
    );

    debugPrint(
      '✅ Background handler registered',
    );

    // Local notifications
    await _initializeLocalNotifications();

    debugPrint(
      '✅ Local notifications initialized',
    );

    // Permission + token
    await _requestPermissionAndSaveToken();

    // =======================================================
    // APP OPENED FROM TERMINATED STATE
    // =======================================================

    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance
            .getInitialMessage();

    debugPrint(
      '📨 getInitialMessage: ${initialMessage?.data}',
    );

    if (initialMessage != null) {
      _handleNavigation(
        initialMessage.data,
      );
    }

    // =======================================================
    // APP OPENED FROM BACKGROUND
    // =======================================================

    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        debugPrint(
          '📲 Notification opened from background',
        );

        debugPrint(
          '📦 Data: ${message.data}',
        );

        _handleNavigation(
          message.data,
        );
      },
    );
  }

  // =========================================================
  // BACKGROUND MESSAGE
  // =========================================================

  static Future<void>
      _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    debugPrint(
      '🌙 Background Message Received',
    );

    debugPrint(
      '🌙 Title: ${message.notification?.title}',
    );

    debugPrint(
      '🌙 Body: ${message.notification?.body}',
    );

    debugPrint(
      '🌙 Data: ${message.data}',
    );
  }

  // =========================================================
  // PERMISSION + TOKEN
  // =========================================================

  static Future<void>
      _requestPermissionAndSaveToken() async {
    debugPrint(
      '🔔 Requesting notification permission...',
    );

    final FirebaseMessaging messaging =
        FirebaseMessaging.instance;

    final NotificationSettings settings =
        await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint(
      '🔔 Permission Status: '
      '${settings.authorizationStatus}',
    );

    if (settings.authorizationStatus !=
        AuthorizationStatus.authorized) {
      debugPrint(
        '❌ Notification permission denied',
      );

      return;
    }

    final String? token =
        await messaging.getToken();

    debugPrint(
      '📲 FCM Token: $token',
    );

    await _saveToken(token);

    FirebaseMessaging.instance
        .onTokenRefresh
        .listen(
      (String newToken) async {
        debugPrint(
          '🔄 Token Refreshed',
        );

        await _saveToken(
          newToken,
        );
      },
    );
  }

  // =========================================================
  // SAVE TOKEN
  // =========================================================

  static Future<void> _saveToken(
    String? token,
  ) async {
    if (token == null ||
        token.trim().isEmpty) {
      debugPrint(
        '❌ Token is null/empty',
      );

      return;
    }

    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      debugPrint(
        '❌ User not logged in. Token not saved.',
      );

      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(user.uid)
          .set(
        {
          'fcmToken': token,
          'lastTokenUpdate':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        '✅ Token saved to Firestore',
      );
    } catch (e) {
      debugPrint(
        '❌ Failed to save FCM token: $e',
      );
    }
  }

  // =========================================================
  // LOCAL NOTIFICATION INITIALIZATION
  // =========================================================

  static Future<void>
      _initializeLocalNotifications() async {
    // =======================================================
    // ANDROID
    // =======================================================

    const AndroidInitializationSettings
        android =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // =======================================================
    // IOS
    // =======================================================

    const DarwinInitializationSettings
        ios =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // =======================================================
    // SETTINGS
    // =======================================================

    const InitializationSettings settings =
        InitializationSettings(
      android: android,
      iOS: ios,
    );

    await flutterLocalNotificationsPlugin
        .initialize(
      settings: settings,
      onDidReceiveNotificationResponse:
          _onLocalNotificationTapped,
    );

    // =======================================================
    // ANDROID CHANNEL
    // =======================================================

    const AndroidNotificationChannel
        channel =
        AndroidNotificationChannel(
      'glowfit_notifications',
      'GlowFit Notifications',
      description:
          'General app notifications',
      importance:
          Importance.max,
      playSound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          channel,
        );

    // =======================================================
    // FOREGROUND MESSAGES
    // =======================================================

    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint(
          '📩 Foreground notification received',
        );

        debugPrint(
          '📌 Title: '
          '${message.notification?.title}',
        );

        debugPrint(
          '📌 Body: '
          '${message.notification?.body}',
        );

        debugPrint(
          '📦 Data: ${message.data}',
        );

        final RemoteNotification? notification =
            message.notification;

        if (notification == null) {
          debugPrint(
            '⚠️ No notification payload',
          );

          return;
        }

        final String payload =
            jsonEncode(
          message.data,
        );

        await _showLocalNotification(
          notificationId:
              DateTime.now()
                  .millisecondsSinceEpoch
                  .remainder(2147483647),
          title:
              notification.title ?? '',
          body:
              notification.body ?? '',
          data:
              message.data,
          payload:
              payload,
        );
      },
    );
  }

  // =========================================================
  // SHOW LOCAL NOTIFICATION
  // =========================================================

  static Future<void>
      _showLocalNotification({
    required int notificationId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String payload,
  }) async {
    // =======================================================
    // IMAGE
    // =======================================================

    final String? imageUrl =
        _getImageUrl(data);

    debugPrint(
      '🖼 Notification image: $imageUrl',
    );

    // =======================================================
    // ANDROID DETAILS
    // =======================================================

    AndroidNotificationDetails
        androidDetails;

    if (imageUrl != null &&
        imageUrl.isNotEmpty) {
      try {
        final String? imagePath =
            await _downloadNotificationImage(
          imageUrl,
        );

        if (imagePath != null) {
          final BigPictureStyleInformation
              bigPicture =
              BigPictureStyleInformation(
            FilePathAndroidBitmap(
              imagePath,
            ),

            largeIcon:
                const DrawableResourceAndroidBitmap(
              '@mipmap/ic_launcher',
            ),

            contentTitle:
                title,

            summaryText:
                body,

            hideExpandedLargeIcon:
                false,
          );

          androidDetails =
              AndroidNotificationDetails(
            'glowfit_notifications',
            'GlowFit Notifications',
            channelDescription:
                'General app notifications',
            importance:
                Importance.max,
            priority:
                Priority.high,
            playSound: true,
            enableVibration: true,
            styleInformation:
                bigPicture,
          );

          debugPrint(
            '✅ Notification image loaded',
          );
        } else {
          androidDetails =
              _defaultAndroidDetails();
        }
      } catch (e) {
        debugPrint(
          '⚠️ Failed loading notification image: $e',
        );

        androidDetails =
            _defaultAndroidDetails();
      }
    } else {
      androidDetails =
          _defaultAndroidDetails();
    }

    // =======================================================
    // SHOW
    // =======================================================

    await flutterLocalNotificationsPlugin.show(
  id: notificationId,
  title: title,
  body: body,
  notificationDetails: NotificationDetails(
    android: androidDetails,
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  ),
  payload: payload,
);
  }

  // =========================================================
  // DEFAULT ANDROID DETAILS
  // =========================================================

  static AndroidNotificationDetails
      _defaultAndroidDetails() {
    return const AndroidNotificationDetails(
      'glowfit_notifications',
      'GlowFit Notifications',
      channelDescription:
          'General app notifications',
      importance:
          Importance.max,
      priority:
          Priority.high,
      playSound: true,
      enableVibration: true,
    );
  }

  // =========================================================
  // GET IMAGE URL
  // =========================================================

  static String? _getImageUrl(
    Map<String, dynamic> data,
  ) {
    final possibleKeys = [
      'image',
      'imageUrl',
      'image_url',
      'productImage',
      'product_image',
    ];

    for (final key in possibleKeys) {
      final value =
          data[key]?.toString().trim();

      if (value != null &&
          value.isNotEmpty &&
          (value.startsWith('http://') ||
              value.startsWith('https://'))) {
        return value;
      }
    }

    return null;
  }

  // =========================================================
  // DOWNLOAD NOTIFICATION IMAGE
  // =========================================================

  static Future<String?>
      _downloadNotificationImage(
    String imageUrl,
  ) async {
    try {
      debugPrint(
        '⬇️ Downloading notification image...',
      );

      final response =
          await http.get(
        Uri.parse(imageUrl),
      );

      if (response.statusCode != 200) {
        debugPrint(
          '❌ Image download failed: '
          '${response.statusCode}',
        );

        return null;
      }

      final Directory directory =
          await getTemporaryDirectory();

      final String fileName =
          'notification_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final File file =
          File(
        '${directory.path}/$fileName',
      );

      await file.writeAsBytes(
        response.bodyBytes,
      );

      debugPrint(
        '✅ Image saved: ${file.path}',
      );

      return file.path;
    } catch (e) {
      debugPrint(
        '❌ Image download error: $e',
      );

      return null;
    }
  }

  // =========================================================
  // LOCAL NOTIFICATION TAP
  // =========================================================

  static void _onLocalNotificationTapped(
    NotificationResponse response,
  ) {
    debugPrint(
      '👆 Local notification tapped',
    );

    final String? payload =
        response.payload;

    debugPrint(
      '📦 Payload: $payload',
    );

    if (payload == null ||
        payload.trim().isEmpty) {
      debugPrint(
        '⚠️ Empty notification payload',
      );

      return;
    }

    try {
      final dynamic decoded =
          jsonDecode(payload);

      if (decoded is! Map) {
        debugPrint(
          '❌ Invalid notification payload',
        );

        return;
      }

      final Map<String, dynamic>
          data =
          Map<String, dynamic>.from(
        decoded,
      );

      debugPrint(
        '✅ Parsed notification data: $data',
      );

      _handleNavigation(data);
    } catch (e) {
      debugPrint(
        '❌ Notification payload parse error: $e',
      );
    }
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  static Future<void> _handleNavigation(
    Map<String, dynamic> data,
  ) async {
    debugPrint(
      '🧭 Handling notification navigation',
    );

    debugPrint(
      '📦 Data: $data',
    );

    await Future.delayed(
      const Duration(
        milliseconds: 500,
      ),
    );

    // =======================================================
    // PRODUCT SLUG
    // =======================================================

    final String? slug =
        data['slug']
            ?.toString()
            .trim();

    if (slug != null &&
        slug.isNotEmpty) {
      final String encodedSlug =
          Uri.encodeComponent(
        slug,
      );

      final String route =
          '/products/$encodedSlug';

      debugPrint(
        '🛍 Opening product by slug: $route',
      );

      AppRouter.router.push(
        route,
      );

      return;
    }

    // =======================================================
    // PRODUCT ID FALLBACK
    // =======================================================

    final String? productId =
        data['productId']
            ?.toString()
            .trim();

    if (productId != null &&
        productId.isNotEmpty) {
      final String route =
          '/product/$productId';

      debugPrint(
        '🛍 Opening product by ID: $route',
      );

      AppRouter.router.push(
        route,
      );

      return;
    }

    // =======================================================
    // TYPE
    // =======================================================

    final String? type =
        data['type']
            ?.toString();

    switch (type) {
      case 'reward':
        AppRouter.router.go(
          '/points',
        );
        break;

      case 'order':
        final String? orderId =
            data['orderId']
                ?.toString()
                .trim();

        if (orderId != null &&
            orderId.isNotEmpty) {
          AppRouter.router.push(
            '/order/$orderId',
          );
        } else {
          AppRouter.router.go(
            '/orders',
          );
        }
        break;

      case 'coupon':
        AppRouter.router.go(
          '/',
        );
        break;

      case 'referral':
        AppRouter.router.go(
          '/points',
        );
        break;

      case 'product':
        AppRouter.router.go(
          '/',
        );
        break;

      default:
        AppRouter.router.go(
          '/',
        );
        break;
    }
  }
}