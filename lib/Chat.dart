import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'ChatList.dart';
import 'Profile.dart';
import 'services/chat_service.dart';
import 'services/cloudinary_service.dart';

class ChatScreen extends StatefulWidget {
  final String personName;
  final String currentUserId;
  final String otherUserId;
  final String? profileImageUrl;

  const ChatScreen({
    Key? key,
    required this.personName,
    required this.currentUserId,
    required this.otherUserId,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Set<int> _visibleTimestamps = {};

  final _cloudinaryService = CloudinaryService();
  final _imagePicker = ImagePicker();
  String? _editingMessageId;
  String? _originalText;

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile == null) return;

      final imageFile = File(pickedFile.path);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Uploading image...')));
      }

      final imageUrl = await _cloudinaryService.uploadImage(imageFile);

      if (imageUrl != null) {
        await ChatService.sendMessage(
          currentUserId: widget.currentUserId,
          otherUserId: widget.otherUserId,
          messageText: imageUrl,
          senderName: widget.personName,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload image. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error selecting image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      if (_editingMessageId != null) {
        // Handle edit
        if (messageText != _originalText) {
          final chatId = ChatService.getChatId(
            widget.currentUserId,
            widget.otherUserId,
          );
          await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc(_editingMessageId)
              .update({'text': messageText, 'edited': true});
        }
        setState(() {
          _editingMessageId = null;
          _originalText = null;
        });
      } else {
        // Handle new message
        await ChatService.sendMessage(
          currentUserId: widget.currentUserId,
          otherUserId: widget.otherUserId,
          messageText: messageText,
          senderName: widget.personName,
        );
      }

      _messageController.clear();

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMessageOptions(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final isMe = data['sender'] == widget.currentUserId;

    if (!isMe) return; // Only show options for user's own messages

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Color(0xff238855)),
                  title: const Text('Edit Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _editMessage(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Color(0xfffd8536)),
                  title: const Text('Delete Message'),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(message.id);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _deleteMessage(String messageId) async {
    try {
      final chatId = ChatService.getChatId(
        widget.currentUserId,
        widget.otherUserId,
      );
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editMessage(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final currentText = data['text'] as String;

    setState(() {
      _editingMessageId = message.id;
      _originalText = currentText;
      _messageController.text = currentText;
    });

    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    FocusScope.of(context).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [_buildTopBar(), _buildMessageList(), _buildInputBox()],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              }
            },
            child: const Icon(Icons.arrow_back_ios),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _navigateToProfile(),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: _getProfileImage(),
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToProfile(),
              child: Text(
                widget.personName,
                style: TextStyle(
                  color: Color(0xff238855),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const Icon(Icons.info_outline),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('chats')
                .doc(
                  ChatService.getChatId(
                    widget.currentUserId,
                    widget.otherUserId,
                  ),
                )
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No messages yet.\nStart a conversation!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
              ),
            );
          }

          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder:
                (context, index) =>
                    _buildMessageItem(snapshot.data!.docs[index], index),
          );
        },
      ),
    );
  }

  Widget _buildInputBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
      child: Column(
        children: [
          if (_editingMessageId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.grey[200],
              child: Row(
                children: [
                  const Text(
                    'Editing message',
                    style: TextStyle(color: Color(0xff238855)),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _editingMessageId = null;
                        _originalText = null;
                        _messageController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xff238855),
                ),
                onPressed: _showImageSourceDialog,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xff238855)),
                  ),
                  child: TextField(
                    controller: _messageController,
                    cursorColor: Color(0xff238855),
                    decoration: InputDecoration(
                      hintText:
                          _editingMessageId != null
                              ? "Edit message..."
                              : "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _editingMessageId != null ? Icons.check : Icons.send,
                  color: const Color(0xff238855),
                ),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(bool isMe, String message) {
    final isImage = message.startsWith('http');

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) _buildAvatar(),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: isImage ? const EdgeInsets.all(4) : const EdgeInsets.all(12),
          constraints: const BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xff238855) : Colors.grey[300],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
              bottomRight: isMe ? Radius.zero : const Radius.circular(12),
            ),
          ),
          child:
              isImage
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      message,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                    ),
                  )
                  : Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildMessageItem(DocumentSnapshot message, int index) {
    final data = message.data() as Map<String, dynamic>;
    final isMe = data['sender'] == widget.currentUserId;
    final timestamp = data['timestamp'] as Timestamp?;
    final isEdited = data['edited'] as bool? ?? false;

    return GestureDetector(
      onTap: () => _toggleTimestamp(index),
      onLongPress: () => _showMessageOptions(message),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _buildChatBubble(isMe, data['text']),
          if (_visibleTimestamps.contains(index))
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEdited)
                    const Text(
                      'edited • ',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  if (timestamp != null)
                    Text(
                      _formatTimestamp(timestamp.toDate()),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundImage: _getProfileImage(),
      backgroundColor: Colors.grey[300],
      child:
          widget.profileImageUrl == null || widget.profileImageUrl!.isEmpty
              ? const Icon(Icons.person, color: Colors.white, size: 20)
              : null,
    );
  }

  ImageProvider _getProfileImage() {
    return (widget.profileImageUrl != null &&
            widget.profileImageUrl!.isNotEmpty)
        ? NetworkImage(widget.profileImageUrl!)
        : const AssetImage('assets/default_avatar.png') as ImageProvider;
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(otherUserId: widget.otherUserId),
      ),
    );
  }

  void _toggleTimestamp(int index) {
    setState(() {
      if (_visibleTimestamps.contains(index)) {
        _visibleTimestamps.remove(index);
      } else {
        _visibleTimestamps.add(index);
      }
    });
  }
}

String _formatTimestamp(DateTime timestamp) {
  final now = DateTime.now();
  final difference = now.difference(timestamp);

  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m';
  if (difference.inHours < 24) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return DateFormat('MM/dd/yy').format(timestamp);
}
