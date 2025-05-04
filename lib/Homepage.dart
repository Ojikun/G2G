import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

import 'Give.dart';
import 'Get.dart';
import 'Trade.dart';
import 'Basket.dart';
import 'Food.dart';
import 'Welcome.dart';
import 'Header.dart';
import 'services/bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePageContent(),
    GiveFoodPage(),
    GetScreenPage(),
    TradeHomePage(),
    BasketScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show a loading indicator only for the body
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // Show the selected page when the user is authenticated
            return _pages[_selectedIndex];
          } else {
            // Show the WelcomePage if no user is logged in
            return WelcomePage();
          }
        },
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

class HomePageContent extends StatelessWidget {
  Future<String?> fetchProfileImage(String userId) async {
    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (userDoc.exists && userDoc['profileImage'] != null) {
        return userDoc['profileImage'] as String?;
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
    return null; // Return null if no image is found or error occurs
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return Center(child: Text('User not logged in.'));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Header(currentUserId: currentUserId),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Banner
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GiveFoodPage()),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/banner2.png',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SizedBox(height: 25), // Add spacing after the banner
                  // Section 1: Get Now!
                  Container(
                    color:
                        Colors.grey[180], // Background color for this section
                    padding: const EdgeInsets.all(
                      0,
                    ), // Add padding inside the container
                    margin: const EdgeInsets.only(
                      bottom: 16,
                    ), // Add margin between sections
                    child: Section(
                      title: 'Get Now!',
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
                  ),

                  // Section 2: My Donations
                  Container(
                    color:
                        Colors.grey[180], // Background color for this section
                    padding: const EdgeInsets.all(
                      0,
                    ), // Add padding inside the container
                    margin: const EdgeInsets.only(
                      bottom: 16,
                    ), // Add margin between sections
                    child: Section(
                      title: 'My Donations',
                      query: FirebaseFirestore.instance
                          .collection('donations')
                          .where(
                            'userId',
                            isEqualTo: currentUserId,
                          ) // Filter by current user
                          .orderBy(
                            'timestamp',
                            descending: true,
                          ) // Order by timestamp (latest first)
                          .limit(4), // Limit to 4 items
                      onEmptySectionPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => GiveFoodPage()),
                        );
                      },
                      emptySectionMessage: 'Give now!',
                    ),
                  ),

                  // Section 3: Get Again!
                  Container(
                    color:
                        Colors.grey[180], // Background color for this section
                    padding: const EdgeInsets.all(
                      0,
                    ), // Add padding inside the container
                    margin: const EdgeInsets.only(
                      bottom: 16,
                    ), // Add margin between sections
                    child: Section(
                      title: 'Get Again!',
                      query: FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUserId)
                          .collection('gets'),
                      onEmptySectionPressed: null, // No action for empty state
                      emptySectionMessage: 'No items found.',
                      onSeeAllPressed: null, // No "See all" for this section
                      customItemBuilder: (context, doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final foodId = data['foodId'] ?? '';
                        final foodName = data['foodName'] ?? 'No Name';

                        return FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('donations')
                                  .doc(foodId)
                                  .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Container(
                                width: 150,
                                margin: EdgeInsets.only(right: 10),
                                child: Center(child: Text('No Image')),
                              );
                            }

                            final donationData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final imageUrl = donationData['imageUrl'] ?? '';

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => FoodScreen(
                                          foodId: foodId,
                                        ), // Pass foodId
                                  ),
                                );
                              },
                              child: Container(
                                width: 180, // Adjust width to 200
                                margin: EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.0),
                                  border: Border.all(
                                    color: Colors.grey, // Border color
                                    width: 0.5, // Border width
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: Stack(
                                    children: [
                                      // Background image
                                      Positioned.fill(
                                        child:
                                            imageUrl.isNotEmpty
                                                ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                )
                                                : Container(
                                                  color: Color(0xffffc533),
                                                  child: Center(
                                                    child: Icon(
                                                      Icons.fastfood,
                                                      size: 60,
                                                      color: Color(0xffffc533),
                                                    ),
                                                  ),
                                                ),
                                      ),

                                      // Solid background with text in the bottom-left corner
                                      Positioned(
                                        left: 0,
                                        bottom: 0,
                                        child: Container(
                                          color: Colors.grey.withOpacity(
                                            0.6,
                                          ), // Solid background with opacity
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          width:
                                              200, // Match the width of the image
                                          child: Text(
                                            foodName,
                                            style: TextStyle(
                                              color:
                                                  Colors
                                                      .white, // White text for contrast
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  14, // Adjust font size as needed
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
  final Widget Function(BuildContext, QueryDocumentSnapshot)? customItemBuilder;

  Section({
    required this.title,
    required this.query,
    this.onSeeAllPressed,
    this.onEmptySectionPressed,
    required this.emptySectionMessage,
    this.customItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
                child: Text(
                  'See all',
                  style: TextStyle(color: Color(0xff140f1f)),
                ),
              ),
          ],
        ),

        // Remove or reduce unnecessary spacing
        SizedBox(height: 10), // Adjust this value or remove it
        // Firestore Horizontal List
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
                    // border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(16.0),
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

            return SizedBox(
              height: 150, // Adjust height as needed
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: docs.length + 1, // Add 1 for the arrow
                itemBuilder: (context, index) {
                  if (index == docs.length) {
                    // Arrow at the end
                    return GestureDetector(
                      onTap: onSeeAllPressed,
                      child: Container(
                        width: 50,
                        alignment: Alignment.center,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xffffc533),
                          ),
                          onPressed:
                              onSeeAllPressed, // Trigger the same action as the GestureDetector
                        ),
                      ),
                    );
                  }
                  final doc = docs[index];

                  // Use customItemBuilder if provided, otherwise fallback to default
                  if (customItemBuilder != null) {
                    return customItemBuilder!(context, doc);
                  }

                  // Default item builder
                  final data = doc.data() as Map<String, dynamic>;
                  final foodName = data['name'] ?? 'No Name';
                  final imageUrl = data['imageUrl'] ?? '';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FoodScreen(foodId: doc.id),
                        ),
                      );
                    },
                    child: Container(
                      width: 180, // Adjust width to 200
                      margin: EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: Colors.grey, // Border color
                          width: 0.5, // Border width
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Stack(
                          children: [
                            // Background image
                            Positioned.fill(
                              child:
                                  imageUrl.isNotEmpty
                                      ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                      )
                                      : Container(
                                        color: Colors.teal[100],
                                        child: Center(
                                          child: Icon(
                                            Icons.fastfood,
                                            size: 60,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                            ),

                            // Solid background with text in the bottom-left corner
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: Container(
                                color: Colors.grey.withOpacity(
                                  0.6,
                                ), // Solid background with opacity
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                width: 200, // Match the width of the image
                                child: Text(
                                  foodName,
                                  style: TextStyle(
                                    color:
                                        Colors.white, // White text for contrast
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14, // Adjust font size as needed
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
