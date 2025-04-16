import 'package:flutter/material.dart';
import 'Give.dart';
import 'Get.dart';
import 'Trade.dart';
import 'Basket.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget coloredIcon(
    String assetPath,
    bool isSelected,
    double width,
    double height,
  ) {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        isSelected ? Colors.teal : Colors.black,
        BlendMode.srcIn,
      ),
      child: Image.asset(assetPath, width: width, height: height),
    );
  }

  // ✅ List of pages for navigation
  final List<Widget> _pages = [
    HomePageContent(),
    GiveFoodPage(),
    GetScreenPage(),
    TradeHomePage(),
    BasketScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
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
    );
  }
}

// ✅ This is the home page layout as a separate widget
class HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
            child: Row(
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
                SizedBox(width: 10),
                Row(
                  children: [
                    Icon(Icons.mail),
                    SizedBox(width: 10),
                    Icon(Icons.notifications),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          Section(title: 'Give again', itemCount: 2),
          Section(title: 'Get again', itemCount: 2),
          Section(title: 'Near Me', itemCount: 2),
        ],
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final int itemCount;

  Section({required this.title, this.itemCount = 2});

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = itemCount == 1 ? 1 : 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text('See all', style: TextStyle(color: Colors.teal)),
            ],
          ),
          SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.2,
            ),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/food${index + 1}.png',
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
    );
  }
}
