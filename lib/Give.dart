import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/cloudinary_service.dart';
import 'dart:io';
import 'Homepage.dart';
import 'services/badge_service.dart';

class DateTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    text = text.replaceAll(RegExp(r'[^0-9]'), '');

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(text[i]);
    }

    final formatted = buffer.toString().substring(
      0,
      buffer.length > 10 ? 10 : buffer.length,
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class GiveFoodPage extends StatefulWidget {
  @override
  _GiveFoodPageState createState() => _GiveFoodPageState();
}

class _GiveFoodPageState extends State<GiveFoodPage> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool isLoading = false; // To show the loading spinner
  bool showThankYou = false; // To show the thank-you animation

  // Fields
  final List<String> foodTypes = [
    'Fruits',
    'Vegetables',
    'Grains & Bread',
    'Canned Goods',
    'Dairy & Alternatives',
    'Proteins',
    'Snacks & Sweets',
    'Beverages',
    'Prepared Meals',
    'Others',
  ];
  String? selectedFoodType;
  int quantity = 0;
  String selectedOption = '';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? selectedImage;

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

  void nextStep() {
    if (_currentStep < 2) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white, // Set the bottom sheet background color to white
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Color(0xfffd8536), // Set the icon color
                ),
                title: Text(
                  'Capture from Camera',
                  style: TextStyle(
                    color: Colors.grey[700], // Set the text color to grey[700]
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close the bottom sheet
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    setState(() {
                      selectedImage = image;
                    });
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Color(0xfffd8536), // Set the icon color
                ),
                title: Text(
                  'Select from Gallery',
                  style: TextStyle(
                    color: Colors.grey[700], // Set the text color to grey[700]
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close the bottom sheet
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() {
                      selectedImage = image;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> uploadDonation() async {
    if (selectedFoodType == null ||
        nameController.text.isEmpty ||
        expiryController.text.isEmpty ||
        quantity <= 0 ||
        selectedOption.isEmpty ||
        locationController.text.isEmpty ||
        selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    try {
      // Show loading spinner
      setState(() {
        isLoading = true; // Add a loading state
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not logged in')));
        return;
      }

      final String username = user.displayName ?? user.email ?? 'Anonymous';

      var cloudinaryService = CloudinaryService();
      String? imageUrl = await cloudinaryService.uploadImage(
        File(selectedImage!.path),
      );

      await FirebaseFirestore.instance.collection('donations').add({
        'foodType': selectedFoodType,
        'name': nameController.text,
        'expiry': expiryController.text,
        'quantity': quantity,
        'option': selectedOption,
        'note': noteController.text,
        'location': locationController.text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user.uid,
        'userEmail': user.email,
        'username': username,
        'status': 'available',
      });

      await BadgeService.checkAndAwardBadges(context, user.uid);

      setState(() {
        isLoading = false;
        showThankYou = true; // Show the thank-you animation
      });

      // Wait for a few seconds before navigating back to the home screen
      await Future.delayed(Duration(seconds: 3));

      setState(() {
        showThankYou = false; // Hide the thank-you animation
      });

      // Navigate back to Home
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading donation: ${e.toString()}')),
        );
      }
    }
  }

  Widget stepIndicator(int step, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor:
              _currentStep == step ? Color(0xfffd8536) : Colors.grey[300],
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 8),
        Text(
          step == 0
              ? "Add Image"
              : step == 1
              ? "Details"
              : "Confirm",
          style: TextStyle(
            fontSize: 12,
            color: _currentStep == step ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget stepIndicatorWithConnector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Step 1
          stepIndicator(0, "1"),
          // Connector
          Expanded(
            child: Container(
              height: 3,
              color: _currentStep >= 1 ? Color(0xfffd8536) : Colors.grey[300],
            ),
          ),
          // Step 2
          stepIndicator(1, "2"),
          // Connector
          Expanded(
            child: Container(
              height: 3,
              color: _currentStep >= 2 ? Color(0xfffd8536) : Colors.grey[300],
            ),
          ),
          // Step 3
          stepIndicator(2, "3"),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false,
            );
          },
        ),
        title: Text(
          'Give',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color(0xff238855),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Step Indicator with Connectors
              stepIndicatorWithConnector(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics:
                      NeverScrollableScrollPhysics(), // Disable swipe gestures
                  children: [step1(), step2(), step3()],
                ),
              ),
            ],
          ),

          // Loading Spinner
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(
                0.5,
              ), // Semi-transparent background
              child: Center(
                child: CircularProgressIndicator(color: Color(0xff238855)),
              ),
            ),

          // Thank-You Animation
          if (showThankYou)
            Container(
              color: Colors.black.withOpacity(
                0.5,
              ), // Semi-transparent background
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Image
                    AnimatedScale(
                      scale: 1.0,
                      duration: Duration(seconds: 1),
                      curve: Curves.easeInOut,
                      child: Image.asset(
                        'assets/thankyou.png', // Replace with your asset path
                        height: 300,
                        width: 300,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Text(
                    //   "Thank you for giving!",
                    //   style: TextStyle(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.white,
                    //   ),
                    //   textAlign: TextAlign.center,
                    // ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget step1() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Color(0xff238855), width: 0.8),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.2),
              ),
              child:
                  selectedImage == null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Color(0xfffd8536),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Add an Image",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(selectedImage!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
            ),
          ),
          SizedBox(height: 20),
          // "Next" Button in Step 1
          Spacer(), // Pushes the button to the bottom
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 150, // Set a fixed width for the button
              child: ElevatedButton(
                onPressed: selectedImage == null ? null : nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xfffd8536),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14), // Match size
                ),
                child: Text("Next", style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget step2() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Food Type Dropdown
            DropdownButtonFormField<String>(
              value: selectedFoodType,
              hint: Text('Select Food Type'),
              items:
                  foodTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedFoodType = value;
                });
              },
              decoration: customInputDecoration(
                "Food Type",
                "Select Food Type",
              ),
              dropdownColor: Colors.white,
            ),
            const SizedBox(height: 15),

            // Food Name Input
            TextField(
              controller: nameController,
              cursorColor: Color(0xff238855),
              decoration: customInputDecoration("Food Name", "Enter food name"),
            ),
            const SizedBox(height: 15),

            // Expiry Date Picker
            TextField(
              controller: expiryController,
              readOnly: true, // Prevent manual input
              decoration: customInputDecoration("Expiry Date", "MM/DD/YYYY"),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(), // Set the initial date to today
                  firstDate: DateTime.now(), // Prevent selecting past dates
                  lastDate: DateTime(2100), // Set an upper limit for the date
                  builder: (BuildContext context, Widget? child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: Color(
                          0xff238855,
                        ), // Header background color
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Color(
                              0xff238855,
                            ), // Button text color
                          ),
                        ),
                        dialogBackgroundColor:
                            Colors.white, // Background color of the dialog
                        colorScheme: ColorScheme.light(
                          primary: Color(
                            0xff238855,
                          ), // Header text and selected date color
                          onPrimary: Colors.white, // Text color on header
                          onSurface: Colors.black, // Text color on calendar
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (pickedDate != null) {
                  setState(() {
                    expiryController.text =
                        "${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.year}";
                  });
                }
              },
            ),
            const SizedBox(height: 15),

            // Quantity Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity', style: TextStyle(fontSize: 16)),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Color(0xfffd8536),
                        ),
                        onPressed: () {
                          setState(() {
                            if (quantity > 0) quantity--;
                          });
                        },
                      ),
                      Text(
                        quantity.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.add_circle_outline,
                          color: Color(0xfffd8536),
                        ),
                        onPressed: () {
                          setState(() {
                            quantity++;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Note Input
            TextField(
              controller: noteController,
              cursorColor: Color(0xff238855),
              decoration: customInputDecoration(
                "Note",
                "Additional details here",
              ),
            ),
            const SizedBox(height: 15),

            // Drop-Off or Pickup Options
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedOption = 'DROP-OFF';
                        locationController.text =
                            'Batangas State University - Alangilan Campus';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedOption == 'DROP-OFF'
                              ? Color(0xfffd8536)
                              : Colors.white,
                      foregroundColor:
                          selectedOption == 'DROP-OFF'
                              ? Colors.white
                              : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: Color(0xfffd8536)),
                    ),
                    child: const Text("DROP-OFF"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedOption = 'PICKUP';
                        locationController.text = '';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedOption == 'PICKUP'
                              ? Color(0xfffd8536)
                              : Colors.white,
                      foregroundColor:
                          selectedOption == 'PICKUP'
                              ? Colors.white
                              : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: Color(0xfffd8536)),
                    ),
                    child: const Text("PICKUP"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Location Input (Only for Pickup)
            if (selectedOption == 'PICKUP')
              TextField(
                controller: locationController,
                cursorColor: Color(0xff238855),
                decoration: customInputDecoration(
                  "Pickup Location",
                  "Enter pickup location",
                ),
              ),
            const SizedBox(height: 83),

            // Navigation Buttons
            // Step 2 Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: previousStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Color(0xff238855)),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Back",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedFoodType == null ||
                          nameController.text.isEmpty ||
                          expiryController.text.isEmpty ||
                          quantity <= 0 ||
                          selectedOption.isEmpty ||
                          (selectedOption == 'PICKUP' &&
                              locationController.text.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please fill in all fields')),
                        );
                        return;
                      }
                      nextStep();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xfffd8536),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      "Next",
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

  Widget step3() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Confirm Details",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // Details Container
            Container(
              padding: const EdgeInsets.all(16.0),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Image
                  if (selectedImage != null)
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(selectedImage!.path),
                          height: 150,
                          width: 150,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (selectedImage != null) SizedBox(height: 20),

                  // Display Food Type
                  Text(
                    "Food Type: ${selectedFoodType ?? 'Not selected'}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  // Display Food Name
                  Text(
                    "Food Name: ${nameController.text.isNotEmpty ? nameController.text : 'Not provided'}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  // Display Expiry Date
                  Text(
                    "Expiry Date: ${expiryController.text.isNotEmpty ? expiryController.text : 'Not provided'}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  // Display Quantity
                  Text(
                    "Quantity: ${quantity > 0 ? quantity.toString() : 'Not provided'}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  // Display Note
                  Text(
                    "Note: ${noteController.text.isNotEmpty ? noteController.text : 'Not provided'}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  // Display Drop-Off or Pickup Option
                  Text(
                    "Option: ${selectedOption.isNotEmpty ? selectedOption : 'Not selected'}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  // Display Location (if Pickup is selected)
                  if (selectedOption == 'PICKUP')
                    Text(
                      "Pickup Location: ${locationController.text.isNotEmpty ? locationController.text : 'Not provided'}",
                      style: TextStyle(fontSize: 16),
                    ),
                ],
              ),
            ),
            SizedBox(height: 98),

            // Buttons Row
            // Step 3 Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: previousStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Color(0xff238855)),
                      ),
                      // side: BorderSide(color: Colors.grey), // Add border
                      padding: EdgeInsets.symmetric(vertical: 14), // Match size
                    ),
                    child: Text(
                      "Back",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(width: 10), // Add spacing between buttons
                Expanded(
                  child: ElevatedButton(
                    onPressed: uploadDonation,
                    // After successful donation
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xfffd8536),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14), // Match size
                    ),
                    child: Text(
                      "Give",
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
