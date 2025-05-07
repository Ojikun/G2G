import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/cloudinary_service.dart';
import 'services/trade_service.dart';
import 'widgets/full_screen_image.dart';
import 'Homepage.dart';
import 'Profile.dart';

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

  InputDecoration customInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelStyle: TextStyle(
        color: Color(0xff238855), // Focused label text color
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xff238855)),
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

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
                                        color: Color(0xff238855),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _submitTrade,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xfffd8536),
                                      ),
                                      child: Text(
                                        'Post',
                                        style: TextStyle(color: Colors.white),
                                      ),
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
                                      backgroundColor: Color(0xff238855),
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
                                  cursorColor: Color(
                                    0xff238855,
                                  ), // Set the cursor color
                                  decoration: InputDecoration(
                                    hintText: 'Say something...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color(
                                          0xff238855,
                                        ), // Set the focused border color
                                        width: 2,
                                      ),
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
                                  cursorColor: Color(
                                    0xff238855,
                                  ), // Set the cursor color
                                  decoration: InputDecoration(
                                    labelText: 'Food Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color(
                                          0xff238855,
                                        ), // Set the focused border color
                                        width: 2,
                                      ),
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
                                  cursorColor: Color(
                                    0xff238855,
                                  ), // Set the cursor color
                                  decoration: InputDecoration(
                                    labelText: 'Quantity',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Color(
                                          0xff238855,
                                        ), // Set the focused border color
                                        width: 2,
                                      ),
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
                                  readOnly: true, // Prevent manual input
                                  decoration: customInputDecoration(
                                    "Expiry Date",
                                    "MM/DD/YYYY",
                                  ),
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          DateTime.now(), // Set the initial date to today
                                      firstDate:
                                          DateTime.now(), // Prevent selecting past dates
                                      lastDate: DateTime(
                                        2100,
                                      ), // Set an upper limit for the date
                                      builder: (
                                        BuildContext context,
                                        Widget? child,
                                      ) {
                                        return Theme(
                                          data: ThemeData.light().copyWith(
                                            primaryColor: Color(
                                              0xff238855,
                                            ), // Header background color
                                            textButtonTheme:
                                                TextButtonThemeData(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Color(
                                                      0xff238855,
                                                    ), // Button text color
                                                  ),
                                                ),
                                            dialogBackgroundColor:
                                                Colors
                                                    .white, // Background color of the dialog
                                            colorScheme: ColorScheme.light(
                                              primary: Color(
                                                0xff238855,
                                              ), // Header text and selected date color
                                              onPrimary:
                                                  Colors
                                                      .white, // Text color on header
                                              onSurface:
                                                  Colors
                                                      .black, // Text color on calendar
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );

                                    if (pickedDate != null) {
                                      setState(() {
                                        _expiryController.text =
                                            "${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.year}";
                                      });
                                    }
                                  },
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
                                      backgroundColor: Colors.white,
                                      builder: (BuildContext context) {
                                        return SafeArea(
                                          child: Wrap(
                                            children: [
                                              ListTile(
                                                leading: Icon(
                                                  Icons.camera_alt,
                                                  color: Color(0xfffd8536),
                                                ),
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
                                                  color: Color(0xfffd8536),
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
                                                    color: Color(0xfffd8536),
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
                              // Top Bar with Back Button, Title, and Save Button
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
                                      'Edit Trade Post',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xff238855),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        final updatedDescription =
                                            _tradeController.text.trim();
                                        final updatedFoodName =
                                            _foodNameController.text.trim();
                                        final updatedQuantity =
                                            _quantityController.text.trim();
                                        final updatedExpiry =
                                            _expiryController.text.trim();

                                        if (updatedDescription.isEmpty ||
                                            updatedFoodName.isEmpty ||
                                            updatedQuantity.isEmpty ||
                                            updatedExpiry.isEmpty) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Please fill in all fields',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        // Update Firestore document
                                        await FirebaseFirestore.instance
                                            .collection('trades')
                                            .doc(docId)
                                            .update({
                                              'description': updatedDescription,
                                              'foodName': updatedFoodName,
                                              'quantity': updatedQuantity,
                                              'expiry': updatedExpiry,
                                            });

                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xfffd8536),
                                      ),
                                      child: Text(
                                        'Save',
                                        style: TextStyle(color: Colors.white),
                                      ),
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
                                  controller: _tradeController,
                                  maxLines: 5,
                                  cursorColor: Color(0xff238855),
                                  decoration: customInputDecoration(
                                    "Trade Description",
                                    "Edit your trade description...",
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
                                  cursorColor: Color(0xff238855),
                                  decoration: customInputDecoration(
                                    "Food Name",
                                    "Edit the food name",
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
                                  cursorColor: Color(0xff238855),
                                  decoration: customInputDecoration(
                                    "Quantity",
                                    "Edit the quantity",
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
                                  decoration: customInputDecoration(
                                    "Expiry Date",
                                    "MM/DD/YYYY",
                                  ),
                                  onTap: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                      builder: (
                                        BuildContext context,
                                        Widget? child,
                                      ) {
                                        return Theme(
                                          data: ThemeData.light().copyWith(
                                            primaryColor: Color(0xff238855),
                                            textButtonTheme:
                                                TextButtonThemeData(
                                                  style: TextButton.styleFrom(
                                                    foregroundColor: Color(
                                                      0xff238855,
                                                    ),
                                                  ),
                                                ),
                                            dialogBackgroundColor: Colors.white,
                                            colorScheme: ColorScheme.light(
                                              primary: Color(0xff238855),
                                              onPrimary: Colors.white,
                                              onSurface: Colors.black,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );

                                    if (pickedDate != null) {
                                      setModalState(() {
                                        _expiryController.text =
                                            "${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.year}";
                                      });
                                    }
                                  },
                                ),
                              ),
                              SizedBox(height: 16),

                              // Image Preview
                              if (oldImageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      oldImageUrl,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.broken_image,
                                            size: 150,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false, // Remove all previous routes
            );
          },
        ),
        title: Text(
          'Trade',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color(0xff238855),
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
            backgroundColor: Color(0xff238855),
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
            icon: Icon(Icons.image, color: Color(0xfffd8536)),
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
                GestureDetector(
                  onTap: () {
                    // Navigate to the ProfileScreen of the specific user
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ProfileScreen(otherUserId: postUid),
                      ),
                    );
                  },
                  child: FutureBuilder<DocumentSnapshot>(
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
                        backgroundColor: Color(0xff238855),
                        child:
                            profileImageUrl == null
                                ? Icon(Icons.person, color: Colors.white)
                                : null,
                      );
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to the ProfileScreen of the specific user
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ProfileScreen(otherUserId: postUid),
                        ),
                      );
                    },
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: Colors.grey[800]),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.white,
                        builder: (context) {
                          return SafeArea(
                            child: Wrap(
                              children: [
                                ListTile(
                                  leading: Icon(
                                    Icons.edit,
                                    color: Color(0xff238855),
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
                                    color: Color(0xfffd8536),
                                  ),
                                  title: Text('Delete Trade'),
                                  onTap: () async {
                                    Navigator.pop(context); // Close the modal
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (context) => AlertDialog(
                                            backgroundColor:
                                                Colors
                                                    .white, // Set the background color to white
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    16,
                                                  ), // Add rounded corners
                                            ),
                                            title: Text(
                                              'Delete Trade',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color:
                                                    Colors
                                                        .black, // Set title text color to black
                                              ),
                                            ),
                                            content: Text(
                                              'Are you sure you want to delete this trade?',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color:
                                                    Colors
                                                        .black87, // Set content text color to a darker shade
                                              ),
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
                                                    color:
                                                        Colors
                                                            .grey, // Set "Cancel" button text color to grey
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
                                                    color: Color(
                                                      0xfffd8536,
                                                    ), // Set "Delete" button text color to orange
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
                          'assets/tradebutton.png', // Path to your trade icon
                          height: 35,
                          width: 35,
                          color:
                              isTradeSubmitted
                                  ? Color(0xfffd8536)
                                  // Change to green if submitted
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
