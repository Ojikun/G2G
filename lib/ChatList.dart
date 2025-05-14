import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'Chat.dart';
import 'Homepage.dart';
import 'services/chat_service.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      Future.microtask(
        () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        ),
      );
      return const SizedBox();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomeScreen()),
              );
            }
          },
        ),
        title: const Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xff238855),
        elevation: 1,
      ),
      body: _ChatList(currentUserId: currentUser.uid),
    );
  }
}

class _ChatList extends StatelessWidget {
  final String currentUserId;

  const _ChatList({Key? key, required this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('chats')
              .where('participants', arrayContains: currentUserId)
              .orderBy('lastMessageTimestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No conversations yet.\nStart chatting with someone!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          padding: const EdgeInsets.all(12),
          itemBuilder:
              (context, index) => _ChatListItem(
                chat: snapshot.data!.docs[index],
                currentUserId: currentUserId,
              ),
        );
      },
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final DocumentSnapshot chat;
  final String currentUserId;

  const _ChatListItem({
    Key? key,
    required this.chat,
    required this.currentUserId,
  }) : super(key: key);

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('MM/dd/yy').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    final chatData = chat.data() as Map<String, dynamic>;
    final lastMessage = chatData['lastMessage'] as String? ?? '';
    final lastMessageTimestamp = chatData['lastMessageTimestamp'] as Timestamp?;
    final lastMessageSender = chatData['lastMessageSender'] as String?;
    final readStatus = chatData['readStatus'] as Map<String, dynamic>? ?? {};

    final otherUserId = (chatData['participants'] as List).firstWhere(
      (id) => id != currentUserId,
      orElse: () => null,
    );

    if (otherUserId == null) return const SizedBox();

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final name = userData['name'] ?? 'Unknown User';
        final profileImage = userData['profileImage'] as String?;
        final isUnread = !(readStatus[currentUserId] ?? true);

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                profileImage != null ? NetworkImage(profileImage) : null,
            backgroundColor: Colors.grey[200],
            child: profileImage == null ? const Icon(Icons.person) : null,
          ),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            lastMessageSender == currentUserId
                ? 'You: $lastMessage'
                : lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isUnread ? Colors.black87 : Colors.grey,
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessageTimestamp != null)
                Text(
                  _formatTimestamp(lastMessageTimestamp.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnread ? Colors.black87 : Colors.grey,
                  ),
                ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xff238855),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          onTap: () => _openChat(context, otherUserId, name, profileImage),
        );
      },
    );
  }

  // Add this to the _ChatListItem class
  void _openChat(
    BuildContext context,
    String otherUserId,
    String name,
    String? profileImage,
  ) async {
    try {
      final currentUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();

      final currentUserName = currentUserDoc.data()?['name'] ?? 'User';
      // Mark as read using ChatService
      final chatId = ChatService.getChatId(currentUserId, otherUserId);
      await FirebaseFirestore.instance.collection('chats').doc(chatId).update({
        'readStatus.$currentUserId': true,
      });

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ChatScreen(
                  currentUserName: currentUserName,
                  personName: name,
                  currentUserId: currentUserId,
                  otherUserId: otherUserId,
                  profileImageUrl: profileImage,
                ),
          ),
        );
      }
    } catch (e) {
      print('Error opening chat: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open chat. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
