import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/BadgeOverlay.dart';
import 'Homepage.dart';

class BadgesScreen extends StatefulWidget {
  final String userId;
  const BadgesScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  late Future<Map<int, Map<String, String>>> badgesFuture;
  late Future<Map<int, bool>> achievementsFuture;

  @override
  void initState() {
    super.initState();
    badgesFuture = _fetchBadges();
    achievementsFuture = _checkUserAchievements();
  }

  Future<Map<int, Map<String, String>>> _fetchBadges() async {
    final badgesSnapshot =
        await FirebaseFirestore.instance
            .collection('badges')
            .orderBy('index')
            .get();

    final Map<int, Map<String, String>> badges = {};
    for (var doc in badgesSnapshot.docs) {
      final data = doc.data();
      badges[data['index']] = {
        'name': data['badgeName'] ?? 'Badge',
        'badgeUrl': data['badgeUrl'] ?? '',
        'placeholder': data['placeholder'] ?? '',
        'requirements': data['requirements'] ?? '',
        'description': data['description'] ?? '',
      };
    }
    return badges;
  }

  Future<Map<int, bool>> _checkUserAchievements() async {
    final Map<int, bool> achievements = {};

    try {
      // Get user's earned badges from subcollection
      final userBadges =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId)
              .collection('badges')
              .get();

      // Get all badges to check achievements
      final allBadges =
          await FirebaseFirestore.instance
              .collection('badges')
              .orderBy('index')
              .get();

      // Create a set of earned badge IDs for quick lookup
      final earnedBadgeIds =
          userBadges.docs.map((doc) => doc.data()['badgeId'] as String).toSet();

      // Process achievements and show overlay for new badges
      for (var badge in allBadges.docs) {
        final data = badge.data();
        final index = data['index'] as int;
        final isEarned = earnedBadgeIds.contains(badge.id);
        achievements[index] = isEarned;

        // Only show badge overlay for current user
        if (isEarned &&
            widget.userId == FirebaseAuth.instance.currentUser?.uid) {
          try {
            // Check if badge was previously shown
            final badgeRef = FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .collection('badges')
                .where('badgeId', isEqualTo: badge.id)
                .where('shown', isEqualTo: true)
                .limit(1);

            final existingBadge = await badgeRef.get();

            if (existingBadge.docs.isEmpty) {
              // Update badge as shown
              final badgeDocs =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.userId)
                      .collection('badges')
                      .where('badgeId', isEqualTo: badge.id)
                      .limit(1)
                      .get();

              if (badgeDocs.docs.isNotEmpty) {
                await badgeDocs.docs.first.reference.update({'shown': true});

                if (mounted && context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) => BadgeOverlay(
                          badgeName: data['badgeName'] ?? 'New Badge',
                          badgeUrl: data['badgeUrl'] ?? '',
                        ),
                  );
                }
              }
            }
          } catch (e) {
            print('Error updating badge shown status: $e');
            // Continue processing other badges even if one fails
          }
        }
      }

      return achievements;
    } catch (e) {
      print('Error checking achievements: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            }
          },
        ),
        title: const Text(
          'My Badges',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xff238855),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      // Replace the existing FutureBuilder in the build method
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([badgesFuture, achievementsFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Loading badges...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xff238855),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          }

          final badges = snapshot.data![0] as Map<int, Map<String, String>>;
          final achievements = snapshot.data![1] as Map<int, bool>;

          return _buildContent(badges, achievements);
        },
      ),
    );
  }

  Widget _buildContent(
    Map<int, Map<String, String>> badges,
    Map<int, bool> achievements,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          Expanded(child: _buildBadgeGrid(badges, achievements)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity, // Added to fill width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Changed to center
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, color: Color(0xff238855), size: 24),
              SizedBox(width: 8),
              Text(
                'Badge Collection',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff238855),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Collect badges by giving, getting, and trading!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeGrid(
    Map<int, Map<String, String>> badges,
    Map<int, bool> achievements,
  ) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: 15,
      itemBuilder: (context, index) {
        final badge = badges[index];
        if (badge == null) return const SizedBox();

        final isEarned = achievements[index] ?? false;
        return _buildBadgeItem(badge, isEarned);
      },
    );
  }

  Widget _buildBadgeItem(Map<String, String> badge, bool isEarned) {
    return GestureDetector(
      onTap: isEarned ? () => _showBadgeDetails(badge) : null,
      child: _buildBadgeCard(
        name: isEarned ? (badge['name'] ?? 'Badge') : '',
        imageUrl:
            isEarned ? (badge['badgeUrl'] ?? '') : (badge['placeholder'] ?? ''),
        isEarned: isEarned,
        requirements: badge['requirements'] ?? '',
      ),
    );
  }

  void _showBadgeDetails(Map<String, String> badge) {
    showDialog(
      context: context,
      builder: (context) => _buildBadgeDetailsDialog(badge),
    );
  }

  Widget _buildBadgeCard({
    required String name,
    required String imageUrl,
    required bool isEarned,
    required String requirements,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  image: DecorationImage(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                    colorFilter:
                        isEarned
                            ? null
                            : ColorFilter.mode(
                              Colors.grey[300]!,
                              BlendMode.saturation,
                            ),
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              color: isEarned ? const Color(0xfffd8536) : Colors.grey[300],
              child: Text(
                isEarned ? name : 'Locked',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isEarned ? Colors.white : Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeDetailsDialog(Map<String, String> badge) {
    return Dialog(
      backgroundColor: Colors.white, // Set dialog background to white
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Column(
                  children: [
                    // Badge Image
                    Container(
                      height: 120,
                      width: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          badge['badgeUrl'] ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Badge Name
                    Text(
                      badge['name'] ?? 'Badge',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff238855),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Badge Description
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        badge['description'] ?? 'No description available',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Requirements Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            badge['requirements'] ??
                                'No requirements specified',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Close Button
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey[400],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
