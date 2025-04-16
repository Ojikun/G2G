import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';

class ImageUploadPage extends StatefulWidget {
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  final picker = ImagePicker();
  final cloudinaryService = CloudinaryService();
  File? _imageFile;
  String? imageUrl;
  bool _isUploading = false;

  // Method to pick an image from gallery or camera
  Future pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // Upload image to Cloudinary
      setState(() {
        _isUploading = true;
      });

      final uploadedUrl = await cloudinaryService.uploadImage(_imageFile!);

      setState(() {
        imageUrl = uploadedUrl;
        _isUploading = false;
      });

      if (uploadedUrl != null) {
        print('Image URL: $uploadedUrl');
      } else {
        print('Failed to upload image');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload to Cloudinary')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the selected image
            if (_imageFile != null) Image.file(_imageFile!, height: 200),
            const SizedBox(height: 20),
            // Buttons for picking image
            ElevatedButton(
              onPressed: () => pickImage(ImageSource.gallery),
              child: Text('Pick from Gallery'),
            ),
            ElevatedButton(
              onPressed: () => pickImage(ImageSource.camera),
              child: Text('Take a Photo'),
            ),
            const SizedBox(height: 20),
            // Display uploaded image URL
            if (_isUploading) CircularProgressIndicator(),
            if (imageUrl != null && !_isUploading)
              Text(
                'Image uploaded!\n$imageUrl',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }
}
