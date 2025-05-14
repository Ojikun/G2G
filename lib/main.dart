import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Homepage.dart';
import 'Give.dart';
import 'Get.dart';
import 'Trade.dart';
import 'Basket.dart';
import 'Notif.dart';
import 'ChatList.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const G2GApp());
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class G2GApp extends StatelessWidget {
  const G2GApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'G2G (Get what you need, give what you can)',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/give': (context) => GiveFoodPage(),
        '/get': (context) => GetScreenPage(),
        '/trade': (context) => TradeHomePage(),
        '/basket': (context) => BasketScreen(),
      },
      builder: (context, child) {
        NotificationService.initialize(context);
        return child!;
      },
    );
  }
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize(BuildContext context) async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    // Initialize local notifications
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = json.decode(response.payload!);
            _handleNotificationTap(data);
          } catch (e) {
            print('DEBUG: Error parsing notification payload: $e');
          }
        }
      },
    );

    // Handle FCM foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message.notification!, message.data);
      }
    });

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('DEBUG: Background notification tapped: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // Request notification permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save FCM token
    String? token = await _firebaseMessaging.getToken();
    print('DEBUG: FCM Token: $token');
    await saveTokenToDatabase(token);
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    final notificationType = data['type'];
    print('DEBUG: Handling notification tap for type: $notificationType');

    switch (notificationType) {
      case 'chat_message':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const ChatListScreen()),
        );
        break;

      case 'trade_request':
      case 'trade_accepted':
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (context) => const NotifPage()),
        );
        break;

      default:
        print('DEBUG: Unknown notification type: $notificationType');
        break;
    }
  }

  static Future<void> _showNotification(
    RemoteNotification notification,
    Map<String, dynamic> data,
  ) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'trade_channel_id',
          'Trade Notifications',
          channelDescription: 'Channel for trade request notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    await _saveNotificationToFirestore(data);

    // Include all necessary data in payload
    final payload = json.encode({
      'type': data['type'] ?? 'unknown',
      'tradePostId': data['tradePostId'],
      'requestId': data['requestId'],
      'chatId': data['chatId'],
      'senderId': data['senderId'],
      'senderName': data['senderName'],
    });

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      notificationDetails,
      payload: payload,
    );
  }

  static Future<void> _saveNotificationToFirestore(
    Map<String, dynamic> data,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final notificationData = {
        'type': data['type'],
        'title': data['type'] == 'chat_message' ? 'New Message' : data['title'],
        'body':
            data['type'] == 'chat_message'
                ? '${data['senderName']}: ${data['messageText']}'
                : data['body'],
        'senderId': data['senderId'],
        'senderName': data['senderName'],
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'tradePostId': data['tradePostId'],
        'requestId': data['requestId'],
        'chatId': data['chatId'],
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add(notificationData);

      print('DEBUG: Notification saved to Firestore');
    } catch (e) {
      print('DEBUG: Error saving notification: $e');
    }
  }

  static Future<void> saveTokenToDatabase(String? token) async {
    if (token != null) {
      try {
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .update({'fcmToken': token});
          print('DEBUG: FCM token saved to database');
        }
      } catch (e) {
        print('DEBUG: Error saving FCM token: $e');
      }
    }
  }
}
