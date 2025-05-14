import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'History.dart';
import 'Give.dart';
import 'Get.dart';
import 'Trade.dart';
import 'Basket.dart';
import 'Food.dart';
import 'ChatList.dart';
import 'Notif.dart';
import 'Profile.dart';
import 'Welcome.dart';
import 'services/bottom_nav_bar.dart';
import 'services/badge_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _checkBadges();
  }

  Future<void> _checkBadges() async {
    if (currentUserId != null && mounted) {
      await BadgeService.checkAndAwardBadges(context, currentUserId!);
    }
  }

  final List<Widget> _pages = [
    HomePageContent(),
    BasketScreen(),
    ChatListScreen(),
    NotifPage(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      Future.microtask(() {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => WelcomePage()),
          (route) => false,
        );
      });
      return const SizedBox(); // Return an empty widget while redirecting
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          IndexedStack(index: _selectedIndex, children: _pages),

          // Floating navigation bar
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: BottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
            ),
          ),
        ],
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

  Future<void> _handleAction(BuildContext context, String userId) async {
    try {
      await BadgeService.checkAndAwardBadges(context, userId);
    } catch (e) {
      print('Error checking badges: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('User not logged in.'));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Logo (Header)
            SizedBox(
              height: 50,
              child: Center(
                child: Image.asset(
                  'assets/logo.png',
                  width: 80,
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 20), // Add spacing after the logo
            // Banner
            GestureDetector(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/banner.png',
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 20), // Add spacing after the banner
            // Row of Button Icons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Give Button
                _buildIconButton(
                  context,
                  'assets/give.png',
                  'Give',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GiveFoodPage()),
                  ),
                ),

                // Get Button
                _buildIconButton(
                  context,
                  'assets/get.png',
                  'Get',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GetScreenPage()),
                  ),
                ),

                // Trade Button
                _buildIconButton(
                  context,
                  'assets/trade.png',
                  'Trade',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TradeHomePage()),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25), // Add spacing after the row of buttons
            // Section 1: Available
            _buildSection(
              context,
              title: 'Available',
              query: FirebaseFirestore.instance
                  .collection('donations')
                  .where('status', isEqualTo: 'available')
                  .where('userId', isNotEqualTo: currentUserId)
                  .limit(4),
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GetScreenPage()),
                );
              },
              emptySectionMessage: 'No available donations.',
            ),

            // Section 2: My Donations
            _buildSection(
              context,
              title: 'My Donations',
              query: FirebaseFirestore.instance
                  .collection('donations')
                  .where('userId', isEqualTo: currentUserId)
                  .orderBy('timestamp', descending: true)
                  .limit(4),
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(userId: currentUserId),
                  ),
                );
              },
              emptySectionMessage: 'Give now and earn a badge!',
            ),

            // Section 3: Get Again!
            _buildSection(
              context,
              title: 'Get Again!',
              query: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .collection('gets')
                  .orderBy('timestamp', descending: true)
                  .limit(5),
              onSeeAllPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(userId: currentUserId),
                  ),
                );
              },
              emptySectionMessage: 'No items found.',
              customItemBuilder: (context, doc) {
                final data = doc.data() as Map<String, dynamic>;

                if (data['foodId'] == null) {
                  return const SizedBox(); // Skip if no foodId
                }

                return FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('donations')
                          .doc(data['foodId'])
                          .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingCard();
                    }

                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return _buildErrorCard();
                    }

                    final donationData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    final foodName = donationData['name'] ?? 'No Name';
                    final imageUrl = donationData['imageUrl'] ?? '';

                    return _buildFoodCard(
                      context: context,
                      foodId: data['foodId'],
                      foodName: foodName,
                      imageUrl: imageUrl,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80), // Add spacing at the bottom
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff238855)),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.grey, width: 0.5),
      ),
      child: const Center(
        child: Icon(Icons.error_outline, color: Colors.grey, size: 32),
      ),
    );
  }

  Widget _buildFoodCard({
    required BuildContext context,
    required String foodId,
    required String foodName,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FoodScreen(foodId: foodId)),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey, width: 0.5),
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[100],
                              child: const Icon(
                                Icons.fastfood,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                        : Container(
                          color: Colors.grey[100],
                          child: const Icon(
                            Icons.fastfood,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
              ),
              // Gradient overlay with food name
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      foodName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    String assetPath,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () async {
        onTap();
        if (FirebaseAuth.instance.currentUser?.uid != null) {
          await _handleAction(context, FirebaseAuth.instance.currentUser!.uid);
        }
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              assetPath,
              height: 60,
              width: 60,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Query query,
    required VoidCallback onSeeAllPressed,
    required String emptySectionMessage,
    Widget Function(BuildContext, QueryDocumentSnapshot)? customItemBuilder,
  }) {
    return Container(
      color: Colors.grey[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Section(
        title: title,
        query: query,
        onSeeAllPressed: onSeeAllPressed,
        emptySectionMessage: emptySectionMessage,
        customItemBuilder: customItemBuilder,
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (onSeeAllPressed != null)
              GestureDetector(
                onTap: onSeeAllPressed,
                child: Text(
                  'See all',
                  style: TextStyle(
                    color: const Color(0xff238855),
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10), // Adjust spacing
        // Firestore Horizontal List
        StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xff238855)),
              );
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return GestureDetector(
                onTap: onEmptySectionPressed,
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Center(
                    child: Text(
                      emptySectionMessage,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
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
                itemCount: docs.length,
                itemBuilder: (context, index) {
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
                      width: 180,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: Colors.grey, width: 0.5),
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
                                        child: const Center(
                                          child: Icon(
                                            Icons.fastfood,
                                            size: 60,
                                            color: Colors.teal,
                                          ),
                                        ),
                                      ),
                            ),
                            // Gradient overlay with food name
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.7),
                                    ],
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Text(
                                    foodName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
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
