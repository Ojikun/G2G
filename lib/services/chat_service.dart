import 'package:cloud_firestore/cloud_firestore.dart';
import '/services/fcm_service.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;

  static String getChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_${userId2}'
        : '${userId2}_${userId1}';
  }

  static Future<void> sendMessage({
    required String currentUserId,
    required String otherUserId,
    required String messageText,
    required String senderName,
  }) async {
    if (messageText.trim().isEmpty) return;

    final chatId = getChatId(currentUserId, otherUserId);
    final chatRef = _firestore.collection('chats').doc(chatId);
    final messagesRef = chatRef.collection('messages');

    // Create or update chat document
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await _createNewChat(
        chatRef: chatRef,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        messageText: messageText,
        senderName: senderName,
      );
    } else {
      await _updateExistingChat(
        chatRef: chatRef,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        messageText: messageText,
      );
    }

    // Add message
    await messagesRef.add({
      'sender': currentUserId,
      'text': messageText,
      'timestamp': FieldValue.serverTimestamp(),
      'readStatus': {currentUserId: true, otherUserId: false},
    });
  }

  static Future<void> _createNewChat({
    required DocumentReference chatRef,
    required String currentUserId,
    required String otherUserId,
    required String messageText,
    required String senderName,
  }) async {
    await chatRef.set({
      'participants': [currentUserId, otherUserId],
      'lastMessage': messageText,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSender': currentUserId,
      'readStatus': {currentUserId: true, otherUserId: false},
    });

    await _sendNotification(
      otherUserId: otherUserId,
      senderName: senderName,
      chatId: chatRef.id,
    );
  }

  static Future<void> _updateExistingChat({
    required DocumentReference chatRef,
    required String currentUserId,
    required String otherUserId,
    required String messageText,
  }) async {
    await chatRef.update({
      'lastMessage': messageText,
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'lastMessageSender': currentUserId,
      'readStatus.$currentUserId': true,
      'readStatus.$otherUserId': false,
    });
  }

  static Future<void> _sendNotification({
    required String otherUserId,
    required String senderName,
    required String chatId,
  }) async {
    final otherUserDoc =
        await _firestore.collection('users').doc(otherUserId).get();

    final otherUserData = otherUserDoc.data() ?? {};
    final otherUserToken = otherUserData['fcmToken'];

    if (otherUserToken != null) {
      await FCMServiceV1.sendPushNotification(
        targetToken: otherUserToken,
        title: 'New Message',
        body: '$senderName sent you a message!',
      );

      await _firestore
          .collection('users')
          .doc(otherUserId)
          .collection('notifications')
          .add({
            'title': 'New Message',
            'body': '$senderName sent you a message!',
            'timestamp': FieldValue.serverTimestamp(),
            'isRead': false,
            'chatId': chatId,
          });
    }
  }
}
