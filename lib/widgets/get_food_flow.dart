import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'quota_utils.dart'; // Contains getRemainingWeeklyQuantity() and kWeeklyLimit
import '../services/badge_service.dart'; // Contains BadgeService class

class GetFoodItem {
  final String foodId;
  final String foodName;
  final String location;
  final int quantity;
  final String imageUrl;

  GetFoodItem({
    required this.foodId,
    required this.foodName,
    required this.location,
    required this.quantity,
    required this.imageUrl,
  });
}

void showGetBasketFlow({
  required BuildContext context,
  required List<GetFoodItem> items,
}) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  // Weekly quota check
  int remainingThisWeek = await getRemainingWeeklyQuantity();
  int totalRequested = items.fold(0, (sum, item) => sum + item.quantity);

  if (totalRequested > remainingThisWeek) {
    if (context.mounted) {
      // Check if the context is still valid
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "You only have $remainingThisWeek item(s) left this week.",
          ),
        ),
      );
    }
    return;
  }

  // Confirmation dialog
  bool confirmed = false;
  // Replace the confirmation dialog section with this:
  if (context.mounted) {
    confirmed =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder:
              (ctx) => SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    MediaQuery.of(ctx).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  'assets/get.png',
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Confirm Food Items",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff238855),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Items List
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                items
                                    .map(
                                      (item) => Card(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 3,
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        child: ListTile(
                                          leading: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child:
                                                item.imageUrl.isNotEmpty
                                                    ? Image.network(
                                                      item.imageUrl,
                                                      width: 50,
                                                      height: 50,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          width: 50,
                                                          height: 50,
                                                          color: const Color(
                                                            0xfffd8536,
                                                          ),
                                                          child: const Icon(
                                                            Icons.fastfood,
                                                            size: 30,
                                                            color: Colors.white,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                    : Container(
                                                      width: 50,
                                                      height: 50,
                                                      color: const Color(
                                                        0xfffd8536,
                                                      ),
                                                      child: const Icon(
                                                        Icons.fastfood,
                                                        size: 30,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                          ),
                                          title: Text(
                                            item.foodName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Quantity: ${item.quantity}",
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.location_on,
                                                    size: 16,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      item.location,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          isThreeLine: true,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Color(0xff238855)),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                "Cancel",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xfffd8536),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: Text(
                                "Claim",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        ) ??
        false;
  }

  if (confirmed != true) return;

  // Claim items
  final claimedItems = <GetFoodItem>[];
  for (final item in items) {
    final donationRef = FirebaseFirestore.instance
        .collection('donations')
        .doc(item.foodId);
    final doc = await donationRef.get();
    int currentQuantity = doc.data()?['quantity'] ?? 0;

    if (item.quantity > currentQuantity) {
      if (context.mounted) {
        // Ensure context is still valid
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Not enough stock for ${item.foodName}.")),
        );
      }
      continue;
    }

    // Add to user's gets
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('gets')
        .add({
          'foodId': item.foodId,
          'foodName': item.foodName,
          'quantity': item.quantity,
          'location': item.location,
          'timestamp': Timestamp.now(),
        });

    claimedItems.add(item);

    // Remove the item from the basket
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('basket')
        .doc(item.foodId)
        .delete();
  }

  if (claimedItems.isEmpty) return;

  // Group by location
  final Map<String, List<GetFoodItem>> locationGroups = {};
  for (final item in claimedItems) {
    locationGroups.putIfAbsent(item.location, () => []).add(item);
  }

  for (final group in locationGroups.entries) {
    _showGroupedTimerOverlay(context, group.key, group.value);
  }
}

int activeOverlayCount = 0; // Keeps track of how many overlays are active.

void _showGroupedTimerOverlay(
  BuildContext context,
  String location,
  List<GetFoodItem> items,
) {
  final screenHeight = MediaQuery.of(context).size.height;
  final bottomSafeArea = MediaQuery.of(context).padding.bottom;
  final maxOverlaySpace = screenHeight * 1;

  final spacing =
      activeOverlayCount > 1
          ? (maxOverlaySpace / activeOverlayCount).clamp(120, 160.0)
          : 120.0; // Adjust spacing based on active overlays

  final bottomOffset = 100 + bottomSafeArea + (activeOverlayCount * spacing);
  activeOverlayCount++;

  final Duration oneHour = Duration(hours: 1);
  final DateTime endTime = DateTime.now().add(oneHour);
  Timer? timer;
  late OverlayEntry entry;

  bool isExpanded = true; // Track whether the overlay is expanded or collapsed

  void removeOverlay() {
    timer?.cancel();
    entry.remove();
    activeOverlayCount--; // Decrement overlay count when an overlay is removed.
  }

  Future<void> updateQuantitiesInFirestore() async {
    final firestore = FirebaseFirestore.instance;

    for (var item in items) {
      final docRef = firestore.collection('donations').doc(item.foodId);

      // Get the current quantity
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        final currentQuantity = snapshot.data()?['quantity'] ?? 0;

        final newQuantity = currentQuantity - item.quantity;

        if (newQuantity <= 0) {
          // Optionally delete or set to 0 — here, we'll just set to 0.
          await docRef.update({'quantity': 0, 'status': 'unavailable'});
        } else {
          await docRef.update({'quantity': newQuantity});
        }
      }
    }
  }

  Future<void> handleDonePressed() async {
    try {
      await updateQuantitiesInFirestore();

      // Check and award badges
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null && context.mounted) {
        // Get user's current badge counts
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId);
        final getsCount = await userDoc.collection('gets').count().get();

        // Check for badge achievements
        if ([1, 3, 5, 8, 10].contains(getsCount.count)) {
          final badgeDoc =
              await FirebaseFirestore.instance
                  .collection('badges')
                  .where('type', isEqualTo: 'get')
                  .where('count', isEqualTo: getsCount.count)
                  .get();

          if (badgeDoc.docs.isNotEmpty) {
            final badgeData = badgeDoc.docs.first.data();

            // Show badge overlay
            if (context.mounted) {
              await BadgeService.showBadgeOverlay(
                context,
                badgeData['badgeName'] ?? 'New Badge',
                badgeData['badgeUrl'] ?? '',
              );
            }
          }
        }
      }

      removeOverlay();
    } catch (e) {
      print('Error handling done: $e');
    }
  }

  entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: bottomOffset, // Dynamic bottom offset based on active overlays.
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          child: StatefulBuilder(
            builder: (context, setState) {
              if (timer == null || !timer!.isActive) {
                timer = Timer.periodic(Duration(seconds: 1), (_) {
                  final remaining = endTime.difference(DateTime.now());
                  if (remaining.isNegative) {
                    removeOverlay();
                  } else {
                    setState(() {});
                  }
                });
              }

              final remaining = endTime.difference(DateTime.now());
              final minutes = remaining.inMinutes
                  .remainder(60)
                  .toString()
                  .padLeft(2, '0');
              final seconds = remaining.inSeconds
                  .remainder(60)
                  .toString()
                  .padLeft(2, '0');

              return GestureDetector(
                onTap: () {
                  // Toggle between expanded and collapsed states
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      isExpanded
                          ? Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "🎉 You got ${items.map((item) => item.quantity).join(", ")} ${items.map((item) => item.foodName).join(", ")}!",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "📍 Get at $location",
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "⏳ $minutes:$seconds",
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff238855),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await updateQuantitiesInFirestore();
                                      removeOverlay();
                                      handleDonePressed();
                                    },
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xff238855),
                                    ),
                                    label: const Text(
                                      "Done",
                                      style: TextStyle(
                                        color: Color(0xff238855),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                          : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "📍 Get at $location",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                              const Icon(
                                Icons.expand_more,
                                color: Color(0xff238855),
                              ),
                            ],
                          ),
                ),
              );
            },
          ),
        ),
      );
    },
  );

  Overlay.of(context, rootOverlay: true).insert(entry);
}
