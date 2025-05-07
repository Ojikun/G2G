import 'package:flutter/material.dart';

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({Key? key, required this.imageUrl})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // InteractiveViewer for zooming
          InteractiveViewer(
            minScale: 0.5, // Allow zooming out
            maxScale: 4.0, // Allow zooming in
            child: Center(
              child: Hero(
                tag: imageUrl,
                child: Image.network(
                  imageUrl,
                  fit:
                      BoxFit
                          .contain, // Ensure the image adapts to its original size
                  errorBuilder:
                      (context, error, stackTrace) => Icon(
                        Icons.broken_image,
                        size: 150,
                        color: Color(0xff238855),
                      ),
                ),
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.close, color: Color(0xff238855), size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
