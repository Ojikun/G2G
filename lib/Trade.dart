import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/cloudinary_service.dart';
import 'services/trade_service.dart';

class TradeHomePage extends StatefulWidget {
  @override
  _TradeHomePageState createState() => _TradeHomePageState();
}

class _TradeHomePageState extends State<TradeHomePage> {
  final TextEditingController _tradeController = TextEditingController();
  File? _selectedImage;
  String? _currentUserId;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String> _getUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Anonymous';
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['name'] ?? 'Anonymous';
  }

  Future<void> _submitTrade() async {
    final tradeText = _tradeController.text.trim();
    if (tradeText.isEmpty) return;
    final username = await _getUsername();

    String? uploadedImageUrl;
    if (_selectedImage != null) {
      uploadedImageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
    }

    await FirebaseFirestore.instance.collection('trades').add({
      'username': username,
      'description': tradeText,
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': uploadedImageUrl,
      'uid': _currentUserId,
    });

    _tradeController.clear();
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _editTrade(String docId, String oldDescription) async {
    final editController = TextEditingController(text: oldDescription);
    File? newImage;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Edit Trade'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: editController,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Description'),
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.image),
                  label: Text('Change Image'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      setState(() {
                        newImage = File(picked.path);
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newDesc = editController.text.trim();
                  Map<String, dynamic> updateData = {'description': newDesc};

                  if (newImage != null) {
                    final uploadedImageUrl = await _cloudinaryService
                        .uploadImage(newImage!);
                    if (uploadedImageUrl != null) {
                      updateData['imageUrl'] = uploadedImageUrl;
                    }
                  }

                  await FirebaseFirestore.instance
                      .collection('trades')
                      .doc(docId)
                      .update(updateData);

                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "G2G",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.person, color: Colors.white),
              ),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _tradeController,
                  decoration: InputDecoration(
                    hintText: 'Create trade post',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.image, color: Colors.teal),
                onPressed: _pickImage,
              ),
              IconButton(
                icon: Icon(Icons.send, color: Colors.teal),
                onPressed: _submitTrade,
              ),
            ],
          ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_selectedImage!, height: 100),
              ),
            ),
          SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('trades')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return Center(child: CircularProgressIndicator());

              final trades = snapshot.data!.docs;
              return Column(
                children:
                    trades.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildCard(
                        docId: doc.id,
                        username: data['username'] ?? 'Anonymous',
                        description: data['description'] ?? '',
                        timestamp:
                            data['timestamp']?.toDate() ?? DateTime.now(),
                        imageUrl: data['imageUrl'],
                        postUid: data['uid'],
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String docId,
    required String username,
    required String description,
    required DateTime timestamp,
    String? imageUrl,
    String? postUid,
  }) {
    final isOwner = _currentUserId == postUid;
    final showTradeButton = _currentUserId != null && !isOwner;

    return Stack(
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.teal,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 8),
              Text(description, style: TextStyle(fontSize: 16)),
              if (imageUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl, height: 100),
                  ),
                ),
              Text(
                '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')} • ${timestamp.day}/${timestamp.month}/${timestamp.year}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (showTradeButton)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        TradeService tradeService = TradeService();
                        tradeService.showTradeRequestDialog(
                          context,
                          docId, // Pass the docId (tradePostId) here
                        );
                      },
                      child: Text('Trade'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (isOwner)
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _editTrade(docId, description),
                  child: Icon(Icons.edit, color: Colors.grey[800], size: 20),
                ),
                GestureDetector(
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text('Delete Trade'),
                            content: Text(
                              'Are you sure you want to delete this trade?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                    );
                    if (confirmed == true) {
                      await FirebaseFirestore.instance
                          .collection('trades')
                          .doc(docId)
                          .delete();
                    }
                  },
                  child: Icon(Icons.close, color: Colors.grey[800], size: 20),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
