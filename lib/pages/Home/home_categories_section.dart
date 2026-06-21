import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:glowfit/models/categorymodel.dart';
import 'package:glowfit/services/api.dart';
import 'package:glowfit/services/remoteconfig.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeCategoriesSection extends StatefulWidget {
  const HomeCategoriesSection({super.key});

  @override
  State<HomeCategoriesSection> createState() => _HomeCategoriesSectionState();
}

class _HomeCategoriesSectionState extends State<HomeCategoriesSection> {
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final raw = RemoteConfigService.getProductCategories();
      final ids = raw
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .where((e) => e != null)
          .cast<int>()
          .toList();

      final result = await APIService.fetchCategoriesByIds(ids);

      setState(() {
        _categories = [
          CategoryModel(
            id: 49,
            name: "All",
            image: "assets/images/gladskin-all.webp",
            parent: 0,
          ),
          ...result,
        ];
      });
    } catch (e) {
      debugPrint("❌ Home category error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_categories.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Shop by Category",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/AllProducts'),
                child: Row(
                  children: [
                    Text(
                      "View All",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6F0562),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Color(0xFF6F0562),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 95,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];

                return GestureDetector(
                  onTap: () => context.push('/AllProducts'),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 18),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 24,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade100,
                            child: ClipOval(
                              child: cat.image.startsWith('assets/')
                                  ? Image.asset(
                                      cat.image,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : cat.image.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: cat.image,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      placeholder: (ctx, url) => const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      errorWidget: (ctx, url, err) =>
                                          const Icon(Icons.category),
                                    )
                                  : const Icon(Icons.category),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
