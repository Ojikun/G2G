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

    try {
      final chatId = getChatId(currentUserId, otherUserId);
      final chatRef = _firestore.collection('chats').doc(chatId);
      final messagesRef = chatRef.collection('messages');
      final batch = _firestore.batch();

      // Create message document first
      final messageDoc = messagesRef.doc();
      final messageData = {
        'messageId': messageDoc.id,
        'sender': currentUserId,
        'senderName': senderName,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'readStatus': {currentUserId: true, otherUserId: false},
        'edited': false,
      };
      batch.set(messageDoc, messageData);

      // Check if chat exists and update accordingly
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        // Create new chat
        batch.set(chatRef, {
          'participants': [currentUserId, otherUserId],
          'lastMessage': messageText,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUserId,
          'readStatus': {currentUserId: true, otherUserId: false},
        });
      } else {
        // Update existing chat
        batch.update(chatRef, {
          'lastMessage': messageText,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
          'lastMessageSender': currentUserId,
          'readStatus.$currentUserId': true,
          'readStatus.$otherUserId': false,
        });
      }

      // Commit all changes atomically
      await batch.commit();

      // Send notification after successful commit
      await _sendNotification(
        recipientId: otherUserId, // Correct - this is the receiver
        senderId: currentUserId, // Correct - this is the sender
        senderName: senderName,
        chatId: chatId,
        messageText: messageText,
      );
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  static Future<void> _sendNotification({
    required String recipientId,
    required String senderId,
    required String senderName,
    required String chatId,
    required String messageText,
  }) async {
    try {
      // Debug: Get current user's (sender's) token for comparison
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();
      final senderToken = senderDoc.data()?['fcmToken'] as String?;
      print(
        'DEBUG: 👤 Current user (sender) FCM: ${senderToken?.substring(0, 10)}...',
      );

      // Debug: Get recipient's token
      final recipientDoc =
          await _firestore.collection('users').doc(recipientId).get();
      final recipientToken = recipientDoc.data()?['fcmToken'] as String?;
      print('DEBUG: 📱 Recipient FCM: ${recipientToken?.substring(0, 10)}...');

      if (recipientToken == null || recipientToken.isEmpty) {
        print('DEBUG: ❌ No FCM token found for recipient');
        return;
      }

      // Compare tokens
      if (senderToken == recipientToken) {
        print(
          'DEBUG: ⚠️ WARNING: Sender and recipient have the same FCM token!',
        );
        return;
      }

      // Double check token ownership
      final verifyDoc =
          await _firestore
              .collection('users')
              .where('fcmToken', isEqualTo: recipientToken)
              .get();

      if (verifyDoc.docs.isEmpty || verifyDoc.docs.first.id != recipientId) {
        print('DEBUG: ❌ Token ownership verification failed');
        return;
      }

      print('DEBUG: ✅ Verified token belongs to recipient: $recipientId');

      await FCMServiceV1.sendPushNotification(
        targetToken: recipientToken,
        title: '$senderName sent you a message',
        body:
            messageText.length > 50
                ? '${messageText.substring(0, 47)}...'
                : messageText,
        payload: {
          'type': 'message',
          'chatId': chatId,
          'senderId': senderId,
          'recipientId': recipientId,
          'senderName': senderName,
        },
      );
    } catch (e) {
      print('DEBUG: ❌ Error in _sendNotification: $e');
    }
  }

  static Future<void> updateFCMToken(String userId, String newToken) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Check if the token is already in use by another user
      final existingTokenDocs =
          await firestore
              .collection('users')
              .where('fcmToken', isEqualTo: newToken)
              .get();

      for (var doc in existingTokenDocs.docs) {
        if (doc.id != userId) {
          // Remove the token from other users
          await firestore.collection('users').doc(doc.id).update({
            'fcmToken': FieldValue.delete(),
          });
        }
      }

      // Update the current user's token
      await firestore.collection('users').doc(userId).update({
        'fcmToken': newToken,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });

      print('DEBUG: ✅ FCM token updated for user: $userId');
    } catch (e) {
      print('DEBUG: ❌ Error updating FCM token: $e');
    }
  }
}
