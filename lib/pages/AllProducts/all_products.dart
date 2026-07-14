import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glowfit/components/primarheader.dart';
import 'package:glowfit/components/products_List.dart';
import 'package:glowfit/models/categorymodel.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:glowfit/services/api.dart';
import 'package:glowfit/services/remoteconfig.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AllProducts extends StatefulWidget {

  final CategoryModel? initialCategory;

  const AllProducts({

    super.key,

    this.initialCategory,

  });

  @override

  State<AllProducts> createState() =>

      _AllProductsState();

}

class _AllProductsState extends State<AllProducts> {
  final ScrollController _scrollController = ScrollController();
  final List<Productsmodel> _products = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  late Future<List<Productsmodel>> _productsFuture;
  List<CategoryModel> categories = [];
  List<CategoryModel> subCategories = [];
  int _selectedCategoryId = 49; // ✅ default = ALL PRODUCTS (category 49)
  int _selectedCategoryIndex = 0;
  int _selectedSubCategoryId = 49;

  @override
void initState() {
  super.initState();

  final initialCategory =
      widget.initialCategory;

  if (initialCategory != null) {
    _selectedCategoryId =
        initialCategory.id;

    _selectedSubCategoryId =
        initialCategory.id;
  } else {
    _selectedCategoryId = 49;
    _selectedSubCategoryId = 49;
  }

  loadCategoriesFromRemote();

  _loadProducts();

  _scrollController.addListener(() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadProducts();
    }
  });
}

Future<void> _applyInitialCategory() async {
  final initial = widget.initialCategory;

  if (initial == null) {
    _selectedCategoryId = 49;
    _selectedSubCategoryId = 49;
    return;
  }

  // Check if selected category is one of the top categories
  final mainIndex = categories.indexWhere(
    (e) => e.id == initial.id,
  );

  if (mainIndex >= 0) {
    _selectedCategoryIndex = mainIndex;
    _selectedCategoryId = initial.id;
    _selectedSubCategoryId = initial.id;

    await loadSubCategories(initial.id);
    return;
  }

  // Search inside all category trees
  for (final category in categories) {
    final children =
        await APIService.fetchSubCategories(
      category.id,
    );

    final sub = children.firstWhere(
      (e) => e.id == initial.id,
      orElse: () => CategoryModel(
        id: -1,
        name: '',
        image: '',
        parent: 0,
      ),
    );

    if (sub.id != -1) {
      _selectedCategoryIndex =
          categories.indexWhere(
        (e) => e.id == category.id,
      );

      _selectedCategoryId =
          category.id;

      await loadSubCategories(
        category.id,
      );

      _selectedSubCategoryId =
          initial.id;

      return;
    }
  }
}

  Future<void> loadCategoriesFromRemote() async {
    try {
      final raw = RemoteConfigService.getProductCategories();

      debugPrint("📡 Remote categories: $raw");

      final ids = raw
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .where((e) => e != null)
          .cast<int>()
          .toList();

      final result = await APIService.fetchCategoriesByIds(ids);

      setState(() {
        categories = [
          CategoryModel(
            id: 49,
            name: "All",
            image: "assets/images/gladskin-all.webp",
            parent: 0,
          ),
          ...result,
        ];
      });

      // Load subcategories for first category
if (categories.isNotEmpty) {
  await _applyInitialCategory();

  await _loadProducts(
    reset: true,
  );
}
    } catch (e) {
      debugPrint("❌ Remote category error: $e");
    }
  }

  Future<void> _onCategorySelected(int index) async {
    final selected = categories[index];

    setState(() {
      _selectedCategoryIndex = index;
      _selectedCategoryId = selected.id;
      _selectedSubCategoryId = selected.id; // default = same
    });

    if (selected.id != 49) {
      await loadSubCategories(selected.id);
    } else {
      setState(() => subCategories = []);
    }

    await _loadProducts(reset: true);
  }

  Future<void> _onSubCategorySelected(int id) async {
    setState(() {
      _selectedSubCategoryId = id;
    });

    await _loadProducts(reset: true);
  }

  Future<void> loadSubCategories(int parentId) async {
    final result = await APIService.fetchSubCategories(parentId);

    setState(() {
      subCategories = [
        CategoryModel(id: parentId, name: "All", image: "", parent: 0),
        ...result,
      ];
    });
  }

  //====================Load Products==========================
  Future<void> _loadProducts({bool reset = false}) async {
    if (_isLoading || (!_hasMore && !reset)) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _products.clear();
    }

    setState(() => _isLoading = true);

    try {
      const int perPage = 50;
      final newProducts = await APIService.fetchProducts(
        page: _currentPage,
        perPage: perPage,
        categoryId: _selectedSubCategoryId,
      );

      setState(() {
        _isLoading = false;
        _currentPage++;
        _products.addAll(newProducts);
        // Stop when API returns fewer items than requested (last page reached)
        if (newProducts.length < perPage) {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Load error: $e");
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
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          'All Products',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.5,
                                color: Colors.black,
                              ),
                        )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 8),
                    //category list
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final cat = categories[index];
                          final isSelected = index == _selectedCategoryIndex;

                          return GestureDetector(
                            onTap: () => _onCategorySelected(index),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 15),
                              child: Column(
                                children: [
                                  /// 🔥 CATEGORY IMAGE
                                  Container(
  width: 70,
  height: 120,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: isSelected
          ? const Color(0xFF6F0562)
          : Colors.transparent,
      width: 2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
      if (isSelected)
        BoxShadow(
          color: const Color(
            0xFF6F0562,
          ).withValues(alpha: 0.18),
          blurRadius: 18,
          spreadRadius: 1,
          offset: const Offset(0, 4),
        ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: cat.image.startsWith('assets/')
        ? Image.asset(
            cat.image,
            fit: BoxFit.contain,
          )
        : cat.image.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: cat.image,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.category),
              )
            : const Icon(Icons.category),
  ),
),

                                  const SizedBox(height: 6),

                                  /// 🔥 CATEGORY NAME
                                  Text(
                                    cat.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? const Color(0xFF6F0562)
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
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
                      /// 🔥 MAIN CONTENT (SIDEBAR + PRODUCTS)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// ================= LEFT SIDEBAR =================
                          if (subCategories.isNotEmpty)
                            Container(
                              width: 80,
                              color: const Color(0xFFF7F7F7),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: subCategories.length,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                itemBuilder: (context, index) {
                                  final sub = subCategories[index];
                                  final isSelected =
                                      sub.id == _selectedSubCategoryId;

                                  return GestureDetector(
                                    onTap: () => _onSubCategorySelected(sub.id),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      height: 95,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 6,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ]
                                            : [],
                                      ),

                                      /// 🔥 CENTERED CONTENT
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF6F0562)
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                              color: Colors.grey.shade100,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: sub.name.toLowerCase() == 'all'
    ? Image.asset(
        'assets/images/gladskin-all.webp',
        fit: BoxFit.cover,
      )
    : sub.image.isNotEmpty
        ? CachedNetworkImage(
            imageUrl: sub.image,
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
            errorWidget: (_, __, ___) =>
                const Icon(
                  Icons.category,
                  size: 20,
                ),
          )
        : const Icon(
            Icons.category,
            size: 20,
          ),
                                            ),
                                          ),

                                          const SizedBox(height: 6),

                                          Flexible(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: Text(
                                                sub.name,
                                                maxLines: 2,
                                                textAlign: TextAlign.center,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  height: 1.15,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                  color: isSelected
                                                      ? const Color(0xFF6F0562)
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                          /// ================= PRODUCTS GRID =================
                          Expanded(
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 0,
                              ),
                              itemCount: _products.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 20,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.7,
                                  ),
                              itemBuilder: (context, index) {
                                final p = _products[index];

                                return GestureDetector(
                                  onTap: () {
                                    final productId = p.id.toString();

                                    if (productId.isEmpty) return;

                                    context.push('/product/$productId');
                                  },
                                  child: ProductsList(
                                    id: p.id.toString(),
                                    name: p.name,
                                    imageUrl: p.image,
                                    product: p,
                                    onAddToCart: () {},
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
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
