import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/BadgeOverlay.dart';

class BadgeService {
  static Future<void> showBadgeOverlay(
    BuildContext context,
    String badgeName,
    String badgeUrl,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => BadgeOverlay(badgeName: badgeName, badgeUrl: badgeUrl),
    );
    // Add delay between badges
    await Future.delayed(const Duration(milliseconds: 500));
  }

  static Future<void> checkAndAwardBadges(
    BuildContext context,
    String userId,
  ) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final badgesCollection = userDoc.collection('badges');

    // Fetch counts
    final donationsCount =
        await FirebaseFirestore.instance
            .collection('donations')
            .where('userId', isEqualTo: userId)
            .count()
            .get();

    final getsCount = await userDoc.collection('gets').count().get();

    final tradesCount =
        await FirebaseFirestore.instance
            .collection('trades')
            .where('uid', isEqualTo: userId)
            .where('status', isEqualTo: 'accepted')
            .count()
            .get();

    // Function to process badge
    Future<void> processBadge(
      int index,
      int currentCount,
      int requiredCount,
      String type,
    ) async {
      if (currentCount >= requiredCount) {
        final badgeDoc =
            await FirebaseFirestore.instance
                .collection('badges')
                .where('index', isEqualTo: index)
                .get();

        if (badgeDoc.docs.isNotEmpty) {
          final badgeId = badgeDoc.docs.first.id;
          final badgeData = badgeDoc.docs.first.data();

          // Check if badge already earned
          final existingBadge =
              await badgesCollection.where('badgeId', isEqualTo: badgeId).get();

          if (existingBadge.docs.isEmpty) {
            // Save badge
            await badgesCollection.add({
              'badgeId': badgeId,
              'type': type,
              'count': requiredCount,
              'earnedAt': FieldValue.serverTimestamp(),
            });

            // Show overlay
            if (context.mounted) {
              await showBadgeOverlay(
                context,
                badgeData['badgeName'] ?? 'New Badge',
                badgeData['badgeUrl'] ?? '',
              );
            }
          }
        }
      }
    }

    // Process all badge types
    final badges = [
      (5, donationsCount.count ?? 0, [1, 3, 5, 8, 10], 'donation'),
      (5, getsCount.count ?? 0, [1, 3, 5, 8, 10], 'get'),
      (5, tradesCount.count ?? 0, [1, 3, 5, 8, 10], 'trade'),
    ];

    for (var badge in badges) {
      for (var i = 0; i < badge.$1; i++) {
        await processBadge(
          i + (badges.indexOf(badge) * 5),
          badge.$2,
          badge.$3[i],
          badge.$4,
        );
      }
    }
  }
}

    // Check donations badges
   
