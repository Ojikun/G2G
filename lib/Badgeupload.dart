import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/cloudinary_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const BadgeUploadApp());
}

class BadgeUploadApp extends StatelessWidget {
  const BadgeUploadApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Badge Upload',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const BadgeUploadScreen(),
    );
  }
}

class BadgeUploadScreen extends StatefulWidget {
  const BadgeUploadScreen({Key? key}) : super(key: key);

  @override
  State<BadgeUploadScreen> createState() => _BadgeUploadScreenState();
}

class _BadgeUploadScreenState extends State<BadgeUploadScreen> {
  final TextEditingController _badgeNameController = TextEditingController();
  final TextEditingController _badgeIndexController = TextEditingController();
  final CloudinaryService _cloudinaryService = CloudinaryService();
  File? _selectedBadgeImage;
  File? _selectedPlaceholderImage;
  bool _isUploading = false;

  Future<void> pickBadgeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedBadgeImage = File(pickedFile.path);
      });
    }
  }

  Future<void> pickPlaceholderImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedPlaceholderImage = File(pickedFile.path);
      });
    }
  }

  Future<void> uploadBadge() async {
    final badgeName = _badgeNameController.text.trim();
    final badgeIndex = int.tryParse(_badgeIndexController.text.trim());

    if (badgeName.isEmpty ||
        badgeIndex == null ||
        _selectedBadgeImage == null ||
        _selectedPlaceholderImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide all required fields')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload badge image to Cloudinary
      final badgeUrl = await _cloudinaryService.uploadImage(
        _selectedBadgeImage!,
      );

      if (badgeUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload badge image')),
        );
        return;
      }

      // Upload placeholder image to Cloudinary
      final placeholderUrl = await _cloudinaryService.uploadImage(
        _selectedPlaceholderImage!,
      );

      if (placeholderUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload placeholder image')),
        );
        return;
      }

      // Save badge data to Firestore
      await FirebaseFirestore.instance.collection('badges').add({
        'badgeUrl': badgeUrl, // URL of the uploaded badge image
        'index': badgeIndex, // Index of the badge (0-14)
        'placeholder': placeholderUrl, // URL of the uploaded placeholder image
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Badge uploaded successfully')),
      );

      // Clear the form
      _badgeNameController.clear();
      _badgeIndexController.clear();
      setState(() {
        _selectedBadgeImage = null;
        _selectedPlaceholderImage = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Badge'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: pickBadgeImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _selectedBadgeImage != null
                        ? FileImage(_selectedBadgeImage!)
                        : null,
                backgroundColor: Colors.grey[300],
                child:
                    _selectedBadgeImage == null
                        ? const Icon(
                          Icons.add_a_photo,
                          size: 30,
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Badge Image',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: pickPlaceholderImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage:
                    _selectedPlaceholderImage != null
                        ? FileImage(_selectedPlaceholderImage!)
                        : null,
                backgroundColor: Colors.grey[300],
                child:
                    _selectedPlaceholderImage == null
                        ? const Icon(
                          Icons.add_a_photo,
                          size: 30,
                          color: Colors.white,
                        )
                        : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Placeholder Image',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _badgeNameController,
              decoration: const InputDecoration(
                labelText: 'Badge Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _badgeIndexController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Badge Index (0-14)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : uploadBadge,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child:
                  _isUploading
                      ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                      : const Text('Upload Badge'),
            ),
          ],
        ),
      ),
    );
  }
}
