import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import 'Splash.dart';
import 'Homepage.dart';
import 'Give.dart';
import 'Get.dart';
import 'Trade.dart';
import 'Basket.dart';
import 'Notif.dart';

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
      navigatorKey: navigatorKey, // Set the global navigator key
      title: 'G2G (Get what you need, give what you can)',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white, // Set background color to white
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // '/': (context) => SplashScreen(),
        '/': (context) => HomeScreen(),
        '/give': (context) => GiveFoodPage(),
        '/get': (context) => GetScreenPage(),
        '/trade': (context) => TradeHomePage(),
        '/basket': (context) => BasketScreen(),
      },
      builder: (context, child) {
        NotificationService.initialize(context); // Initialize notifications
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
    // Android initialization
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap when app is in the foreground
        if (response.payload != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const NotifPage(), // Navigate to NotifPage
            ),
          );
        }
      },
    );

    // Handle FCM foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showNotification(message.notification!, message.data);
      }
    });

    // Handle notification tap when app is opened from background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const NotifPage(), // Navigate to NotifPage
        ),
      );
    });

    // Request permission (important for iOS)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get and save FCM token
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
    await saveTokenToDatabase(token);
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

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      notificationDetails,
      payload: '${data['tradePostId']}|${data['requestId']}', // Pass data
    );
  }

  static Future<void> saveTokenToDatabase(String? token) async {
    if (token != null) {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'fcmToken': token});
      }
    }
  }
}
