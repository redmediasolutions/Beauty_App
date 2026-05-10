import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glowfit/Auth/mobilelogin.dart';
import 'package:glowfit/components/primarheader.dart';
import 'package:glowfit/models/product_detail.dart';
import 'package:glowfit/models/producthighlight.dart';
import 'package:glowfit/pages/single_product/pagescroll_trigger.dart';
import 'package:glowfit/services/api.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductsView extends StatefulWidget {
  final String productId;

  const ProductsView({super.key, required this.productId});

  @override
  State<ProductsView> createState() => _ProductsViewState();
}

class _ProductsViewState extends State<ProductsView> {
  String? selectedImage;
  ProductDetail? product;
  bool isLoading = true;
  bool hasError = false;
  
  bool _isAdding = false;
int quantity = 1;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  final ScrollController _scrollController = ScrollController();

  Future<void> _addToCart(ProductDetail p) async {
  try {
    setState(() => _isAdding = true);

    final user = FirebaseAuth.instance.currentUser;

    /// 🔐 LOGIN CHECK
    if (user == null || user.isAnonymous) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        enableDrag: false,
        builder: (context) {
          return Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: MobileLogin(),
          );
        },
      );
      return;
    }

    /// 📦 CART REF
    final cartItemRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(p.id.toString());

    final cartSnap = await cartItemRef.get();

    /// 🔁 UPDATE IF EXISTS
    if (cartSnap.exists) {
      await cartItemRef.update({
        'quantity': FieldValue.increment(quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      /// ➕ CREATE NEW ITEM
      await cartItemRef.set({
        'productId': p.id,
        'image': p.images.isNotEmpty ? p.images.first : '',
        'name': p.name,
        'brand': p.manufacturer,
        'packing': p.packing,
        'mrp': p.price,
        'salePrice': p.salePrice ?? p.price,
        'quantity': quantity,
        'addedBy': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    /// ✅ SUCCESS UI
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added to cart')),
      );

      context.go('/cart');

      HapticFeedback.mediumImpact();
    }
  } catch (e) {
    debugPrint("Add to cart error: $e");
  } finally {
    if (mounted) {
      setState(() => _isAdding = false);
    }
  }
}

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchProduct() async {
    try {
      print("🟡 Fetching Product ID: ${widget.productId}");

      setState(() {
        isLoading = true;
        hasError = false;
      });

      final productData = await APIService.fetchSingleProductDetail(
        widget.productId,
      ).timeout(const Duration(seconds: 15));

      /// ✅ Handle null
      if (productData == null) {
        throw Exception("Product not found");
      }

      if (!mounted) return;

      print("✅ Product Loaded: ${productData.name}");
      print("➡️ Images: ${productData.images.length}");
      print("➡️ Highlights: ${productData.highlights.length}");

      setState(() {
        product = productData; // ✅ NO fromJson here
        isLoading = false;
      });
    } catch (e, stack) {
      print("❌ Error fetching product: $e");
      print("📍 Stacktrace: $stack");

      if (!mounted) return;

      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    /// 🔄 LOADING
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    /// ❌ ERROR
    if (hasError || product == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: fetchProduct,
            child: const Text("Retry"),
          ),
        ),
      );
    }

    /// ✅ SAFE DATA
    final p = product!;

    return PrimaryHeader(
  body: Stack(
    children: [
      /// 🔹 MAIN CONTENT (SCROLL)
      SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(context, p),
            _productdetails(context, p),
            _description(context, p),
      
            if (p.highlights.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: _buildHighlights(context, p),
              ),
      
            const SizedBox(height: 15),
            _additionalimagesrow(p: p),
            const SizedBox(height: 200),
          ],
        ),
      ),

      /// FLOATING ADD TO CART
     Positioned(
  bottom: 0,
  left: 0,
  right: 0,
  child: SafeArea(
    top: false,
    child: FloatingAddToCartBar(
      p: p,
      quantity: quantity,
      isAdding: _isAdding,
      onAdd: () => _addToCart(p),
      onIncrease: () => setState(() => quantity++),
      onDecrease: () => setState(() => quantity--),
    ),
  ),
),
    ],
  ),
);
  }

  Widget _buildHighlights(BuildContext context, ProductDetail p) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: p.highlights.map((h) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 50) / 2, // 2 per row
          child: _highlightCard(context, h),
        );
      }).toList(),
    );
  }

  Widget _addToCartSection(ProductDetail p) {
  if (!p.canAddToCart) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          child: Text(
            p.isNotForSale ? "NOT FOR SALE" : "OUT OF STOCK",
          ),
        ),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      children: [
        /// 🔹 QUANTITY
        Container(
          height: 42,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: quantity > 1
                    ? () => setState(() => quantity--)
                    : null,
              ),
              Text(quantity.toString()),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => setState(() => quantity++),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        /// 🔹 BUTTON
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isAdding ? null : () => _addToCart(p),
            icon: _isAdding
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.shopping_cart_outlined),
            label: Text(_isAdding ? "ADDING..." : "ADD TO CART"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _highlightCard(BuildContext context, ProductHighlight h) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF8E9F0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIcon(h.icon),

          const SizedBox(height: 8),

          if (h.title.isNotEmpty)
            Text(
              h.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8A206E),
              ),
            ),

          const SizedBox(height: 6),

          if (h.description.isNotEmpty)
            Text(
              h.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8A206E),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildIcon(String icon) {
    if (icon.isEmpty) {
      return const Icon(Icons.star, color: Color(0xFF8A206E), size: 24);
    }

    if (icon.startsWith('http')) {
      return Image.network(
        icon,
        height: 24,
        width: 24,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.star, color: Color(0xFF8A206E)),
      );
    }

    // fallback for dashicons (since Flutter can't render them directly)
    return const Icon(Icons.star, color: Color(0xFF8A206E), size: 24);
  }

  Widget _buildHeroSection(BuildContext context, ProductDetail p) {
    // 1. Combine images and filter out empty strings
    final List<String> allImages = p.images.isNotEmpty
        ? p.images
        : ['https://via.placeholder.com/380'];

    // 2. Fallback: Show dummy image if no images are found
    if (allImages.isEmpty) {
      allImages.add('https://your-domain.com/assets/dummy_image.png');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Positioned(
            bottom: 10,
            left: 25,
            child: Text(
              p.manufacturer.toUpperCase(),
              style: GoogleFonts.inter(
                letterSpacing: 2,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black45,
              ),
            ),
          ),
        ),
        // =========================== IMAGE CAROUSEL SECTION =========================
        CarouselSlider(
          // carouselController: _carouselController,
          options: CarouselOptions(
            height: 450, // Standard height for hero section
            // viewportFraction: 0.9, // Shows a peek of the next image
            enlargeCenterPage: true, // Adds a nice scaling effect
            enableInfiniteScroll: allImages.length > 1,
            autoPlay: false,
            onPageChanged: (index, reason) {
              setState(() {
                selectedImage = allImages[index];
              });
            },
          ),
          items: allImages.map((imageUrl) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F7),
                borderRadius: BorderRadius.circular(24), // <--- THE CURVE
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  24,
                ), // Matches the container
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ).animate().fadeIn(duration: 800.ms),
            );
          }).toList(),
        ),

        // =========================== DOT INDICATOR =========================

        // =========================== PRODUCT INFO OVERLAY =========================
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Positioned(
            bottom: 10,
            left: 25,
            right: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  p.name,
                  style: GoogleFonts.tenorSans(
                    fontSize: 26,
                    height: 1.1,
                    color: Colors.black,
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //=======================KeyWords==========================
  Widget _keywords(
    BuildContext context,
    IconData symbol,
    String label,
    String desc,
  ) {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: const Color(0xFFF8E9F0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(symbol, size: 24, color: const Color(0xFF8A206E)),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            //maxLines: 5,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8A206E),
            ),
          ),
          SizedBox(height: 8),
          Text(
            desc,
            textAlign: TextAlign.center,

            style: GoogleFonts.inter(
              fontSize: 11, // Slightly smaller to ensure fit on small screens
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8A206E),
            ),
          ),
        ],
      ),
    );
  }

  //========================== PRODUCT DETAILS SECTION =========================
  Widget _productdetails(BuildContext context, ProductDetail p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "₹ ${p.salePrice}",
                style: GoogleFonts.tenorSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "₹ ${p.price}",
                style: GoogleFonts.tenorSans(
                  fontSize: 16,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            spacing: 10,
            children: [
              Text(
                p.packing.toString(),
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //========================== DESCRIPTION SECTION =========================
 Widget _description(BuildContext context, ProductDetail p) {
  final String cleanDescription = p.content.replaceAll(
    RegExp(r'<[^>]*>|&[^;]+;'),
    '',
  );

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: StatefulBuilder(
      builder: (context, setState) {
        bool isExpanded = false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            /// 🔹 DESCRIPTION WITH EXPAND
            GestureDetector(
              onTap: () => setState(() => isExpanded = !isExpanded),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cleanDescription,
                      textAlign: TextAlign.justify,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.black),
                    ),

                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 🔹 ADDITIONAL IMAGES (SKIP FIRST IMAGE)
            
          ],
        );
      },
    ),
  );
}

  //========================== IMAGE SECTION =========================
  Widget _image(BuildContext context, ProductDetail p) {
    /// 🖼️ Safe image fallback
    final String imageUrl = p.images.isNotEmpty
        ? p.images.first
        : 'https://via.placeholder.com/380';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Image.network(
          imageUrl,
          height: 380,
          fit: BoxFit.contain,

          /// 🔄 Loading state
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const SizedBox(
              height: 380,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },

          /// ❌ Error fallback
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            height: 380,
            child: Center(child: Icon(Icons.broken_image, size: 40)),
          ),
        ).animate().fadeIn(duration: 1200.ms).moveY(begin: 20, end: 0),
      ),
    );
  }

  //========================== IMAGE SECTION =========================
  Widget _buildImageSection(BuildContext context, ProductDetail p) {
    final double sectionHeight = MediaQuery.of(context).size.height * 0.8;

    /// 🖼️ Get first image safely
    final String imageUrl = p.images.isNotEmpty
        ? p.images.first
        : 'https://via.placeholder.com/380';

    /// 💰 Price fallback
    final double displayPrice = p.salePrice ?? p.price;

    return SizedBox(
      height: sectionHeight,
      width: double.infinity,
      child: Stack(
        children: [
          /// ================= IMAGE =================
          Positioned.fill(
            child: Image.network(
              imageUrl,
              cacheWidth: 300,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.error)),
            ).animate().fadeIn(duration: 1200.ms),
          ),

          /// ================= OVERLAY =================
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🏷️ PRODUCT NAME
                  Text(
                    p.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      letterSpacing: 2,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.tealAccent,
                    ),
                  ).animate().fadeIn(duration: 800.ms).moveY(begin: 10, end: 0),

                  const SizedBox(height: 10),

                  /// 💰 PRICE
                  Text(
                    "₹ $displayPrice",
                    style: GoogleFonts.tenorSans(
                      fontSize: 22,
                      color: Colors.tealAccent,
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //
}

class _additionalimagesrow extends StatelessWidget {
    final ProductDetail p; // ✅ ADD THIS

  const _additionalimagesrow({
    super.key,
    required this.p, // ✅ REQUIRE IT
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: p.addimages.map((img) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 16), // ✅ GAP ADDED HERE
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  img.url,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) =>
                      const SizedBox.shrink(),
                ),
              ),
    
              if (img.alt.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  img.alt,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}



class FloatingAddToCartBar extends StatelessWidget {
  final ProductDetail p;
  final int quantity;
  final bool isAdding;
  final VoidCallback onAdd;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const FloatingAddToCartBar({
    super.key,
    required this.p,
    required this.quantity,
    required this.isAdding,
    required this.onAdd,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF8C277B);

    if (!p.canAddToCart) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          /// 🔵 LEFT PILL (QUANTITY)
          Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: quantity > 1 ? onDecrease : null,
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                Text(
                  quantity.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: onIncrease,
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          /// 🛒 RIGHT PILL (ADD TO CART)
          Expanded(
            child: GestureDetector(
              onTap: isAdding ? null : onAdd,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: isAdding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "ADD TO CART",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}