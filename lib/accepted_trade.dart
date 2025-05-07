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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Trade Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff238855),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Background Image
                          Positioned.fill(
                            child:
                                tradePost?['imageUrl']?.isNotEmpty == true
                                    ? Image.network(
                                      tradePost!['imageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: const Color(0xfffd8536),
                                          child: const Center(
                                            child: Icon(
                                              Icons.fastfood,
                                              size: 60,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                    : Container(
                                      color: const Color(0xfffd8536),
                                      child: const Center(
                                        child: Icon(
                                          Icons.fastfood,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                          ),
                          // Gradient overlay with text
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${tradePost?['quantity'] ?? 'N/A'} ${tradePost?['foodName'] ?? 'Unknown Food'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Expiry: ${tradePost?['expiry'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Description: ${tradePost?['description'] ?? 'No description'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Background Image
                          Positioned.fill(
                            child:
                                tradeRequest?['tradeImageUrl']?.isNotEmpty ==
                                        true
                                    ? Image.network(
                                      tradeRequest!['tradeImageUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return Container(
                                          color: const Color(0xfffd8536),
                                          child: const Center(
                                            child: Icon(
                                              Icons.fastfood,
                                              size: 60,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                    : Container(
                                      color: const Color(0xfffd8536),
                                      child: const Center(
                                        child: Icon(
                                          Icons.fastfood,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                          ),
                          // Gradient overlay with text
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${tradeRequest?['tradeQuantity'] ?? 'N/A'} ${tradeRequest?['tradeFoodName'] ?? 'Unknown Food'}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Trade Expiry: ${tradeRequest?['tradeExpiry'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Description: ${tradeRequest?['tradeDescription'] ?? 'No description'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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
