import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'TradeRequestDetail.dart';
import 'accepted_trade.dart';
import 'Chat.dart';
import 'Homepage.dart';

class NotifPage extends StatefulWidget {
  const NotifPage({Key? key}) : super(key: key);

  @override
  _NotifPageState createState() => _NotifPageState();
}

class _NotifPageState extends State<NotifPage> {
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view notifications')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context); // Go back to the previous screen
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false, // Remove all previous routes
              );
            }
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xff238855),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          return Future.delayed(const Duration(milliseconds: 500));
        },
        child: StreamBuilder<QuerySnapshot>(
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
                final isTradeAccepted =
                    notification['title'] == 'Trade Accepted';

                return Dismissible(
                  key: Key(notifications[index].id),
                  background: Container(
                    color: Color(0xfffd8536),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) async {
                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser?.uid)
                          .collection('notifications')
                          .doc(notifications[index].id)
                          .delete();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting notification: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xfffd8536),
                          child:
                              isTradeRequest || isTradeAccepted
                                  ? Image.asset(
                                    'assets/tradebutton.png',
                                    width: 24,
                                    height: 24,
                                    color: Colors.white,
                                  )
                                  : Icon(
                                    Icons.notifications,
                                    color: Colors.white,
                                  ),
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
                    title: Text(
                      notification['title'] ?? 'Notification',
                      style: TextStyle(
                        fontWeight:
                            (notification['isRead'] ?? false)
                                ? FontWeight.normal
                                : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(notification['body'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(notification['timestamp']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      // Mark as read
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(currentUser?.uid)
                          .collection('notifications')
                          .doc(notifications[index].id)
                          .update({'isRead': true});

                      if (!mounted) return;

                      // Navigate based on notification type
                      if (isTradeAccepted) {
                        final tradePostId = notification['tradePostId'];
                        final requestId = notification['requestId'];
                        if (tradePostId != null && requestId != null) {
                          Navigator.push(
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
                      } else if (isTradeRequest) {
                        final tradePostId = notification['tradePostId'];
                        final requestId = notification['requestId'];
                        if (tradePostId != null && requestId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => TradeRequestDetailPage(
                                    postId: tradePostId,
                                    requestId: requestId,
                                  ),
                            ),
                          );
                        }
                      } else if (notification['chatId'] != null) {
                        final chatId = notification['chatId'].toString();
                        final otherUserId = chatId
                            .split('_')
                            .firstWhere(
                              (id) => id != currentUser?.uid,
                              orElse: () => '',
                            );
                        if (otherUserId.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChatScreen(
                                    personName:
                                        notification['senderName'] ?? 'User',
                                    currentUserId: currentUser!.uid,
                                    otherUserId: otherUserId,
                                    profileImageUrl:
                                        notification['senderProfileImage'],
                                  ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}
