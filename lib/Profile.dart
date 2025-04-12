import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: ProfileScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back and settings icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(Icons.arrow_back_ios),
                    ),
                  ),
                  Text(
                    "G2G",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Icon(Icons.settings),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Profile Picture & Name
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text("First Name Last Name"),
            const SizedBox(height: 5),

            // Edit Profile Button
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text("EDIT PROFILE"),
            ),
            const SizedBox(height: 20),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Badge Collected"),
                    const SizedBox(height: 10),
                    _InfoCard(showArrow: true, index: 0, isBadge: true, label: 'Fair Trade'), // Badge item
                    const SizedBox(height: 20),

                    const Text("History"),
                    const SizedBox(height: 10),
                    _InfoCard(index: 1, isBadge: false, label: 'Argentina Corned Beef'), // Food item
                    const SizedBox(height: 10),
                    _InfoCard(index: 2, isBadge: false, label: 'Ligo Sardines'), // Food item
                  ],
                ),
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
  final int index;  // Added index to handle dynamic item images
  final bool isBadge; // To distinguish between badge and history item (food)
  final String label; // The label for the item

  const _InfoCard({this.showArrow = false, required this.index, required this.isBadge, required this.label});

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
          // Image - Dynamically loaded based on index and whether it's a badge or history item
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(isBadge
                    ? 'assets/badge${index + 1}.png'  // Badge images
                    : 'assets/food${index + 1}.png'), // Food images
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 10),

          // Label for the item (badge or food)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The label text for the item
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Spacer to push the arrow icon to the right
          if (showArrow) const Spacer(),

          // Arrow icon (optional)
          if (showArrow)
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}
