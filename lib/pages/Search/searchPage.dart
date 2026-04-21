import 'package:flutter/material.dart';
import 'package:glowfit/components/products_List.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:glowfit/services/api.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() => _SearchpageState();
}

class _SearchpageState extends State<Searchpage> {
  final List<Productsmodel> _products = [];

  bool _isLoading = false;
  bool _hasSearched = false;
  int _resultCount = 0;

  // 🔍 SEARCH FUNCTION
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _products.clear();
        _hasSearched = false;
        _resultCount = 0;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await APIService().searchProducts(query);

      setState(() {
        _products
          ..clear()
          ..addAll(results);

        _resultCount = results.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Search error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 🔹 TITLE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Text(
                'Search',
                style: GoogleFonts.inter(
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 SEARCH FIELD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TextField(
                onChanged: _performSearch,
                decoration: InputDecoration(
                  hintText: "Search products...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // 🔹 RESULTS COUNT
            if (_hasSearched)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Text(
                  "$_resultCount RESULTS",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // 🔥 MAIN CONTENT
            Expanded(
              child: Builder(
                builder: (_) {
                  // 🟡 INITIAL STATE (NO SEARCH YET)
                  if (!_hasSearched) {
                    return const Center(
                      child: Text("Start typing to search"),
                    );
                  }

                  // 🔄 LOADING
                  if (_isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // ❌ NO RESULTS
                  if (_products.isEmpty) {
                    return const Center(
                      child: Text("No products found"),
                    );
                  }

                  // ✅ RESULTS GRID
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 20,
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
                          context.push('/product/${p.id}');
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}