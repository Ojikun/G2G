import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

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
        // Handle notification tap if needed
        if (response.payload != null) {
          print('Notification payload: ${response.payload}');
          // You can navigate to a specific screen if needed
          // Example: Navigator.push(context, MaterialPageRoute(builder: (_) => TargetScreen()));
        }
      },
    );

    // Request notification permissions (for iOS, optional but recommended)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission');
    } else {
      print('User declined or has not accepted notification permission');
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print("✅ FCM Registration Token: $token");

    // TODO: Save the token to Firestore linked to the current user
    // Example:
    // await FirebaseFirestore.instance.collection('users').doc(uid).update({'fcmToken': token});

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Received a foreground message: ${message.messageId}');
      if (message.notification != null) {
        _showLocalNotification(
          title: message.notification!.title ?? 'New Notification',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Handle notification when app is opened by tapping on it
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🖐️ Notification clicked and app opened!');
      // Navigate to a specific screen if needed
    });
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'default_channel_id', // channel id
          'Default Notifications', // channel name
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotificationsPlugin.show(
      0, // Notification ID
      title,
      body,
      notificationDetails,
      payload: 'Default payload', // Optional, pass extra data
    );
  }
}
