import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../TradeRequestDetail.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null) {
          final payload = json.decode(response.payload!);
          handleNotificationTap(context, payload);
        }
      },
    );

    // Request notification permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('Notification authorization status: ${settings.authorizationStatus}');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Received foreground message: ${message.messageId}');
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
          payload: message.data,
        );
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔥 App opened from background notification');
      handleNotificationTap(context, message.data);
    });

    // Get and save FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      print('✅ FCM Token: ${token.substring(0, 10)}...');
      await _saveFCMToken(token);
    }
  }

  static Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'fcmToken': token});
        print('✅ FCM token saved to Firestore');
      }
    } catch (e) {
      print('❌ Error saving FCM token: $e');
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'default_channel_id',
            'Default Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: payload != null ? json.encode(payload) : null,
      );
    } catch (e) {
      print('❌ Error showing local notification: $e');
    }
  }

  static void handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> payload,
  ) {
    try {
      final String type = payload['type'] ?? '';

      switch (type) {
        case 'trade_request':
          final String? postId = payload['tradePostId'];
          final String? requestId = payload['requestId'];
          if (postId != null && requestId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => TradeRequestDetailPage(
                      postId: postId,
                      requestId: requestId,
                    ),
              ),
            );
          }
          break;

        case 'chat_message':
          // Handle chat message navigation
          break;

        default:
          print('⚠️ Unknown notification type: $type');
      }
    } catch (e) {
      print('❌ Error handling notification tap: $e');
    }
  }
}
