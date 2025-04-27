import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Splash.dart'; // starting page (you can change this if needed)
import 'Homepage.dart'; // your homepage
import 'Give.dart';
import 'Get.dart';
import 'Trade.dart';
import 'Basket.dart'; // your basket screen
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const G2GApp());
}

class G2GApp extends StatelessWidget {
  const G2GApp({super.key});

  @override
  Widget build(BuildContext context) {
    NotificationService.initialize(context);
    return MaterialApp(
      title: 'G2G (Get what you need, give what you can)',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Initial route
      routes: {
        '/': (context) => SplashScreen(), // starting screen of your app
        '/home': (context) => HomeScreen(),
        '/give': (context) => GiveFoodPage(),
        '/get': (context) => GetScreenPage(),
        '/trade': (context) => TradeHomePage(), // homepage route
        '/basket': (context) => BasketScreen(), // basket screen route
      },
    );
  }
}
