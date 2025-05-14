import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Food.dart';
import 'accepted_trade.dart';

class HistoryScreen extends StatefulWidget {
  final String userId;
  const HistoryScreen({
    Key? key,
    required this.userId, // Make userId required
  }) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final isCurrentUser =
        widget.userId == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isCurrentUser ? 'My History' : 'User History', // Dynamic title
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xff238855),
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              title: 'Gives',
              subtitle: 'Donation history',
              iconAsset: 'assets/give.png',
            ),
            const SizedBox(height: 10),
            _buildGivesSection(),

            const SizedBox(height: 20),

            _buildSectionHeader(
              title: 'Gets',
              subtitle: 'Received items',
              iconAsset: 'assets/get.png',
            ),
            const SizedBox(height: 10),
            _buildGetsSection(),

            const SizedBox(height: 20),

            _buildSectionHeader(
              title: 'Trades',
              subtitle: 'Trading history',
              iconAsset: 'assets/trade.png',
            ),
            const SizedBox(height: 10),
            _buildTradesSection(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required String iconAsset,
  }) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xff238855).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(iconAsset, width: 24, height: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff238855),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard({
    required String title,
    required String date,
    required String imageUrl,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              imageUrl.isNotEmpty
                  ? Image.network(
                    imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                  : Container(
                    width: 50,
                    height: 50,
                    color: Colors.white,
                    child: Icon(Icons.fastfood, color: Colors.white),
                  ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          date,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        onTap: onTap,
        trailing:
            onTap != null
                ? const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xfffd8536),
                  size: 16,
                )
                : null,
      ),
    );
  }

  Widget _buildGivesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('donations')
              .where('userId', isEqualTo: widget.userId) // Use passed userId
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No donations yet. Start giving to earn badges!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildHistoryCard(
              title: data['name'] ?? 'No Name',
              date:
                  "Donated on: ${data['timestamp']?.toDate().toString().split(' ')[0] ?? 'N/A'}",
              imageUrl: data['imageUrl'] ?? '',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FoodScreen(foodId: doc.id),
                    ),
                  ),
            );
          },
        );
      },
    );
  }

  Widget _buildGetsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(widget.userId) // Use passed userId
              .collection('gets')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No items received yet.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final foodId = data['foodId'] ?? '';

            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('donations')
                      .doc(foodId)
                      .get(),
              builder: (context, donationSnapshot) {
                if (!donationSnapshot.hasData) {
                  return const SizedBox();
                }

                final donationData =
                    donationSnapshot.data?.data() as Map<String, dynamic>?;

                return _buildHistoryCard(
                  title: data['foodName'] ?? 'No Name',
                  date:
                      "Received on: ${data['timestamp']?.toDate().toString().split(' ')[0] ?? 'N/A'}",
                  imageUrl: donationData?['imageUrl'] ?? '',
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodScreen(foodId: foodId),
                        ),
                      ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTradesSection() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('trades')
              .where('uid', isEqualTo: widget.userId) // Use passed userId
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No trades yet. Start trading to earn badges!',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            return _buildHistoryCard(
              title: data['foodName'] ?? 'No Name',
              date: "Traded on: ${_formatDate(data['timestamp'])}",
              imageUrl: data['imageUrl'] ?? '',
              onTap: () async {
                try {
                  final tradePostId = doc.id;

                  // Get trade requests for this trade
                  final tradeRequestsSnapshot =
                      await FirebaseFirestore.instance
                          .collection('trades')
                          .doc(tradePostId)
                          .collection('tradeRequests')
                          .where('status', isEqualTo: 'accepted')
                          .limit(1)
                          .get();

                  if (tradeRequestsSnapshot.docs.isEmpty) {
                    print('DEBUG: No accepted trade request found');
                    // Handle pending or other status
                    final foodId = data['foodId'];
                    if (foodId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodScreen(foodId: foodId),
                        ),
                      );
                    }
                    return;
                  }

                  final requestDoc = tradeRequestsSnapshot.docs.first;
                  final requestId = requestDoc.id;
                  final requestData = requestDoc.data();

                  print(
                    'DEBUG: Trade tile clicked. Status: ${requestData['status']}',
                  );
                  print('DEBUG: Request ID: $requestId');

                  if (requestData['status'] == 'accepted') {
                    print('DEBUG: Navigating to AcceptedTradePage');
                    print('DEBUG: Trade Post ID: $tradePostId');

                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AcceptedTradePage(
                              tradePostId: tradePostId,
                              requestId: requestId,
                            ),
                      ),
                    );
                  }
                } catch (e) {
                  print('DEBUG: Error navigating to trade details: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

String _formatDate(Timestamp? timestamp) {
  if (timestamp == null) return 'N/A';
  final date = timestamp.toDate();
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
