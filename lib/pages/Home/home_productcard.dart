import 'package:flutter/material.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeFeaturedProductCard extends StatelessWidget {
  final Productsmodel product;
  final Color accentColor;

  const HomeFeaturedProductCard({
    super.key,
    required this.product,
    required this.accentColor,
  });

  String _formatPrice(double? price) {
    if (price == null) return "--";
    return price.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    // =====================================
// GST INCLUSIVE PRICES
// =====================================

double withTax(double price) {
  return price * (1 + product.taxRate / 100);
}

final double originalMrp =
    product.regularPrice ?? 0;

final double originalSale =
    product.salePrice ?? originalMrp;

// Prices including GST
final double mrp =
    withTax(originalMrp);

final double salePrice =
    withTax(originalSale);

// Discount percentage should always be calculated
// from the original prices (GST doesn't affect it)
final int discountPercent =
    originalMrp > originalSale && originalMrp > 0
        ? (((originalMrp - originalSale) / originalMrp) * 100).round()
        : 0;

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: SizedBox(
        width: 210,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            product.image ??
                                "https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=600&q=80",
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7F0A2),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "BEST SELLER",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E3A1A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D2424),
              ),
            ),
            const SizedBox(height: 6),
            

Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Text(
          "₹${_formatPrice(salePrice)}",
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFB34E6F),
          ),
        ),

        const SizedBox(width: 6),

        if (mrp > salePrice)
          Text(
            "₹${_formatPrice(mrp)}",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey.shade600,
              decoration: TextDecoration.lineThrough,
            ),
          ),
                  const Spacer(),
          if (discountPercent > 0) ...[
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.shade300,
          ),
        ),
        child: Text(
          "SAVE $discountPercent%",
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.green.shade700,
          ),
        ),
      ),
    ],
      ],
    ),
  ],
)
          ],
        ),
      ),
    );
  }
}
