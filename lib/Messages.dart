import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wireframe List',
      debugShowCheckedModeBanner: false,
      home: WireframeListScreen(),
    );
  }
}

final List<String> personNames = ['Jun', 'Jin', 'Claudio', 'Steve'];
final List<String> foodNames = ['Lucky Me Pancit Canton Extra Hot', 'Argentina Corned Beef', 'Ligo Sardines', 'Nescafe Original'];
final List<String> messages = ['Is this available?', 'Is this available?', 'Is this available?', 'Is this available?'];

class WireframeListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.arrow_back_ios),
        title: Text(
          "G2G",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: ListView.builder(
        itemCount: 4,
        padding: EdgeInsets.all(12),
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Profile Row
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[300],
                            child: Icon(Icons.person, size: 18, color: Colors.grey),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 8),
                      Text(
                        personNames[index],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Main content
                  Row(
                    children: [
                      Image.asset(
                        'assets/food${index + 1}.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              foodNames[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              messages[index],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
