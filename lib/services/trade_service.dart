import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'cloudinary_service.dart';

class TradeService {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Method to submit a trade request
  Future<void> submitTradeRequest(
    String tradePostId,
    String tradeDescription,
    File? tradeImage,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || tradeDescription.isEmpty) {
      return;
    }

    final String currentUserId = currentUser.uid;

    // Fetch user's name
    String name = 'Unknown User';
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUserId)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        name = userDoc.data()!['name'] ?? 'Unknown User';
      }
    } catch (e) {
      name = 'Unknown User';
    }

    // Upload image if provided
    String? uploadedImageUrl;
    if (tradeImage != null) {
      uploadedImageUrl = await _cloudinaryService.uploadImage(tradeImage);
    }

    // Add trade request to Firestore
    await FirebaseFirestore.instance
        .collection('trades')
        .doc(tradePostId)
        .collection('tradeRequests')
        .add({
          'uid': currentUserId,
          'name': name,
          'tradeDescription': tradeDescription,
          'tradeImageUrl': uploadedImageUrl,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'pending',
          'isRead': false,
        });
  }

  // Method to show the dialog for trade request
  Future<void> showTradeRequestDialog(
    BuildContext context,
    String tradePostId,
  ) async {
    final TextEditingController _tradeDescriptionController =
        TextEditingController();
    File? _selectedImage;

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Request Trade'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _tradeDescriptionController,
                  decoration: InputDecoration(labelText: 'Trade Description'),
                  maxLines: 3,
                ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.image),
                  label: Text('Select Image'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (picked != null) {
                      _selectedImage = File(picked.path);
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
                  final tradeDescription =
                      _tradeDescriptionController.text.trim();
                  if (tradeDescription.isEmpty) {
                    Navigator.pop(context);
                    return;
                  }

                  final currentUser = FirebaseAuth.instance.currentUser;
                  if (currentUser == null) {
                    Navigator.pop(context);
                    return;
                  }

                  // Fetch target user's **username** from the 'trades' document
                  String targetUsername = 'User';
                  try {
                    final tradePostDoc =
                        await FirebaseFirestore.instance
                            .collection('trades')
                            .doc(tradePostId)
                            .get();
                    if (tradePostDoc.exists && tradePostDoc.data() != null) {
                      targetUsername =
                          tradePostDoc.data()!['username'] ?? 'User';
                    }
                  } catch (e) {
                    // Optional: log or handle error
                  }

                  // Submit the trade request
                  await submitTradeRequest(
                    tradePostId,
                    tradeDescription,
                    _selectedImage,
                  );

                  Navigator.pop(context); // Close the dialog first

                  // Show Snackbar after successful submission
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Trade request sent to $targetUsername'),
                    ),
                  );
                },
                child: Text('Submit Request'),
              ),
            ],
          ),
    );
  }
}
