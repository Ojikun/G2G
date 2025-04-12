import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GetScreenPage(),
    );
  }
}

class GetScreenPage extends StatefulWidget {
  @override
  _GetScreenPageState createState() => _GetScreenPageState();
}

class _GetScreenPageState extends State<GetScreenPage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget coloredIcon(String assetPath, bool isSelected, double width, double height) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected ? Colors.teal : Colors.black,
        BlendMode.srcIn,
      ),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[300],
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.black,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Home.png', _selectedIndex == 0, 25, 25),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Give.png', _selectedIndex == 1, 40, 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Get.png', _selectedIndex == 2, 40, 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Trade.png', _selectedIndex == 3, 40, 40),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: coloredIcon('assets/Bag.png', _selectedIndex == 4, 30, 30),
            label: '',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.person),
                SizedBox(width: 42),
                Text(
                  "G2G",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(width: 40),
                Icon(Icons.mail),
              ],
            ),

            SizedBox(height: 20),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.tune),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Grid View - Main Body Content
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: 8, // Based on wireframe
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/food${index + 1}.png', // Assuming you have images named 'item1.png', 'item2.png', etc.
                        width: 150,
                        height: 150,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
