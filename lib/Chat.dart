import 'package:flutter/material.dart';

void main() => runApp(ChatApp());

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios),
                  SizedBox(width: 8),
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text(
                    "Claudio",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.info_outline),
                ],
              ),
            ),

            // Chat messages
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  chatBubble(isMe: false),
                  chatBubble(isMe: true),
                  chatBubble(isMe: false),
                  chatBubble(isMe: false),
                  chatBubble(isMe: true),
                  chatBubble(isMe: false),
                  chatBubble(isMe: true),
                  chatBubble(isMe: true),
                  chatBubble(isMe: false),
                  chatBubble(isMe: true),
                  chatBubble(isMe: false),
                ],
              ),
            ),

            // Input box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.teal),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Send a message",
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(Icons.send, color: Colors.teal),
                            onPressed: () {
                              // Handle send message
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget chatBubble({required bool isMe}) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe)
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.grey[400],
            child: Icon(Icons.person, size: 16),
          ),
        SizedBox(width: 8),
        Container(
          margin: EdgeInsets.symmetric(vertical: 6),
          padding: EdgeInsets.all(12),
          constraints: BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: isMe ? Colors.grey[600] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "Message bubble",
            style: TextStyle(color: isMe ? Colors.white : Colors.black87),
          ),
        ),
      ],
    );
  }
}
