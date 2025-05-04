import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore

import 'EditProfile.dart';
import 'Login.dart';
import 'History.dart';
import 'Food.dart';
import 'widgets/full_screen_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? user;
  String fullName = '';
  String email = '';
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    if (user != null) {
      setState(() {
        email = user!.email ?? '';
      });

      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get();

        if (userDoc.exists) {
          setState(() {
            fullName = userDoc['name'] ?? '';
            profileImageUrl =
                userDoc['profileImage']; // <-- fetch profile image
          });
        } else {
          fullName = '';
          profileImageUrl = null;
        }
      } catch (e) {
        print('Error fetching user details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: Image.asset(
          'assets/logo.png',
          width: 80,
          height: 50,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ), // Changed to logout icon
            onPressed: () async {
              // Logout Firebase session
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ), // Navigate to LoginScreen
                (route) => false, // Remove all previous routes
              );
            },
          ),
        ],
        elevation: 0, // Optional: Remove shadow for a flat look
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Profile Image
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              FullScreenImageView(imageUrl: profileImageUrl!),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No profile image available')),
                  );
                }
              },
              child: CircleAvatar(
                radius: 45,
                backgroundImage:
                    profileImageUrl != null
                        ? NetworkImage(profileImageUrl!)
                        : null,
                backgroundColor: Color(0xffffc533),
                child:
                    profileImageUrl == null
                        ? Icon(Icons.person, color: Colors.white)
                        : null,
              ),
            ),

            const SizedBox(height: 10),

            // Display name
            Text(
              fullName.isNotEmpty
                  ? fullName
                  : (email.isNotEmpty ? email : 'Loading...'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            // Email
            if (email.isNotEmpty)
              Text(email, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 10),

            // Edit Profile Button
            ElevatedButton(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );

                if (updated == true) {
                  fetchUserDetails(); // Reload details if profile was updated
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffffc533),
                foregroundColor: Colors.white,
              ),
              child: const Text("EDIT PROFILE"),
            ),

            const SizedBox(height: 20),

            // Main Content
            // Badge Collected Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Badge Collected",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const _InfoCard(
                    showArrow: true,
                    index: 0,
                    isBadge: true,
                    label: 'Fair Trade',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // History Section
            // History Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                // color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "History",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "See All",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffffc533),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Display 4 latest items in cards
                  // Display 4 latest items in cards
                  FutureBuilder<QuerySnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('donations')
                            .where('userId', isEqualTo: user!.uid)
                            .orderBy('timestamp', descending: true)
                            .limit(4)
                            .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No history found.'));
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          final foodId =
                              docs[index].id; // Get the document ID (foodId)
                          final foodName = data['name'] ?? 'No Name';
                          final imageUrl = data['imageUrl'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child:
                                    imageUrl.isNotEmpty
                                        ? Image.network(
                                          imageUrl,
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        )
                                        : Container(
                                          width: 50,
                                          height: 50,
                                          color: Colors.grey[300],
                                          child: const Icon(
                                            Icons.fastfood,
                                            color: Colors.grey,
                                          ),
                                        ),
                              ),
                              title: Text(
                                foodName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                "Donated on: ${data['timestamp']?.toDate().toString().split(' ')[0] ?? 'N/A'}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              onTap: () {
                                // Navigate to FoodScreen with the foodId
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => FoodScreen(foodId: foodId),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
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

class _InfoCard extends StatelessWidget {
  final bool showArrow;
  final int index;
  final bool isBadge;
  final String label;

  const _InfoCard({
    this.showArrow = false,
    required this.index,
    required this.isBadge,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  isBadge
                      ? 'assets/badge${index + 1}.png'
                      : 'assets/food${index + 1}.png',
                ),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (showArrow) const Spacer(),
          if (showArrow)
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
