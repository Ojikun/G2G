import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';
import 'fcm_service.dart';

class TradeService {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  Future<void> submitTradeRequest({
    required String tradePostId,
    required String tradeDescription,
    required String tradeFoodName,
    required String tradeQuantity,
    required String tradeExpiry,
    File? tradeImage,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final String currentUserId = currentUser.uid;

    // Fetch the current user's name
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
    } catch (_) {
      name = 'Unknown User';
    }

    // Upload image if provided
    String? uploadedImageUrl;
    if (tradeImage != null) {
      uploadedImageUrl = await _cloudinaryService.uploadImage(tradeImage);
    }

    // Add trade request to Firestore
    final tradeRequestRef =
        FirebaseFirestore.instance
            .collection('trades')
            .doc(tradePostId)
            .collection('tradeRequests')
            .doc();

    await tradeRequestRef.set({
      'uid': currentUserId,
      'name': name,
      'tradeDescription': tradeDescription,
      'tradeFoodName': tradeFoodName,
      'tradeQuantity': tradeQuantity,
      'tradeExpiry': tradeExpiry,
      'tradeImageUrl': uploadedImageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
      'isRead': false,
    });

    // Fetch the trade post owner's FCM token and send push notification
    try {
      final tradePostDoc =
          await FirebaseFirestore.instance
              .collection('trades')
              .doc(tradePostId)
              .get();

      if (tradePostDoc.exists && tradePostDoc.data() != null) {
        final targetUserId = tradePostDoc.data()!['uid'];

        // Fetch the FCM token of the target user
        final targetUserDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(targetUserId)
                .get();

        if (targetUserDoc.exists && targetUserDoc.data() != null) {
          final targetToken = targetUserDoc.data()!['fcmToken'];

          // Send FCM notification to the target user
          if (targetToken != null) {
            await FCMServiceV1.sendPushNotification(
              targetToken: targetToken,
              title: 'New Trade Request',
              body: '$name wants to trade with you!',
            );
          }

          // Add a notification entry in Firestore for the trade post owner
          await FirebaseFirestore.instance
              .collection('users')
              .doc(targetUserId)
              .collection('notifications')
              .add({
                'title': 'New Trade Request',
                'body': '$name wants to trade with you!',
                'tradePostId': tradePostId, // Save tradePostId
                'requestId': tradeRequestRef.id, // Save requestId
                'timestamp': FieldValue.serverTimestamp(),
                'isRead': false,
              });
        }
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }

  Future<void> showTradeRequestOverlay({
    required BuildContext context,
    required String tradePostId,
  }) async {
    final TextEditingController _tradeDescriptionController =
        TextEditingController();
    final TextEditingController _foodNameController = TextEditingController();
    final TextEditingController _quantityController = TextEditingController();
    final TextEditingController _expiryController = TextEditingController();
    File? _selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: GestureDetector(
                  onTap: () {},
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    maxChildSize: 0.95,
                    minChildSize: 0.5,
                    builder: (context, scrollController) {
                      return Container(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Bar with Back Button, Title, and Submit Button
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.arrow_back_ios,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                    Text(
                                      'Submit Trade Request',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final tradeDescription =
                                            _tradeDescriptionController.text
                                                .trim();
                                        final tradeFoodName =
                                            _foodNameController.text.trim();
                                        final tradeQuantity =
                                            _quantityController.text.trim();
                                        final tradeExpiry =
                                            _expiryController.text.trim();

                                        if (tradeDescription.isEmpty ||
                                            tradeFoodName.isEmpty ||
                                            tradeQuantity.isEmpty ||
                                            tradeExpiry.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Please fill in all fields',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        // Show loading indicator
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (BuildContext context) {
                                            return const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            );
                                          },
                                        );

                                        try {
                                          await submitTradeRequest(
                                            tradePostId: tradePostId,
                                            tradeDescription: tradeDescription,
                                            tradeFoodName: tradeFoodName,
                                            tradeQuantity: tradeQuantity,
                                            tradeExpiry: tradeExpiry,
                                            tradeImage: _selectedImage,
                                          );

                                          Navigator.pop(
                                            context,
                                          ); // Close the loading indicator
                                          Navigator.pop(
                                            context,
                                          ); // Close the modal
                                        } catch (e) {
                                          Navigator.pop(
                                            context,
                                          ); // Close the loading indicator
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error: ${e.toString()}',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Text('Submit'),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(thickness: 1, color: Colors.grey[300]),

                              // Trade Description
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextField(
                                  controller: _tradeDescriptionController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText: 'Write your trade description...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),

                              // Food Name
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextField(
                                  controller: _foodNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Food Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),

                              // Quantity
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextField(
                                  controller: _quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),

                              // Expiry Date
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextField(
                                  controller: _expiryController,
                                  readOnly: true,
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      setModalState(() {
                                        _expiryController.text =
                                            '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Expiry Date',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),

                              // Image Picker
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: GestureDetector(
                                  onTap: () async {
                                    final picker = ImagePicker();
                                    final picked = await picker.pickImage(
                                      source: ImageSource.gallery,
                                    );
                                    if (picked != null) {
                                      setModalState(() {
                                        _selectedImage = File(picked.path);
                                      });
                                    }
                                  },
                                  child: Container(
                                    height: 200,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                    child:
                                        _selectedImage == null
                                            ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.add_a_photo,
                                                    color: Color(0xffffc533),
                                                    size: 50,
                                                  ),
                                                  SizedBox(height: 10),
                                                  Text(
                                                    "Add an Image",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: Image.file(
                                                _selectedImage!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
