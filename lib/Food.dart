import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Mockup',
      debugShowCheckedModeBanner: false,
      home: FoodScreen(),
    );
  }
}

class FoodScreen extends StatelessWidget {
  final List<String> foodImages = [
    'assets/food1.png', // food1.png
    'assets/food2.png', // food2.png
    'assets/food3.png', // food3.png
  ];

  final List<String> foodLabels = [
    'Lucky Me Pancit Canton Extra Hot', // Food label for the first item
    'Argentina Corned Beef', // Food label for the second item
    'Ligo Sardines', // Food label for the third item
  ];

  final List<String> personNames = [
    'Jun', // Name for the first item
    'Jin', // Name for the second item
    'Claudio', // Name for the third item
  ];

  final List<String> expiryDates = [
    '12/23/2026', // Expiry date for the first item
    '04/12/2025', // Expiry date for the second item
    '06/21/2028', // Expiry date for the third item
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.arrow_back_ios),
                  SizedBox(width: 130),
                  Text(
                    "G2G",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  Spacer(),
                ],
              ),
            ),

            // Dynamic List of Cards
            Expanded(
              child: ListView.builder(
                itemCount: foodImages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Profile Icon instead of CircleAvatar
                              Icon(
                                Icons.account_circle, // Profile icon
                                size: 40, // Adjust the size of the icon
                                color: Colors.grey, // Adjust the color of the icon
                              ),
                              SizedBox(width: 8),
                              // Display person name next to the icon
                              Text(
                                personNames[index], // Display person name based on index
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            children: [
                              Image.asset(
                                foodImages[index], // Use the dynamic image path
                                height: 80,
                                width: 80,
                                fit: BoxFit.cover,
                              ),
                              SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    foodLabels[index], // Display food label based on index
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // Add expiry date below the food label
                                  Text(
                                    'Expiry: ${expiryDates[index]}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 50), // Adjust vertical padding here
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('ADD TO BASKET'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      side: BorderSide(color: Colors.teal),
                    ),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('GET'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
