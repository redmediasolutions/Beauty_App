
import 'package:flutter/material.dart';

class GalleryImage extends StatelessWidget {
  final String imageUrl;

  const GalleryImage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
     
      width: 100,
    
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.image_not_supported);
          },
        ),
      ),
    );
  }
}