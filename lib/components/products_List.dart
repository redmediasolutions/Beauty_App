import 'package:flutter/material.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductsList extends StatefulWidget {
  final String? id;
  final String? imageUrl;
  final String name;
  final VoidCallback? onAddToCart;
  final Productsmodel product;

  const ProductsList({
    super.key,
    this.id,
    this.imageUrl,
    required this.name,
    this.onAddToCart,
    required this.product,
  });

  @override
  State<ProductsList> createState() => _ProductsListState();
}

class _ProductsListState extends State<ProductsList> {
  @override
  Widget build(BuildContext context) {
final double regular =
    double.tryParse(widget.product.regularPrice?.toString() ?? '') ?? 0;

final double sale =
    double.tryParse(widget.product.salePrice?.toString() ?? '') ?? 0;

    final bool hasDiscount = sale > 0 && sale < regular;

    final int discountPercent = hasDiscount
        ? (((regular - sale) / regular) * 100).round()
        : 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ================= IMAGE =================
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: widget.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            widget.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.grey),
                        ),
                ),

                /// 🔥 DISCOUNT BADGE
                if (hasDiscount)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "$discountPercent% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ================= INFO =================
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// PRODUCT NAME
                  Text(
                    widget.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 6),

                  /// 💰 PRICE SECTION
                  Row(
                    children: [
                      /// SALE / FINAL PRICE
                      Text(
                        "₹${(hasDiscount ? sale : regular).toStringAsFixed(0)}",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),

                      const SizedBox(width: 6),

                      /// REGULAR PRICE (STRIKETHROUGH)
                      if (hasDiscount)
                        Text(
                          "₹${regular.toStringAsFixed(0)}",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}