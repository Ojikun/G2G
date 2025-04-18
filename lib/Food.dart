import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodScreen extends StatelessWidget {
  final String foodId;

  const FoodScreen({required this.foodId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Food Details'), backgroundColor: Colors.teal),
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
          final quantity = data['quantity']?.toString() ?? '0';
          final foodType = data['foodType'] as String? ?? 'Unknown';
          final expiryDate = data['expiry'] as String? ?? 'Unknown';
          final donor = data['username'] as String? ?? 'Anonymous';
          final option = data['option'] as String? ?? 'Pick‑up';
          final location = data['location'] as String? ?? 'N/A';
          final note = data['note'] as String? ?? 'No notes provided.';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food Image
                Center(
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
                                color: Colors.teal,
                              ),
                            ),
                  ),
                ),
                SizedBox(height: 24),

                // Name & Donor
                Text(
                  name,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
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

                // Details Card
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
                          quantity,
                        ),
                        _buildDetailRow(Icons.date_range, 'Expiry', expiryDate),
                        _buildDetailRow(Icons.map, 'Location', location),
                        _buildDetailRow(Icons.local_shipping, 'Option', option),
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
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: implement "Add to Basket"
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange, // fixed here
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Add to Basket',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: implement "Get"
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal, // fixed here
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Get', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
