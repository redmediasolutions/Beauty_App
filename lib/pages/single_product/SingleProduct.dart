import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glowfit/Auth/mobilelogin.dart';
import 'package:glowfit/components/primarheader.dart';
import 'package:glowfit/components/products_List.dart';
import 'package:glowfit/models/product_detail.dart';
import 'package:glowfit/models/product_model.dart';
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
  bool _showBottomBar = true;

  @override
void initState() {
  super.initState();

  fetchProduct();

  _scrollController.addListener(() {
    final direction =
        _scrollController.position.userScrollDirection;

    if (direction == ScrollDirection.reverse &&
        _showBottomBar) {
      setState(() {
        _showBottomBar = false;
      });
    }

    if (direction == ScrollDirection.forward &&
        !_showBottomBar) {
      setState(() {
        _showBottomBar = true;
      });
    }
  });
}

  final ScrollController _scrollController = ScrollController();

  Future<bool> hasRequestedStockNotification(
  String productId,
) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return false;

  final snapshot = await FirebaseFirestore.instance
      .collection('stock_notifications')
      .where('userId', isEqualTo: user.uid)
      .where('productId', isEqualTo: productId)
      .limit(1)
      .get();

  return snapshot.docs.isNotEmpty;
}

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
        print("========== ADD TO CART ==========");

print("Product: ${p.name}");
print("Tax Status: ${p.taxStatus}");

print("Tax Class: ${p.taxClass}");

print("================================");
       await cartItemRef.set({
  'productId': p.id,

  'image':
      p.images.isNotEmpty
          ? p.images.first
          : '',

  'name': p.name,

  'brand': p.manufacturer,

  'packing': p.packing,

  'mrp': p.price,

  'salePrice':
      p.salePrice ?? p.price,

  'taxStatus': p.taxStatus,

  'taxClass': p.taxClass,

  'taxRate': p.taxRate,

  'quantity': quantity,

  'addedBy': 'user',

  'createdAt':
      FieldValue.serverTimestamp(),

  'updatedAt':
      FieldValue.serverTimestamp(),
});
      }

      /// ✅ SUCCESS UI
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Added to cart')));

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
                if (p.highlights.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: _buildHighlights(context, p),
                  ),
                _additionalimagesrow(p: p),
                const SizedBox(height: 15),
                _description(context, p),
                const SizedBox(height: 200),
                _relatedProductsSection(p),
              ],
            ),
          ),

          /// FLOATING ADD TO CART
          AnimatedPositioned(
  duration: const Duration(
    milliseconds: 300,
  ),
  curve: Curves.easeOutCubic,
  left: 0,
  right: 0,

  bottom: _showBottomBar
      ? MediaQuery.of(context)
              .viewPadding
              .bottom +
          25 // sits above navbar
      : -140,

  child: FloatingAddToCartBar(
    p: p,
    quantity: quantity,
    isAdding: _isAdding,
    onAdd: () => _addToCart(p),
    onIncrease: () => setState(() => quantity++),
    onDecrease: () => setState(() => quantity--),
  ),
),
        ],
      ),
    );
  }

  Widget _buildHighlights(BuildContext context, ProductDetail p) {
    return Column(
      children: p.highlights.map((h) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),

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
            child: Text(p.isNotForSale ? "NOT FOR SALE" : "OUT OF STOCK"),
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
      constraints: const BoxConstraints(minHeight: 170),

      padding: const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F6),

        borderRadius: BorderRadius.circular(28),

        border: Border.all(color: const Color(0xFFF1E5EC)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),

            blurRadius: 18,

            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // =========================

          // ICON BOX

          // =========================
          Container(
            height: 68,

            width: 68,

            decoration: BoxDecoration(
              color: const Color(0xFFF1E7ED),

              borderRadius: BorderRadius.circular(20),
            ),

            child: Center(child: _buildIcon(h.icon)),
          ),

          const SizedBox(height: 28),

          // =========================

          // TITLE

          // =========================
          if (h.title.trim().isNotEmpty)
            Text(
              h.title,

              style: GoogleFonts.playfairDisplay(
                fontSize: 20,

                height: 1.2,

                fontWeight: FontWeight.w700,

                color: const Color(0xFF1D1B1C),
              ),
            ),

          const SizedBox(height: 14),

          // =========================

          // DESCRIPTION

          // =========================
          if (h.description.trim().isNotEmpty)
            Text(
              h.description,

              style: GoogleFonts.manrope(
                fontSize: 16,

                height: 1.8,

                fontWeight: FontWeight.w500,

                color: const Color(0xFF5B4A55),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).moveY(begin: 20, end: 0);
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
        errorBuilder: (_, _, _) =>
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
          child: Text(p.manufacturer.toUpperCase()),
        ),
        // =========================== IMAGE CAROUSEL SECTION =========================
        CarouselSlider(
          options: CarouselOptions(
            height: 420,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            enableInfiniteScroll: allImages.length > 1,
            autoPlay: false,
            onPageChanged: (index, reason) {
              setState(() {
                selectedImage = allImages[index];
              });
            },
          ),
          items: allImages.map((imageUrl) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F7),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ).animate().fadeIn(duration: 800.ms),
              ),
            );
          }).toList(),
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
    // Calculate savings

    final double mrp = p.price;

    final double salePrice = p.salePrice ?? p.price;

    final double savingsPercent = mrp > 0 ? ((mrp - salePrice) / mrp) * 100 : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Text(
            p.name,
            style: GoogleFonts.manrope(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          if ((p.shortdescription).trim().isNotEmpty)
            _shortdescription(context, p)
          else
            const SizedBox.shrink(),
          Text(
                p.packing.toString(),
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.blueGrey,
                  fontSize: 18,
                ),
              ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Text(
                "₹ ${salePrice.toStringAsFixed(0)}",

                style: GoogleFonts.manrope(
                  fontSize: 26,

                  fontWeight: FontWeight.w800,

                  color: const Color(0xFF701A80),
                ),
              ),

              const SizedBox(width: 10),

              if (salePrice < mrp)
                Text(
                  "₹ ${mrp.toStringAsFixed(0)}",

                  style: GoogleFonts.manrope(
                    fontSize: 20,

                    color: Colors.purple,

                    fontWeight: FontWeight.w500,

                    decoration: TextDecoration.lineThrough,
                  ),
                ),

              const SizedBox(width: 12),

              if (salePrice < mrp)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,

                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.green.shade50,

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: Colors.green.shade300),
                  ),

                  child: Text(
                    "${savingsPercent.round()}% OFF",

                    style: GoogleFonts.manrope(
                      fontSize: 12,

                      fontWeight: FontWeight.w700,

                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),

          if (salePrice < mrp) ...[
            const SizedBox(height: 6),

            Text(
              "You save ₹ ${(mrp - salePrice).toStringAsFixed(0)}",

              style: GoogleFonts.manrope(
                fontSize: 14,

                fontWeight: FontWeight.w600,

                color: Colors.green.shade700,
              ),
            ),
          ],
          const SizedBox(height: 20),
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _relatedProductsSection(ProductDetail product) {
    // =====================================
    // GET RELATED PRODUCTS FROM MODEL
    // =====================================

    final List<Productsmodel> relatedProducts = product.relatedProducts;

    if (relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),

          child: Text(
            "Related Products",

            style: GoogleFonts.manrope(
              fontSize: 24,

              fontWeight: FontWeight.w800,

              color: Colors.black,
            ),
          ),
        ),

        const SizedBox(height: 20),

        SizedBox(
          height: 320,

          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),

            scrollDirection: Axis.horizontal,

            itemCount: relatedProducts.length,

            separatorBuilder: (_, _) => const SizedBox(width: 16),

            itemBuilder: (context, index) {
              final p = relatedProducts[index];

              return SizedBox(
                width: 190,

                child: GestureDetector(
                  onTap: () {
                    context.push('/product/${p.id}');
                  },

                  child: ProductsList(
                    id: p.id.toString(),

                    imageUrl: p.image,

                    name: p.name,

                    product: p,

                    onAddToCart: () {},
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _shortdescription(BuildContext context, ProductDetail p) {
    final String cleanDescription = p.shortdescription.replaceAll(
      RegExp(r'<[^>]*>|&[^;]+;'),
      '',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: StatefulBuilder(
        builder: (context, setState) {
          bool isExpanded = false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5),
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
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              /// 🔹 ADDITIONAL IMAGES (SKIP FIRST IMAGE)
            ],
          );
        },
      ),
    );
  }
  //
}

class _additionalimagesrow extends StatelessWidget {
  final ProductDetail p; // ✅ ADD THIS

  const _additionalimagesrow({
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
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

              if (img.alt.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  img.alt,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class FloatingAddToCartBar extends StatefulWidget {
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
  State<FloatingAddToCartBar> createState() => _FloatingAddToCartBarState();
}

class _FloatingAddToCartBarState

    extends State<FloatingAddToCartBar> {

  bool _alreadyRequested = false;

  bool _loading = true;

  @override

  void initState() {

    super.initState();

    _checkRequest();

  }

  Future<void> _checkRequest() async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {

      setState(() => _loading = false);

      return;

    }

    final snapshot = await FirebaseFirestore.instance

        .collection('stock_notifications')

        .where('userId', isEqualTo: user.uid)

        .where(

          'productId',

          isEqualTo: widget.p.id,

        )

        .limit(1)

        .get();

    if (mounted) {

      setState(() {

        _alreadyRequested =

            snapshot.docs.isNotEmpty;

        _loading = false;

      });

    }

  }
  @override
    Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF8C277B);

if (!widget.p.canAddToCart) {
  if (_loading) {
    return const SizedBox(
      height: 65,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 20,
    ),
    child: SizedBox(
      height: 65,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _alreadyRequested
            ? null
            : () async {
                final user =
                    FirebaseAuth.instance.currentUser;

                if (user == null) return;

                await FirebaseFirestore.instance
                    .collection(
                      'stock_notifications',
                    )
                    .add({
                  'userId': user.uid,
                  'email': user.email,
                  'productId': widget.p.id,
                  'productName':
                      widget.p.name,
                  'createdAt':
                      FieldValue
                          .serverTimestamp(),
                  'status': 'pending',
                });

                if (mounted) {
                  setState(() {
                    _alreadyRequested =
                        true;
                  });
                }
              },
        icon: Icon(
          _alreadyRequested
              ? Icons.check_circle
              : Icons.notifications_active,
        ),
        label: Text(
          _alreadyRequested
              ? "WE'LL UPDATE YOU WHEN IT'S AVAILABLE"
              : "NOTIFY WHEN AVAILABLE",
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _alreadyRequested
                  ? Colors.green
                  : const Color(
                      0xFF8C277B,
                    ),
          foregroundColor:
              Colors.white,
          disabledBackgroundColor:
              Colors.green,
          disabledForegroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              40,
            ),
          ),
        ),
      ),
    ),
  );
}

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
                BoxShadow(color: primaryColor.withValues(alpha: 0.3), blurRadius: 20),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.quantity > 1 ? widget.onDecrease : null,
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                Text(
                  widget.quantity.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: widget.onIncrease,
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          /// 🛒 RIGHT PILL (ADD TO CART)
          Expanded(
            child: GestureDetector(
              onTap: widget.isAdding ? null : widget.onAdd,
              child: Container(
                height: 65,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isAdding
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
                            Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                            ),
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
