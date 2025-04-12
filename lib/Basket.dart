import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BasketScreen(),
    );
  }
}

class BasketScreen extends StatefulWidget {
  @override
  _BasketScreenState createState() => _BasketScreenState();
}

class _BasketScreenState extends State<BasketScreen> {
  List<bool> isChecked = [true, true, true, false];
  List<String> itemNames = [
    "Lucky Me Pancit Canton Extra Hot",
    "Argentina Corned Beef",
    "Ligo Sardines",
    "Nescafe Original"
  ];

  int get checkedCount => isChecked.where((item) => item).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button and center box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.arrow_back_ios),
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
            ),

            // "My Basket" row
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.shopping_bag),
                  SizedBox(width: 10),
                  Text(
                    "My Basket",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Basket items
            Expanded(
              child: ListView.builder(
                itemCount: 4,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final itemChecked = isChecked[index];
                  final canToggle = itemChecked || checkedCount < 3;

                  // Styling based on whether it's disabled or not
                  final containerColor = canToggle
                      ? Colors.grey[200]
                      : Colors.grey[400];

                  final imageColor = canToggle
                      ? Colors.grey[300]
                      : Colors.black45;

                  final barColor = Colors.grey[canToggle ? 400 : 600];

                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Checkbox(
                          value: itemChecked,
                          onChanged: canToggle
                              ? (value) {
                            setState(() {
                              isChecked[index] = value!;
                            });
                          }
                              : null,
                          activeColor: Colors.green,
                          checkColor: Colors.white,
                        ),
                        // Displaying the PNG image
                        Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/food${index + 1}.png'), // Replace with your image assets
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Replacing the yellow rectangle with the item name
                            Text(
                              itemNames[index],
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500
                              ),
                            ),
                            SizedBox(height: 8),
                            // Adding the bar under the item name
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
            ),

            // GET button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 100,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text("GET"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
