import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'quota_utils.dart'; // Contains getRemainingWeeklyQuantity() and kWeeklyLimit

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
  if (context.mounted) {
    confirmed = await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/Get.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "Confirm Food Items",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xffffc533),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...items.map(
                    (item) => Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              item.imageUrl.isNotEmpty
                                  ? Image.network(
                                    item.imageUrl,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                  : Icon(
                                    Icons.fastfood,
                                    size: 40,
                                    color: Colors.teal,
                                  ),
                        ),
                        title: Text(
                          item.foodName,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Quantity: ${item.quantity}",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            actions: [
              TextButton.icon(
                label: Text("Cancel", style: TextStyle(color: Colors.black)),
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffffc533),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Text("Claim", style: TextStyle(color: Colors.black)),
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ],
          ),
    );
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
  final bottomOffset =
      105.0 + (activeOverlayCount * 100); // Stack overlays 90px apart.
  activeOverlayCount++; // Increment overlay count.

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

  entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        left: 16,
        right: 16,
        bottom: bottomOffset, // Dynamic bottom offset based on active overlays.
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(20),
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
                  padding: EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child:
                      isExpanded
                          ? Row(
                            children: [
                              // Left side: Food info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "🎉 You got ${items.map((item) => item.quantity).join(", ")} ${items.map((item) => item.foodName).join(", ")}!",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "📍 Get at $location",
                                      style: TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12),
                              // Right side: Timer and Done button
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "⏳ $minutes:$seconds",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xffffc533),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await updateQuantitiesInFirestore();
                                      removeOverlay();
                                    },
                                    icon: Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xffffc533),
                                    ),
                                    label: Text(
                                      "Done",
                                      style: TextStyle(
                                        color: Color(0xffffc533),
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
                              Text(
                                "📍 $location",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Icon(Icons.expand_more, color: Color(0xffffc533)),
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
