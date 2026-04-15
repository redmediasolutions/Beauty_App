import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glowfit/components/primarheader.dart';
import 'package:glowfit/components/products_List.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:glowfit/services/api.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AllProducts extends StatefulWidget {
  const AllProducts({super.key});

  @override
  State<AllProducts> createState() => _AllProductsState();
}

class _AllProductsState extends State<AllProducts> {
  final ScrollController _scrollController = ScrollController();
  final List<Productsmodel> _products = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  late Future<List<Productsmodel>> _productsFuture;
  final categories = [
    {
      'name': 'Serums',
      'count': '12 Products',
      'image':
          'https://www.drsheths.com/cdn/shop/files/1_Website.jpg?v=1746015642',
    },
    {
      'name': 'Moisturizers',
      'count': '8 Products',
      'image':
          'https://vibrantskinbar.com/wp-content/uploads/what-is-moisturizer.jpg',
    },
    {
      'name': 'Cleansers',
      'count': '6 Products',
      'image':
          'https://images.unsplash.com/photo-1556228578-0d85b1a4d571?q=80&w=400',
    },
    {
      'name': 'Masks',
      'count': '5 Products',
      'image':
          'https://wowbeauty.co/wp-content/uploads/2023/10/face-mask-web.webp',
    },
  ];
  @override
  void initState() {
    super.initState();
    _productsFuture = APIService.fetchProducts();
    _loadProducts(); // Initial load

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadProducts();
      }
    });
  }

  //====================Load Products==========================
  Future<void> _loadProducts() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newProducts = await APIService.fetchProducts(
        page: _currentPage,
        perPage: 10, // Fetch smaller chunks
      );

      setState(() {
        _isLoading = false;
        if (newProducts.isEmpty) {
          _hasMore = false;
        } else {
          _currentPage++;
          _products.addAll(newProducts);
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error: $e");
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryHeader(
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Section ---
              Padding(
                padding: const EdgeInsets.fromLTRB(25, 40, 25, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          'All Products',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 40,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.5,
                                color: Colors.black,
                              ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 8),
                    Text(
                      '18 exclusive creations',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black45,
                        fontWeight: FontWeight.w400,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    //category list
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 35,
                                  backgroundImage: NetworkImage(
                                    categories[index]['image']!,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  categories[index]['name']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    if (_products.isEmpty && _isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_products.isEmpty)
                      const Center(child: Text("No products found"))
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // Keep this as is
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 30,
                        ),
                        itemCount: _products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 15,
                              childAspectRatio: 0.7,
                            ),
                        itemBuilder: (context, index) {
                          final p = _products[index];
                          return GestureDetector(
                            onTap: () {
                              context.push('/productview', extra: p);
                            },
                            child: ProductsList(
                              id: p.id.toString(),
                              name: p.name,
                              imageUrl: p.image,
                              regularPrice: p.salePrice,
                              product: p,
                              onAddToCart: () => print("Added ${p.name}"),
                            ),
                          );
                        },
                      ),

                    // Loading indicator at the bottom
                    if (_isLoading && _products.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const SizedBox(height: 100), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }
}
