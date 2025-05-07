import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/fcm_service.dart';
import 'services/badge_service.dart';

class TradeRequestDetailPage extends StatefulWidget {
  final String postId;
  final String requestId;

  const TradeRequestDetailPage({
    Key? key,
    required this.postId,
    required this.requestId,
  }) : super(key: key);

  @override
  _TradeRequestDetailPageState createState() => _TradeRequestDetailPageState();
}

class _TradeRequestDetailPageState extends State<TradeRequestDetailPage> {
  Map<String, dynamic>? myPostData;
  Map<String, dynamic>? requestData;
  bool isLoading = true;
  bool isTradeDeclined = false;
  bool isTradeAccepted = false;

  @override
  void initState() {
    super.initState();
    fetchTradeDetails();
  }

  Future<void> fetchTradeDetails() async {
    try {
      final myPostSnapshot =
          await FirebaseFirestore.instance
              .collection('trades')
              .doc(widget.postId)
              .get();

      final requestSnapshot =
          await FirebaseFirestore.instance
              .collection('trades')
              .doc(widget.postId)
              .collection('tradeRequests')
              .doc(widget.requestId)
              .get();

      setState(() {
        myPostData = myPostSnapshot.data();
        requestData = requestSnapshot.data();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching trade details: $e');
    }
  }

  Future<void> _handleAccept(BuildContext context) async {
    Navigator.of(context).pop(); // Close the dialog
    setState(() => isTradeAccepted = true);

    try {
      // Update the trade request status to "accepted"
      await FirebaseFirestore.instance
          .collection('trades')
          .doc(widget.postId)
          .collection('tradeRequests')
          .doc(widget.requestId)
          .update({'status': 'accepted'});

      // Fetch the user who sent the trade request
      final offeredUserId = requestData?['uid'];
      final userSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(offeredUserId)
              .get();

      final fcmToken = userSnapshot.data()?['fcmToken'];
      final username = myPostData?['username'] ?? 'Someone';

      if (fcmToken != null) {
        // Send push notification
        await FCMServiceV1.sendPushNotification(
          targetToken: fcmToken,
          title: 'Trade Accepted',
          body: '$username accepted your trade request!',
        );

        // Add a notification entry in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(offeredUserId)
            .collection('notifications')
            .add({
              'title': 'Trade Accepted',
              'body': '$username accepted your trade request!',
              'tradePostId': widget.postId,
              'requestId': widget.requestId,
              'timestamp': FieldValue.serverTimestamp(),
              'isRead': false,
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trade Accepted and notification sent')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send notification: No FCM token'),
          ),
        );
      }

      // Check and award badges
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        await BadgeService.checkAndAwardBadges(context, currentUserId);
      }
    } catch (e) {
      print('Error while accepting trade: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
        title: const Text(
          'Trade Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(
          0xff238855,
        ), // Match Give.dart app bar color
        elevation: 0, // Remove shadow for a flat look
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // TOP: My Posted Item
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background Image
                      Positioned.fill(
                        child:
                            myPostData?['imageUrl']?.isNotEmpty == true
                                ? Image.network(
                                  myPostData!['imageUrl']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xfffd8536),
                                      child: const Center(
                                        child: Icon(
                                          Icons.fastfood,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  color: const Color(0xfffd8536),
                                  child: const Center(
                                    child: Icon(
                                      Icons.fastfood,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                      ),
                      // Gradient overlay with text
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${myPostData?['quantity'] ?? 'N/A'} ${myPostData?['foodName'] ?? 'Unknown Food'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Expiry: ${myPostData?['expiry'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Description: ${myPostData?['description'] ?? 'No description'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Background Image
                      Positioned.fill(
                        child:
                            requestData?['tradeImageUrl']?.isNotEmpty == true
                                ? Image.network(
                                  requestData!['tradeImageUrl']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: const Color(0xfffd8536),
                                      child: const Center(
                                        child: Icon(
                                          Icons.fastfood,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),
                                    );
                                  },
                                )
                                : Container(
                                  color: const Color(0xfffd8536),
                                  child: const Center(
                                    child: Icon(
                                      Icons.fastfood,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                      ),
                      // Gradient overlay with text
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${requestData?['tradeQuantity'] ?? 'N/A'} ${requestData?['tradeFoodName'] ?? 'Unknown Food'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Expiry: ${requestData?['tradeExpiry'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Description: ${requestData?['tradeDescription'] ?? 'No description'}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Accept / Decline buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        isTradeAccepted || isTradeDeclined
                            ? null // Disable button if trade is already accepted or declined
                            : () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      dialogBackgroundColor: Colors.white,
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xff238855,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text(
                                        'Confirm Decline',
                                        style: TextStyle(
                                          color: Color(0xff238855),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to decline this trade?',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            Navigator.of(context).pop();
                                            setState(() {
                                              isTradeDeclined = true;
                                            });
                                            try {
                                              await FirebaseFirestore.instance
                                                  .collection('trades')
                                                  .doc(widget.postId)
                                                  .collection('tradeRequests')
                                                  .doc(widget.requestId)
                                                  .update({
                                                    'status': 'declined',
                                                  });

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Trade Declined',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              print(
                                                'Error while declining trade: $e',
                                              );
                                            }
                                          },
                                          child: const Text(
                                            'Decline',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xfffd8536),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xff238855)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Decline",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        isTradeAccepted || isTradeDeclined
                            ? null // Disable button if trade is already accepted or declined
                            : () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Theme(
                                    data: ThemeData.light().copyWith(
                                      dialogBackgroundColor: Colors.white,
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xff238855,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text(
                                        'Confirm Accept',
                                        style: TextStyle(
                                          color: Color(0xff238855),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to accept this trade?',
                                        style: TextStyle(color: Colors.black87),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () async {
                                            await _handleAccept(context);
                                          },
                                          child: const Text(
                                            'Accept',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xfffd8536),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xfffd8536),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Accept",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
