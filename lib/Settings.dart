import 'package:flutter/material.dart';

void main() {
  runApp(SettingsApp());
}

class SettingsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  Widget settingsButton(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Row for back button and teal rectangle
              Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios),
                      onPressed: () {},
                    ),
                  ),
                  Text(
                    "G2G",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20), // Space below header row
              settingsButton("ACCOUNT SETTINGS"),
              SizedBox(height: 10),
              settingsButton("PRIVACY SETTINGS"),
              SizedBox(height: 10),
              settingsButton("CHAT SETTINGS"),
              SizedBox(height: 10),
              settingsButton("NOTIFICATION SETTINGS"),
              SizedBox(height: 10),
              settingsButton("TERMS & POLICIES"),
              SizedBox(height: 10),
              settingsButton("HELP CENTER"),
              SizedBox(height: 10),
              settingsButton("ADD ON"),
              SizedBox(height: 10),
              settingsButton("ADD ON"),
              SizedBox(height: 100), // Space before Log Out
              settingsButton("LOG OUT"),
            ],
          ),
        ),
      ),
    );
  }
}
