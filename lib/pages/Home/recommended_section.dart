import 'package:flutter/material.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:glowfit/services/api.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class RecommendedSection extends StatelessWidget {
  final String categoryId;

  const RecommendedSection({super.key, required this.categoryId});

  String _formatPrice(double? price) {
    if (price == null) return "--";
    return price.toStringAsFixed(0);
  }

  String _stripHtml(String input) {
    final clean = input.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ');
    return clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "PERSONALIZED CARE",
            style: GoogleFonts.inter(
              fontSize: 11,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFC06A83),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Recommended For\nYou",
            style: GoogleFonts.tenorSans(
              fontSize: 28,
              height: 1.1,
              color: const Color(0xFF2D2424),
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Productsmodel>>(
            future: APIService.fetchProductsByCategory(categoryId: categoryId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _RecommendedLoading();
              }

              if (snapshot.hasError) {
                return const Text(
                  'Failed to load products',
                  style: TextStyle(color: Color(0xFF8A7F7A)),
                );
              }

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return const Text(
                  'No products found',
                  style: TextStyle(color: Color(0xFF8A7F7A)),
                );
              }

              final primary = products.first;
              final secondary = products.skip(1).take(2).toList();

              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      context.push('/product/${primary.id}');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                primary.image ??
                                    "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=600&q=80",
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: [
                              _TagChip(
                                label: "NATURAL",
                                background: const Color(0xFFDFF4B2),
                                foreground: const Color(0xFF3C5A1A),
                              ),
                              _TagChip(
                                label: "TARGETED",
                                background: const Color(0xFFF4C6D9),
                                foreground: const Color(0xFF7D2C52),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            primary.name,
                            style: GoogleFonts.tenorSans(
                              fontSize: 20,
                              height: 1.2,
                              color: const Color(0xFF2D2424),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _stripHtml(primary.description),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.5,
                              color: const Color(0xFF7B6E69),
                            ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              context.push('/product/${primary.id}');
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8E5E6A),
                              side: const BorderSide(color: Color(0xFFE5C9D3)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: GoogleFonts.inter(
                                fontSize: 11,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: Text(
                              "ADD TO ROUTINE - ₹${_formatPrice(primary.regularPrice)}",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...secondary.map((product) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CompactRecommendationTile(
                        product: product,
                        priceText: "₹${_formatPrice(product.regularPrice)}",
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _TagChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _CompactRecommendationTile extends StatelessWidget {
  final Productsmodel product;
  final String priceText;

  const _CompactRecommendationTile({
    required this.product,
    required this.priceText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
       onTap: () {
  context.push('/product/${product.id}');
},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.image ??
                    "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=600&q=80",
                height: 56,
                width: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D2424),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB34E6F),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendedLoading extends StatelessWidget {
  const _RecommendedLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 320,
          decoration: BoxDecoration(
            color: const Color(0xFFE8DEDA),
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFE8DEDA),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}
