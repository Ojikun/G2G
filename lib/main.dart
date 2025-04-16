import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'Splash.dart'; // starting page (you can change this if needed)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const G2GApp());
}

class G2GApp extends StatelessWidget {
  const G2GApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'G2G (Get what you need, give what you can)',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // starting screen of your app
    );
  }
}
