import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/cloudinary_service.dart';
import 'Profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _selectedImage;
  bool _isLoading = false;

  User? user = FirebaseAuth.instance.currentUser;
  String? currentImageUrl;

  final CloudinaryService _cloudinaryService = CloudinaryService();

  InputDecoration customInputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelStyle: const TextStyle(color: Color(0xff238855)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xff238855)),
        borderRadius: BorderRadius.circular(16),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get();

        if (userDoc.exists) {
          setState(() {
            _nameController.text = userDoc['name'] ?? '';
            currentImageUrl = userDoc['profileImage'];
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading user data')),
        );
      }
    }
  }

  Future<void> showImagePickerOptions() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xfffd8536)),
                title: const Text('Capture from Camera'),
                onTap: () async {
                  Navigator.pop(context); // Close the bottom sheet
                  await pickImage(ImageSource.camera);
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xfffd8536),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  Navigator.pop(context); // Close the bottom sheet
                  await pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Update the saveProfile method
  Future<void> saveProfile() async {
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = currentImageUrl;

      // If user picked a new image, upload it to Cloudinary
      if (_selectedImage != null) {
        imageUrl = await _cloudinaryService.uploadImage(_selectedImage!);
      }

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'name': _nameController.text.trim(),
            'profileImage': imageUrl,
          });

      if (mounted) {
        // Return to Profile screen with refresh flag
        Navigator.pop(context, true);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Color(0xff238855),
          ),
        );

        // Find and refresh the ProfileScreen
        final profileContext = Navigator.of(context);
        if (profileContext.canPop()) {
          // Pop back to Profile and trigger refresh
          final wasRefreshed = await profileContext.maybePop(true);
          if (!wasRefreshed && mounted) {
            // If direct pop didn't work, replace with fresh Profile
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(otherUserId: user!.uid),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: // Replace the existing AppBar with:
          AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: const Color(0xff238855),
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff238855)),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: showImagePickerOptions, // Show bottom sheet on tap
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage:
                            _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (currentImageUrl != null
                                    ? NetworkImage(currentImageUrl!)
                                        as ImageProvider
                                    : const AssetImage(
                                      'assets/default_avatar.png',
                                    )),
                        backgroundColor: Colors.grey[300],
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Color(0xff238855),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      cursorColor: const Color(0xff238855),
                      decoration: customInputDecoration('Full Name', ''),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    SizedBox(
                      // Wrap ElevatedButton with SizedBox
                      width: 150, // Set fixed width
                      child: ElevatedButton(
                        onPressed: saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xfffd8536),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
