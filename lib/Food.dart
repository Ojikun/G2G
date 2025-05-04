import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'Basket.dart';
import 'widgets/get_food_flow.dart';
import 'widgets/quota_utils.dart';
import 'widgets/full_screen_image.dart';

Future<String?> fetchCurrentUserName(String userId) async {
  final doc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (doc.exists) {
    return doc.data()?['name'];
  }
  return null;
}

class FoodScreen extends StatelessWidget {
  final String foodId;

  const FoodScreen({required this.foodId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          'Food Details',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xffffc533),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('basket')
                    .snapshots(),
            builder: (context, snapshot) {
              int basketCount = 0;
              if (snapshot.hasData) {
                basketCount = snapshot.data!.docs.length;
              }

              return Stack(
                children: [
                  IconButton(
                    icon: Image.asset('assets/Bag.png', width: 45, height: 40),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BasketScreen()),
                      );
                    },
                  ),
                  if (basketCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$basketCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('donations')
                .doc(foodId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong.'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Item not found.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final imageUrl = data['imageUrl'] as String? ?? '';
          final name = data['name'] as String? ?? 'No Name';
          final quantityStr = data['quantity']?.toString() ?? '0';
          final quantity = int.tryParse(quantityStr) ?? 0;
          final foodType = data['foodType'] as String? ?? 'Unknown';
          final expiryDate = data['expiry'] as String? ?? 'Unknown';
          final donor = data['username'] as String? ?? 'Anonymous';
          final option = data['option'] as String? ?? 'Pick‑up';
          final location = data['location'] as String? ?? 'N/A';
          final note = data['note'] as String? ?? 'No notes provided.';

          return FutureBuilder<String?>(
            future: fetchCurrentUserName(
              FirebaseAuth.instance.currentUser?.uid ?? '',
            ),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final currentUserName = userSnapshot.data;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      FullScreenImageView(imageUrl: imageUrl),
                            ),
                          );
                        },
                        child: Hero(
                          tag: imageUrl,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                imageUrl.isNotEmpty
                                    ? Image.network(
                                      imageUrl,
                                      width: 250,
                                      height: 250,
                                      fit: BoxFit.cover,
                                    )
                                    : Container(
                                      width: 250,
                                      height: 250,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.fastfood,
                                        size: 100,
                                        color: Color(0xffffc533),
                                      ),
                                    ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text('Donor: $donor', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                    SizedBox(height: 16),
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow(Icons.category, 'Type', foodType),
                            _buildDetailRow(
                              Icons.confirmation_number,
                              'Quantity',
                              quantityStr,
                            ),
                            _buildDetailRow(
                              Icons.date_range,
                              'Expiry',
                              expiryDate,
                            ),
                            _buildDetailRow(Icons.map, 'Location', location),
                            _buildDetailRow(
                              Icons.local_shipping,
                              'Option',
                              option,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Note:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(note),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),

                    FutureBuilder<QuerySnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('basket')
                              .get(),
                      builder: (context, basketSnapshot) {
                        int basketCount = 0;
                        if (basketSnapshot.hasData) {
                          basketCount = basketSnapshot.data!.docs.length;
                        }

                        bool isBasketFull = basketCount >= 5;

                        return Column(
                          children: [
                            if (quantity == 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Unavailable',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (donor !=
                                currentUserName) // Hide buttons if donor is the current user
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (quantity == 0) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'No stocks available.',
                                              ),
                                            ),
                                          );
                                        } else if (isBasketFull) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text('Basket is full.'),
                                            ),
                                          );
                                        } else {
                                          _showAddToBasketSheet(
                                            context,
                                            quantityStr,
                                            userId!,
                                            foodId,
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            isBasketFull || quantity == 0
                                                ? Colors.grey
                                                : Color(0xffffffff),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Add to Basket',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _showGetQuantitySheet(
                                          context: context,
                                          originalContext: context,
                                          foodId: foodId,
                                          foodName: name,
                                          location: location,
                                          imageUrl: imageUrl,
                                          maxQuantity: quantity,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xffffc533),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Get',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          SizedBox(width: 8),
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

void _showAddToBasketSheet(
  BuildContext context,
  String availableQuantity,
  String userId,
  String foodId,
) async {
  final doc =
      await FirebaseFirestore.instance
          .collection('donations')
          .doc(foodId)
          .get();
  final data = doc.data() as Map<String, dynamic>;

  final imageUrl = data['imageUrl'] as String? ?? '';
  final foodName = data['name'] as String? ?? 'No Name';
  final location = data['location'] as String? ?? 'N/A';

  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      int selectedQuantity = 1;
      int maxQuantity = int.tryParse(availableQuantity) ?? 1;

      return StatefulBuilder(
        builder: (context, setState) {
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                /// Image, Name and Location Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          imageUrl.isNotEmpty
                              ? Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.fastfood,
                                  color: Color(0xffffc533),
                                  size: 30,
                                ),
                              ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            foodName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  location,
                                  style: TextStyle(color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                /// Select Quantity Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quantity:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          color: Color(0xffffc533),
                          onPressed:
                              selectedQuantity > 1
                                  ? () => setState(() => selectedQuantity--)
                                  : null,
                        ),
                        Text(
                          '$selectedQuantity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline),
                          color: Color(0xffffc533),
                          onPressed:
                              selectedQuantity < maxQuantity
                                  ? () => setState(() => selectedQuantity++)
                                  : null,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20),

                /// Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final basketRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .collection('basket')
                          .doc(foodId);
                      final basketDoc = await basketRef.get();

                      if (basketDoc.exists) {
                        final currentQuantity =
                            basketDoc.data()?['quantity'] ?? 0;
                        await basketRef.update({
                          'quantity': currentQuantity + selectedQuantity,
                          'addedAt': FieldValue.serverTimestamp(),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $selectedQuantity to Basket!'),
                          ),
                        );
                      } else {
                        await basketRef.set({
                          'addedAt': FieldValue.serverTimestamp(),
                          'quantity': selectedQuantity,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added $selectedQuantity to Basket!'),
                          ),
                        );
                      }

                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffffc533),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Add to Basket',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showGetQuantitySheet({
  required BuildContext context,
  required BuildContext originalContext,
  required String foodId,
  required String foodName,
  required String location,
  required String imageUrl,
  required int maxQuantity,
}) async {
  final remaining = await getRemainingWeeklyQuantity();

  if (remaining <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("You have reached the 3-item weekly limit.")),
    );
    return;
  }

  int availableToSelect = remaining < maxQuantity ? remaining : maxQuantity;

  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      int selectedQuantity = 1;

      return StatefulBuilder(
        builder: (context, setState) {
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // --- Food Image + Name + Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child:
                          imageUrl.isNotEmpty
                              ? Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                              : Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.fastfood,
                                  color: Color(0xffffc533),
                                  size: 30,
                                ),
                              ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            foodName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  location,
                                  style: TextStyle(color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // --- Quantity selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quantity:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline),
                          color: Color(0xffffc533),
                          onPressed:
                              selectedQuantity > 1
                                  ? () => setState(() => selectedQuantity--)
                                  : null,
                        ),
                        Text(
                          '$selectedQuantity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.add_circle_outline),
                          color: Color(0xffffc533),
                          onPressed:
                              selectedQuantity < availableToSelect
                                  ? () => setState(() => selectedQuantity++)
                                  : null,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "You only have $availableToSelect item(s) left this week.",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),

                SizedBox(height: 20),

                // --- Confirm Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet first

                      // Use a post-frame callback to delay until after pop
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        showGetBasketFlow(
                          context:
                              originalContext, // <-- this should be the parent page's context, not the bottom sheet
                          items: [
                            GetFoodItem(
                              foodId: foodId,
                              foodName: foodName,
                              location: location,
                              quantity: selectedQuantity,
                              imageUrl: imageUrl,
                            ),
                          ],
                        );
                      });
                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffffc533),
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Confirm Get',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
