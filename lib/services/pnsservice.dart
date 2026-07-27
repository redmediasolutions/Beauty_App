import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:glowfit/services/gorouter.dart';
<<<<<<< Updated upstream
import 'package:go_router/go_router.dart';
=======
>>>>>>> Stashed changes

final FlutterLocalNotificationsPlugin
    flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class PushNotificationService {

  static Future<void> init() async {
  debugPrint('🚀 PushNotificationService.init()');

  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  debugPrint('✅ Background handler registered');

  await _requestPermissionAndSaveToken();

  await _initializeLocalNotifications();

  debugPrint('✅ Local notifications initialized');

  FirebaseMessaging.instance
      .getInitialMessage()
      .then((message) {
    debugPrint(
      '📨 getInitialMessage: ${message?.data}',
    );

    if (message != null) {
      _handleNavigation(message.data);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen(
    (message) {
      debugPrint(
        '📲 Notification opened from background: ${message.data}',
      );

      _handleNavigation(message.data);
    },
  );
}

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

  static Future<void>
    _requestPermissionAndSaveToken() async {

  debugPrint(
    '🔔 Requesting notification permission...',
  );

  final messaging =
      FirebaseMessaging.instance;

  final settings =
      await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  debugPrint(
    '🔔 Permission Status: ${settings.authorizationStatus}',
  );

  if (settings.authorizationStatus !=
      AuthorizationStatus.authorized) {

    debugPrint(
      '❌ Notification permission denied',
    );

    return;
  }

  final token =
      await messaging.getToken();

  debugPrint(
    '📲 FCM Token: $token',
  );

  await _saveToken(token);

  FirebaseMessaging.instance
      .onTokenRefresh
      .listen((newToken) async {

    debugPrint(
      '🔄 Token Refreshed',
    );

    debugPrint(
      '📲 New Token: $newToken',
    );

    await _saveToken(
      newToken,
    );
  });
}

  static Future<void> _saveToken(
  String? token,
) async {

  if (token == null) {

    debugPrint(
      '❌ Token is null',
    );

    return;
  }

  final user =
      FirebaseAuth.instance.currentUser;

  if (user == null) {

    debugPrint(
      '❌ User not logged in. Token not saved.',
    );

    return;
  }

  debugPrint(
    '💾 Saving token for ${user.uid}',
  );

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
}

  static Future<void>
    _initializeLocalNotifications() async {

  const android =
      AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const ios =
      DarwinInitializationSettings();

  const settings =
      InitializationSettings(
    android: android,
    iOS: ios,
  );

  await flutterLocalNotificationsPlugin.initialize(
  settings: settings,
    onDidReceiveNotificationResponse:
        (NotificationResponse response) {

      final payload =
          response.payload;

      if (payload == null ||
          payload.isEmpty) {
        return;
      }

      try {

        final data =
            Uri.splitQueryString(
          payload
              .replaceAll('{', '')
              .replaceAll('}', '')
              .replaceAll(' ', '')
              .replaceAll(':', '='),
        );

        _handleNavigation(data);

      } catch (e) {

        debugPrint(
          'Notification payload parse error: $e',
        );
      }
    },
  );

  FirebaseMessaging.onMessage.listen(
    (message) async {

      final notification =
          message.notification;

      if (notification == null) {
        return;
      }

      await flutterLocalNotificationsPlugin
          .show(
        id: notification.hashCode,

        title:
            notification.title,

        body:
            notification.body,

        notificationDetails:
            const NotificationDetails(
          android:
              AndroidNotificationDetails(
            'glowfit_notifications',
            'GlowFit Notifications',

            channelDescription:
                'General app notifications',

            importance:
                Importance.max,

            priority:
                Priority.high,
          ),

          iOS:
              DarwinNotificationDetails(),
        ),

        payload:
            message.data.toString(),
      );
    },
  );
}

  static void _handleNavigation(
  Map<String, dynamic> data,
) async {

  await Future.delayed(
    const Duration(milliseconds: 500),
  );

  final type =
      data['type']?.toString();

  switch (type) {

    case 'reward':

      AppRouter.router.go(
        '/points',
      );
      break;

    case 'order':

      final orderId =
          data['orderId']?.toString();

      if (orderId != null &&
          orderId.isNotEmpty) {

        AppRouter.router.push(
          '/order/$orderId',
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

    default:

      AppRouter.router.go('/');
      break;
  }
}
}