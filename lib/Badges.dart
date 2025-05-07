import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final userDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId);
    final badgesCollection = userDoc.collection('badges');

    // Fetch counts using more efficient count() queries
    final donationsCount =
        await FirebaseFirestore.instance
            .collection('donations')
            .where('userId', isEqualTo: widget.userId)
            .count()
            .get();

    final getsCount = await userDoc.collection('gets').count().get();

    final tradesCount =
        await FirebaseFirestore.instance
            .collection('trades')
            .where('uid', isEqualTo: widget.userId)
            .where('status', isEqualTo: 'accepted')
            .count()
            .get();

    final Map<int, bool> achievements = {};

    // Function to process badge achievement
    Future<void> processBadge(
      int index,
      int currentCount,
      int requiredCount,
      String type,
    ) async {
      if (currentCount >= requiredCount) {
        achievements[index] = true;
        final badgeDoc =
            await FirebaseFirestore.instance
                .collection('badges')
                .where('index', isEqualTo: index)
                .get();

        if (badgeDoc.docs.isNotEmpty) {
          final badgeId = badgeDoc.docs.first.id;
          final existingBadge =
              await badgesCollection.where('badgeId', isEqualTo: badgeId).get();

          if (existingBadge.docs.isEmpty) {
            final badgeData = badgeDoc.docs.first.data();
            await badgesCollection.add({
              'badgeId': badgeId,
              'type': type,
              'count': requiredCount,
              'earnedAt': FieldValue.serverTimestamp(),
            });

            if (mounted && context.mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder:
                    (context) => BadgeOverlay(
                      badgeName: badgeData['badgeName'] ?? 'New Badge',
                      badgeUrl: badgeData['badgeUrl'] ?? '',
                    ),
              );
            }
          }
        }
      }
    }

    // Process all badge types
    final counts = [
      (donationsCount.count ?? 0, 'donation'),
      (getsCount.count ?? 0, 'get'),
      (tradesCount.count ?? 0, 'trade'),
    ];

    for (var count in counts) {
      final thresholds = [1, 3, 5, 8, 10];
      for (var i = 0; i < thresholds.length; i++) {
        await processBadge(
          i + (counts.indexOf(count) * 5),
          count.$1,
          thresholds[i],
          count.$2,
        );
      }
    }

    return achievements;
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
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([badgesFuture, achievementsFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏆 Badge Collection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xff238855),
            ),
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
              color: isEarned ? const Color(0xff238855) : Colors.grey[300],
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Column(
                  children: [
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
                    const SizedBox(height: 16),
                    Text(
                      badge['name'] ?? 'Badge',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff238855),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge['description'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: Colors.amber[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            badge['requirements'] ?? '',
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
