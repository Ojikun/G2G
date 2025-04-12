import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MessagesScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MessagesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.arrow_back_ios),
        title: Center(
          child: Text(
            "G2G",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        actions: [SizedBox(width: 48)], // Keeps title centered
        elevation: 0,
      ),
      body: ListView(
        children: [
          sectionTitle("Today"),
          buildMessageItem(0, "Traded Successfully"), // Passing index and status text
          buildMessageItem(1, "Gave Successfully"),
          buildMessageItem(2, "Waiting for Offer"),
          sectionTitle("Earlier"),
          buildMessageItem(3, "Traded Successfully"),
        ],
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildMessageItem(int index, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage('assets/food${index + 1}.png'), // Load image from assets
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(width: 10),

            Spacer(),
            Text(
              status, // Status text on the right side
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal, // Change color based on status if needed
              ),
            ),
          ],
        ),
      ),
    );
  }
}
