import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotifPage extends StatefulWidget {
  const NotifPage({Key? key}) : super(key: key);

  @override
  _NotifPageState createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  final currentUser = FirebaseAuth.instance.currentUser;
  late Future<List<DocumentSnapshot>> _userTradePosts;

  @override
  void initState() {
    super.initState();
    _userTradePosts = fetchUserTradePosts();
  }

  Future<List<DocumentSnapshot>> fetchUserTradePosts() async {
    if (currentUser == null) return [];
    final tradesSnapshot =
        await FirebaseFirestore.instance
            .collection('trades')
            .where('uid', isEqualTo: currentUser!.uid)
            .get();
    return tradesSnapshot.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _userTradePosts,
        builder: (context, tradePostsSnapshot) {
          if (tradePostsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!tradePostsSnapshot.hasData || tradePostsSnapshot.data!.isEmpty) {
            return const Center(child: Text('You have no trade posts.'));
          }

          final tradePosts = tradePostsSnapshot.data!;

          return ListView.builder(
            itemCount: tradePosts.length,
            itemBuilder: (context, index) {
              final post = tradePosts[index];
              final postId = post.id;

              return StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('trades')
                        .doc(postId)
                        .collection('tradeRequests')
                        .snapshots(),
                builder: (context, requestsSnapshot) {
                  if (requestsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!requestsSnapshot.hasData ||
                      requestsSnapshot.data!.docs.isEmpty) {
                    return const SizedBox.shrink(); // No requests
                  }

                  final tradeRequests = requestsSnapshot.data!.docs;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        tradeRequests.map((request) {
                          final data = request.data() as Map<String, dynamic>;

                          return ListTile(
                            leading: Stack(
                              children: [
                                const Icon(
                                  Icons.swap_horiz,
                                  color: Colors.blueAccent,
                                  size: 30,
                                ),
                                if (!(data['isRead'] ?? false))
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: const Text('Trade'),
                            subtitle: Text(
                              '${data['name'] ?? 'Someone'} wants to trade with you!',
                              style: TextStyle(
                                fontWeight:
                                    (data['isRead'] ?? false)
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              _formatTimestamp(data['timestamp']),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            onTap: () async {
                              // Mark notification as read
                              await FirebaseFirestore.instance
                                  .collection('trades')
                                  .doc(postId)
                                  .collection('tradeRequests')
                                  .doc(request.id)
                                  .update({'isRead': true});

                              // Navigate to detailed view page
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => TradeRequestDetailPage(
                                        tradeData: data,
                                        postId: postId,
                                        requestId: request.id,
                                      ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.month}/${date.day}/${date.year}';
  }
}

// Placeholder for detail page (create this later)
class TradeRequestDetailPage extends StatelessWidget {
  final Map<String, dynamic> tradeData;
  final String postId;
  final String requestId;

  const TradeRequestDetailPage({
    Key? key,
    required this.tradeData,
    required this.postId,
    required this.requestId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trade Request Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item: ${tradeData['name'] ?? 'Unknown'}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text('Description: ${tradeData['tradeDescription'] ?? ''}'),
            const SizedBox(height: 10),
            Text('Requested by: ${tradeData['requesterName'] ?? 'Someone'}'),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Accept logic here
                  },
                  child: const Text('Accept'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    // Decline logic here
                  },
                  child: const Text('Decline'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
