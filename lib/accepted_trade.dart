import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AcceptedTradePage extends StatelessWidget {
  final String tradePostId;
  final String requestId;

  const AcceptedTradePage({
    Key? key,
    required this.tradePostId,
    required this.requestId,
  }) : super(key: key);

  Future<Map<String, dynamic>> _fetchTradeDetails() async {
    final tradePostSnapshot =
        await FirebaseFirestore.instance
            .collection('trades')
            .doc(tradePostId)
            .get();

    final tradeRequestSnapshot =
        await FirebaseFirestore.instance
            .collection('trades')
            .doc(tradePostId)
            .collection('tradeRequests')
            .doc(requestId)
            .get();

    return {
      'tradePost': tradePostSnapshot.data(),
      'tradeRequest': tradeRequestSnapshot.data(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Trade Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xffffc533),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchTradeDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Error loading trade details.'));
          }

          final tradePost = snapshot.data!['tradePost'];
          final tradeRequest = snapshot.data!['tradeRequest'];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Display the traded product from the trade post
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            tradePost?['imageUrl'] ?? '',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tradePost?['quantity'] ?? 'N/A'} ${tradePost?['foodName'] ?? 'Unknown Food'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Description: ${tradePost?['description'] ?? 'No description'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Expiry: ${tradePost?['expiry'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Display the traded product from the trade request
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            tradeRequest?['tradeImageUrl'] ?? '',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${tradeRequest?['tradeQuantity'] ?? 'N/A'} ${tradeRequest?['tradeFoodName'] ?? 'Unknown Food'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Description: ${tradeRequest?['tradeDescription'] ?? 'No description'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Trade Expiry: ${tradeRequest?['tradeExpiry'] ?? 'N/A'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
