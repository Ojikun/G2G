import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/cloudinary_service.dart';
import 'dart:io';

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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(50),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.teal),
        borderRadius: BorderRadius.circular(50),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
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
        'username': username, // ✅ added here
        'status': 'available',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Donation uploaded successfully!')),
      );

      setState(() {
        selectedFoodType = null;
        quantity = 0;
        selectedOption = '';
        selectedImage = null;
      });

      nameController.clear();
      expiryController.clear();
      noteController.clear();
      locationController.clear();
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading donation')));
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        selectedImage = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.person),
                SizedBox(width: 42),
                Text(
                  "G2G",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(width: 40),
                Icon(Icons.mail),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child:
                    selectedImage == null
                        ? Center(
                          child: Icon(
                            Icons.add_a_photo,
                            size: 60,
                            color: Colors.grey,
                          ),
                        )
                        : Image.file(
                          File(selectedImage!.path),
                          fit: BoxFit.cover,
                        ),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedFoodType,
              hint: Text('Food Type'),
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
              decoration: customInputDecoration("", "Food Type"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: customInputDecoration("Name", "Food Name Here"),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: expiryController,
              keyboardType: TextInputType.number,
              inputFormatters: [DateTextFormatter()],
              decoration: customInputDecoration("Expiry", "MM/DD/YYYY"),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(50),
                color: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Quantity'),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          setState(() {
                            if (quantity > 0) quantity--;
                          });
                        },
                      ),
                      Text(quantity.toString(), style: TextStyle(fontSize: 16)),
                      IconButton(
                        icon: Icon(Icons.add_circle_outline),
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
            TextField(
              controller: noteController,
              decoration: customInputDecoration(
                "Note",
                "Additional details here",
              ),
            ),
            const SizedBox(height: 15),
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
                              ? Colors.teal
                              : Colors.white,
                      foregroundColor:
                          selectedOption == 'DROP-OFF'
                              ? Colors.white
                              : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.teal),
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
                              ? Colors.teal
                              : Colors.white,
                      foregroundColor:
                          selectedOption == 'PICKUP'
                              ? Colors.white
                              : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.teal),
                    ),
                    child: const Text("PICKUP"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (selectedOption == 'PICKUP')
              TextField(
                controller: locationController,
                decoration: customInputDecoration(
                  "Location",
                  "Enter pickup location",
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadDonation,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
              child: const Text(
                'Post Donation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
