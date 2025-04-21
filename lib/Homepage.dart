import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Give.dart';
import 'Get.dart';
import 'Trade.dart';
import 'Basket.dart';
import 'Food.dart';

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

class HomePageContent extends StatelessWidget {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.person),
                Text(
                  "G2G",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
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

          // Banner
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                'Banner or Announcement',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),

          // Sections
          Section(
            title: 'Available',
            query: FirebaseFirestore.instance
                .collection('donations')
                .where('status', isEqualTo: 'available')
                .where('userId', isNotEqualTo: currentUserId)
                .limit(4),
            onSeeAllPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GetScreenPage()),
              );
            },
            emptySectionMessage: 'No available donations.',
          ),
          Section(
            title: 'My Donations',
            query: FirebaseFirestore.instance
                .collection('donations')
                .where('userId', isEqualTo: currentUserId),
            onEmptySectionPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GiveFoodPage()),
              );
            },
            emptySectionMessage: 'Give now!',
          ),
          Section(
            title: 'Get again',
            query: FirebaseFirestore.instance
                .collection('donations')
                .where('claimedBy', isEqualTo: currentUserId),
            onEmptySectionPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => GetScreenPage()),
              );
            },
            emptySectionMessage: 'Get now!',
          ),
        ],
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final Query query;
  final VoidCallback? onSeeAllPressed;
  final VoidCallback? onEmptySectionPressed;
  final String emptySectionMessage;

  Section({
    required this.title,
    required this.query,
    this.onSeeAllPressed,
    this.onEmptySectionPressed,
    required this.emptySectionMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (onSeeAllPressed != null)
                GestureDetector(
                  onTap: onSeeAllPressed,
                  child: Text('See all', style: TextStyle(color: Colors.teal)),
                ),
            ],
          ),
          SizedBox(height: 10),

          // Firestore Grid
          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return GestureDetector(
                  onTap: onEmptySectionPressed,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: Text(
                        emptySectionMessage,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final docId = docs[index].id;
                  final foodName = data['name'] ?? 'No Name';
                  final imageUrl = data['imageUrl'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FoodScreen(foodId: docId),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          imageUrl.isNotEmpty
                              ? Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                              : Icon(
                                Icons.fastfood,
                                size: 60,
                                color: Colors.teal,
                              ),
                          SizedBox(height: 8),
                          Text(
                            foodName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
