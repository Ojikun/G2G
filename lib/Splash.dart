import 'dart:async';
import 'package:flutter/material.dart';
import 'Welcome.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => WelcomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[700],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fastfood, color: Colors.white, size: 100),
            const SizedBox(height: 20),
            Text(
              'G2G', // Logo text
              style: TextStyle(
                fontSize: 50, // Big text
                fontWeight: FontWeight.bold, // Bold
                color: Colors.white, // White text on teal background
                letterSpacing: 5, // Spaced letters
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '(Get what you need, give what you can)',
              style: TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

// Example of the main screen (you can replace it with your actual main screen)
// class MainScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('')),
//       body: Center(
//         child: Text(
//           'G2G', // Your logo text
//           style: TextStyle(
//             fontSize: 50, // Adjust the font size
//             fontWeight: FontWeight.bold, // Optional for bold
//             color: Colors.teal, // Adjust color of text
//             letterSpacing: 5, // Optional for letter spacing
//           ),
//         ),
//       ),
//     );
//   }
// }
