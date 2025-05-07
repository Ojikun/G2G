import 'dart:async';
import 'package:flutter/material.dart';
import 'Homepage.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 10), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🛠 Use Image.asset instead of Icon
            Image.asset(
              'assets/logo.png',
              width: 150, // You can adjust size
              height: 100,
              fit: BoxFit.contain,
            ),
            // const CircularProgressIndicator(color: Colors.teal),
          ],
        ),
      ),
    );
  }
}
