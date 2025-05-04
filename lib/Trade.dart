import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/cloudinary_service.dart';
import 'services/trade_service.dart';
import 'widgets/full_screen_image.dart';
import 'Homepage.dart';

class TradeHomePage extends StatefulWidget {
  @override
  _TradeHomePageState createState() => _TradeHomePageState();
}

class _TradeHomePageState extends State<TradeHomePage> {
  final TextEditingController _tradeController = TextEditingController();
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  File? _selectedImage;
  String? _currentUserId;
  String? _profileImageUrl;
  String? _username;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _fetchUserProfileImage();
  }

  Future<void> _fetchUserProfileImage() async {
    if (_currentUserId == null) return;
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .get();
    setState(() {
      _profileImageUrl = userDoc.data()?['profileImage'];
      _username = userDoc.data()?['name'] ?? 'Anonymous';
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(
          picked.path,
        ); // Update the state with the new image
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
    final foodName = _foodNameController.text.trim();
    final quantity = _quantityController.text.trim();
    final expiry = _expiryController.text.trim();

    if (tradeText.isEmpty ||
        foodName.isEmpty ||
        quantity.isEmpty ||
        expiry.isEmpty) {
      // Show an error if any required field is empty
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    final username = await _getUsername();

    String? uploadedImageUrl;
    if (_selectedImage != null) {
      uploadedImageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
    }

    final docRef = FirebaseFirestore.instance.collection('trades').doc();

    await docRef.set({
      'docId': docRef.id,
      'username': username,
      'description': tradeText,
      'foodName': foodName,
      'quantity': quantity,
      'expiry': expiry,
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': uploadedImageUrl,
      'uid': _currentUserId,
    });

    // Clear the input fields and reset the state
    _tradeController.clear();
    _foodNameController.clear();
    _quantityController.clear();
    _expiryController.clear();
    setState(() {
      _selectedImage = null;
    });

    // Close the modal
    Navigator.pop(context);
  }

  void _showFullScreenOverlay() {
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
                              // Top Bar with Back Button, Title, and Post Button
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
                                        setState(() {
                                          _tradeController.clear();
                                          _foodNameController.clear();
                                          _quantityController.clear();
                                          _expiryController.clear();
                                          _selectedImage = null;
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                    Text(
                                      'Create Trade Post',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _submitTrade,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xffffc533),
                                      ),
                                      child: Text('Post'),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(thickness: 1, color: Colors.grey[300]),

                              // User Info Section
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          _profileImageUrl != null
                                              ? NetworkImage(_profileImageUrl!)
                                              : null,
                                      backgroundColor: Color(0xffffc533),
                                      child:
                                          _profileImageUrl == null
                                              ? Icon(
                                                Icons.person,
                                                color: Colors.white,
                                              )
                                              : null,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      _username ??
                                          'Anonymous', // Display username instantly
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),

                              // Text Area
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: TextField(
                                  controller: _tradeController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText: 'Say something...',
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
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return SafeArea(
                                          child: Wrap(
                                            children: [
                                              ListTile(
                                                leading: Icon(Icons.camera_alt),
                                                title: Text(
                                                  'Capture from Camera',
                                                ),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  final picker = ImagePicker();
                                                  final picked = await picker
                                                      .pickImage(
                                                        source:
                                                            ImageSource.camera,
                                                      );
                                                  if (picked != null) {
                                                    setModalState(() {
                                                      _selectedImage = File(
                                                        picked.path,
                                                      );
                                                    });
                                                  }
                                                },
                                              ),
                                              ListTile(
                                                leading: Icon(
                                                  Icons.photo_library,
                                                ),
                                                title: Text(
                                                  'Select from Gallery',
                                                ),
                                                onTap: () async {
                                                  Navigator.pop(context);
                                                  final picker = ImagePicker();
                                                  final picked = await picker
                                                      .pickImage(
                                                        source:
                                                            ImageSource.gallery,
                                                      );
                                                  if (picked != null) {
                                                    setModalState(() {
                                                      _selectedImage = File(
                                                        picked.path,
                                                      );
                                                    });
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
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

  void _showFullScreenOverlayForEdit({
    required String docId,
    required String oldDescription,
    required String oldFoodName,
    required String oldQuantity,
    required String oldExpiry,
    String? oldImageUrl,
  }) {
    _tradeController.text = oldDescription;
    _foodNameController.text = oldFoodName;
    _quantityController.text = oldQuantity;
    _expiryController.text = oldExpiry;
    _selectedImage = oldImageUrl != null ? File(oldImageUrl) : null;

    _showFullScreenOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false, // Remove all previous routes
            );
          },
        ),
        title: Text('Trade', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xffffc533),
      ),
      body: Stack(
        children: [
          // Scrollable trade list
          Padding(
            padding: EdgeInsets.only(top: 80), // Leave space for the fixed card
            child: _buildTradeList(),
          ),

          // Fixed trade card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildCreateTradeSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTradeSection() {
    return Container(
      height: 80, // Set a fixed height for the container
      padding: EdgeInsets.all(16),
      color: Colors.white,

      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage:
                _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
            backgroundColor: Color(0xffffc533),
            child:
                _profileImageUrl == null
                    ? Icon(Icons.person, color: Colors.white)
                    : null,
          ),
          SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _showFullScreenOverlay,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Create a trade post...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.image, color: Color(0xffffc533)),
            onPressed: _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _buildTradeList() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('trades')
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final trades = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.all(0),
          itemCount: trades.length,
          itemBuilder: (context, index) {
            final data = trades[index].data() as Map<String, dynamic>;
            return _buildTradeCard(
              docId: trades[index].id,
              username: data['username'] ?? 'Anonymous',
              description: data['description'] ?? '',
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              foodName: data['foodName'] ?? 'N/A',
              quantity: data['quantity'] ?? 'N/A',
              expiry: data['expiry'] ?? 'N/A',
              imageUrl: data['imageUrl'],
              postUid: data['uid'],
            );
          },
        );
      },
    );
  }

  Widget _buildTradeCard({
    required String docId,
    required String username,
    required String description,
    required DateTime timestamp,
    required String foodName,
    required String quantity,
    required String expiry,
    String? imageUrl, // Image of the food item
    required String postUid,
  }) {
    final isOwner = _currentUserId == postUid;
    // final showTradeButton = _currentUserId != null && !isOwner;

    String timeAgo(DateTime date) {
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar, name, timestamp, and actions
            Row(
              children: [
                FutureBuilder<DocumentSnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(postUid)
                          .get(),
                  builder: (context, snapshot) {
                    String? profileImageUrl;

                    if (snapshot.hasData && snapshot.data != null) {
                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      profileImageUrl = userData?['profileImage'];
                    }

                    return CircleAvatar(
                      radius: 24,
                      backgroundImage:
                          profileImageUrl != null
                              ? NetworkImage(profileImageUrl)
                              : null,
                      backgroundColor: Color(0xffffc533),
                      child:
                          profileImageUrl == null
                              ? Icon(Icons.person, color: Colors.white)
                              : null,
                    );
                  },
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        timeAgo(timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: Colors.grey[800]),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.edit,
                                    color: Color(0xffffc533),
                                  ),
                                  title: Text('Edit Trade'),
                                  onTap: () {
                                    Navigator.pop(context); // Close the modal
                                    _showFullScreenOverlayForEdit(
                                      docId: docId,
                                      oldDescription: description,
                                      oldFoodName: foodName,
                                      oldQuantity: quantity,
                                      oldExpiry: expiry,
                                      oldImageUrl: imageUrl,
                                    );
                                  },
                                ),
                                ListTile(
                                  leading: Icon(
                                    Icons.delete,
                                    color: Colors.black,
                                  ),
                                  title: Text('Delete Trade'),
                                  onTap: () async {
                                    Navigator.pop(context); // Close the modal
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
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                child: Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color: Color(0xffffc533),
                                                  ),
                                                ),
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
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
            SizedBox(height: 8),
            Divider(thickness: 1, color: Colors.grey[300]),
            // Description
            Text(description, style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),

            // Details Section
            Text(
              'Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text('Name: $foodName', style: TextStyle(fontSize: 14)),
            Text('Quantity: $quantity', style: TextStyle(fontSize: 14)),
            Text('Expiration Date: $expiry', style: TextStyle(fontSize: 14)),
            SizedBox(height: 8),

            if (imageUrl != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => FullScreenImageView(imageUrl: imageUrl),
                    ),
                  );
                },
                child: Hero(
                  tag: imageUrl,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              Icon(Icons.broken_image, size: 150),
                    ),
                  ),
                ),
              ),
            Divider(thickness: 1, color: Colors.grey[300]),
            // Trade Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Trade Request Count (Left)
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('trades')
                          .doc(docId)
                          .collection('tradeRequests')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Text(
                        'Trade requests: 0',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      );
                    }
                    final tradeRequestCount = snapshot.data!.docs.length;
                    return Text(
                      'Trade requests: $tradeRequestCount',
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    );
                  },
                ),

                // Trade Icon (Right)
                if (!isOwner)
                  StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('trades')
                            .doc(docId)
                            .collection('tradeRequests')
                            .where('uid', isEqualTo: _currentUserId)
                            .snapshots(),
                    builder: (context, snapshot) {
                      final isTradeSubmitted =
                          snapshot.hasData && snapshot.data!.docs.isNotEmpty;

                      return IconButton(
                        icon: Image.asset(
                          'assets/Trade.png', // Path to your trade icon
                          height: 35,
                          width: 35,
                          color:
                              isTradeSubmitted
                                  ? Color(
                                    0xffffc533,
                                  ) // Change to green if submitted
                                  : null, // Default color
                        ),
                        onPressed: () async {
                          if (!isTradeSubmitted) {
                            final TradeService tradeService = TradeService();
                            await tradeService.showTradeRequestOverlay(
                              context: context,
                              tradePostId: docId, // Pass the trade post ID
                            );
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
