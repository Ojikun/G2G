import 'package:flutter/material.dart';

class SettingsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: SettingsScreen());
  }
}

class SettingsScreen extends StatelessWidget {
  Widget settingsButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
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
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          "Settings",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xffffc533),
        elevation: 0, // Remove shadow for a flat look
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20), // Space below the AppBar
              settingsButton("ACCOUNT SETTINGS", () {
                // Add functionality for Account Settings
              }),
              settingsButton("PRIVACY SETTINGS", () {
                // Add functionality for Privacy Settings
              }),
              settingsButton("CHAT SETTINGS", () {
                // Add functionality for Chat Settings
              }),
              settingsButton("NOTIFICATION SETTINGS", () {
                // Add functionality for Notification Settings
              }),
              settingsButton("TERMS & POLICIES", () {
                // Add functionality for Terms & Policies
              }),
              settingsButton("HELP CENTER", () {
                // Add functionality for Help Center
              }),
              settingsButton("ADD ON", () {
                // Add functionality for Add On
              }),
              const Spacer(), // Push the Log Out button to the bottom
              settingsButton("LOG OUT", () {
                // Add functionality for Log Out
              }),
            ],
          ),
        ),
      ),
    );
  }
}
