import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class Shopcategory extends StatelessWidget {
  final bool visible;

  const Shopcategory(this.visible, {super.key});

  @override
  Widget build(BuildContext context) {
      final categories = [
    {'name': 'Serums', 'count': '12 Products', 'image': 'https://www.drsheths.com/cdn/shop/files/1_Website.jpg?v=1746015642'},
    {'name': 'Moisturizers', 'count': '8 Products', 'image': 'https://vibrantskinbar.com/wp-content/uploads/what-is-moisturizer.jpg'},
    {'name': 'Cleansers', 'count': '6 Products', 'image': 'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?q=80&w=400'},
    {'name': 'Masks', 'count': '5 Products', 'image': 'https://wowbeauty.co/wp-content/uploads/2023/10/face-mask-web.webp'},
  ];
  
    return Padding(
    padding: const EdgeInsets.symmetric(vertical: 40.0), 
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Text(
            "Shop by Category",
            style: GoogleFonts.tenorSans(
              fontSize: 32,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ).animate(target: visible ? 1 : 0).fadeIn().slideX(begin: -0.1),
        ),
        const SizedBox(height: 25),
        SizedBox(
          height: 180, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 25), 
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return Container(
                width: 150, 
                margin: const EdgeInsets.only(right: 15), 
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(categories[index]['image']!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.35), 
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categories[index]['name']!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categories[index]['count']!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ).animate(target: visible ? 1 : 0)
               .fadeIn(delay: (100 * index).ms)
               .moveX(begin: 20, end: 0); // Subtle staggered slide-in
            },
          ),
        ),
      ],
    ),
  );
  }
}
