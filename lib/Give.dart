import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/cloudinary_service.dart';
import 'dart:io';
import 'Homepage.dart';

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

  // Fields
  final List<String> foodTypes = [
    'Fruits',
    'Vegetables',
    'Canned Goods',
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xffffc533)),
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Capture from Camera'),
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
                leading: Icon(Icons.photo_library),
                title: Text('Select from Gallery'),
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
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donation uploaded successfully!')),
      );

      // Navigate back to Home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ), // Replace with your HomeScreen widget
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading donation')));
    }
  }

  Widget stepIndicator(int step, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor:
              _currentStep == step ? Color(0xffffc533) : Colors.grey[300],
          child: Text(
            label,
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: Text('Give', style: TextStyle(color: Colors.black)),
        backgroundColor: Color(0xffffc533),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step Indicator
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                stepIndicator(0, "1"),
                stepIndicator(1, "2"),
                stepIndicator(2, "3"),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(), // Disable swipe gestures
              children: [step1(), step2(), step3()],
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
                border: Border.all(color: Colors.black, width: 0.8),
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
                              color: Color(0xffffc533),
                            ),
                            SizedBox(height: 10),
                            Text(
                              "Add an Image",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xffffc533),
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
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 150, // Set a fixed width for the button
              child: ElevatedButton(
                onPressed:
                    selectedImage == null
                        ? null
                        : nextStep, // Disable if no image
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffffc533),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14), // Match size
                ),
                child: Text("Next", style: TextStyle(color: Colors.black)),
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
            ),
            const SizedBox(height: 15),

            // Food Name Input
            TextField(
              controller: nameController,
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
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Color(0xffffc533),
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
                          color: Color(0xffffc533),
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
                              ? Color(0xffffc533)
                              : Colors.white,
                      foregroundColor:
                          selectedOption == 'DROP-OFF'
                              ? Colors.white
                              : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Color(0xffffc533)),
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
                              ? Color(0xffffc533)
                              : Colors.white,
                      foregroundColor:
                          selectedOption == 'PICKUP'
                              ? Colors.white
                              : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Color(0xffffc533)),
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
                decoration: customInputDecoration(
                  "Pickup Location",
                  "Enter pickup location",
                ),
              ),
            const SizedBox(height: 20),

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
                        borderRadius: BorderRadius.circular(12),
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
                      backgroundColor: Color(0xffffc533),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14), // Match size
                    ),
                    child: Text(
                      "Next",
                      style: TextStyle(fontSize: 16, color: Colors.black),
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
                borderRadius: BorderRadius.circular(12),
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
            SizedBox(height: 20),

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
                        borderRadius: BorderRadius.circular(12),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffffc533),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14), // Match size
                    ),
                    child: Text(
                      "Give",
                      style: TextStyle(fontSize: 16, color: Colors.black),
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
