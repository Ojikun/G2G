import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'quota_utils.dart'; // Contains getRemainingWeeklyQuantity() and kWeeklyLimit
import '../Homepage.dart';
import '../main.dart'; // Contains navigatorKey

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

  // Confirmation bottom sheet
  bool confirmed = false;
  if (context.mounted) {
    confirmed =
        await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (ctx) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xff238855),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child:
                                  item.imageUrl.isNotEmpty
                                      ? Image.network(
                                        item.imageUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                      : const Icon(
                                        Icons.fastfood,
                                        size: 40,
                                        color: Color(0xff238855),
                                      ),
                            ),
                            title: Text(
                              item.foodName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
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
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.location,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                        maxLines: null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          label: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.black, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xff238855)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          label: const Text(
                            "Claim",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xfffd8536),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ) ??
        false;
  }

  if (!confirmed) return;

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

  final currentContext = navigatorKey.currentContext;
  if (currentContext != null) {
    for (final group in locationGroups.entries) {
      _showGroupedTimerOverlay(currentContext, group.key, group.value);
    }
  }

  // Navigate to Homepage after showing overlays
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
      (route) => false,
    );
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
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        // blurRadius: 12,
                        // offset: Offset(0, 5),
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
                                      maxLines:
                                          null, // Allow the text to wrap to multiple lines
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
                                      color: Color(0xff238855),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () async {
                                      await updateQuantitiesInFirestore();
                                      removeOverlay();
                                    },
                                    icon: Icon(
                                      Icons.check_circle_outline,
                                      color: Color(0xff238855),
                                    ),
                                    label: Text(
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
                              Text(
                                "📍 $location",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Icon(Icons.expand_more, color: Color(0xff238855)),
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
