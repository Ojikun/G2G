import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      home: SplashScreen(), // Set splash screen as home
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      // Navigate to the main screen after 3 seconds
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()), // Replace with your main screen widget
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set background color if needed
      body: Center(
        child: Text(
          'G2G', // Your logo text
          style: TextStyle(
            fontSize: 40, // Adjust the font size
            fontWeight: FontWeight.bold, // Optional for bold
            color: Colors.blue, // Adjust color of text
            letterSpacing: 5, // Optional for letter spacing
          ),
        ),
      ),
    );
  }
}

// Example of the main screen (you can replace it with your actual main screen)
class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('')),
      body: Center(
        child: Text(
          'G2G', // Your logo text
          style: TextStyle(
            fontSize: 50 , // Adjust the font size
            fontWeight: FontWeight.bold, // Optional for bold
            color: Colors.teal, // Adjust color of text
            letterSpacing: 5, // Optional for letter spacing
          ),
        ),
      ),
    );
  }
}
