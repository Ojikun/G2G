import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'TradeRequestDetail.dart';

class NotifPage extends StatefulWidget {
  const NotifPage({Key? key}) : super(key: key);

  @override
  _NotifPageState createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color(0xffffc533),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser?.uid)
                .collection('notifications')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final isTradeRequest =
                  notification['title'] == 'New Trade Request';

              return ListTile(
                leading: Stack(
                  children: [
                    Icon(
                      isTradeRequest ? Icons.swap_horiz : Icons.check_circle,
                      color: const Color(0xffffc533),
                      size: 30,
                    ),
                    if (!(notification['isRead'] ?? false))
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
                title: Text(notification['title'] ?? 'Notification'),
                subtitle: Text(
                  notification['body'] ?? '',
                  style: TextStyle(
                    fontWeight:
                        (notification['isRead'] ?? false)
                            ? FontWeight.normal
                            : FontWeight.bold,
                  ),
                ),
                trailing: Text(
                  _formatTimestamp(notification['timestamp']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () async {
                  // Mark notification as read
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser!.uid)
                      .collection('notifications')
                      .doc(notifications[index].id)
                      .update({'isRead': true});

                  // Navigate to trade request detail page if applicable
                  if (notification['tradePostId'] != null &&
                      notification['requestId'] != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => TradeRequestDetailPage(
                              postId: notification['tradePostId'],
                              requestId: notification['requestId'],
                            ),
                      ),
                    );
                  } else {
                    // Show an error message if details are missing
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Invalid notification details.'),
                      ),
                    );
                  }
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
