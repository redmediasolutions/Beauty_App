import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glowfit/components/products_List.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:glowfit/services/algolia_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class Searchpage extends StatefulWidget {
  const Searchpage({super.key});

  @override
  State<Searchpage> createState() =>
      _SearchpageState();
}

class _SearchpageState
    extends State<Searchpage> {

  // =========================================
  // CONTROLLERS
  // =========================================

  final TextEditingController
      _searchController =
          TextEditingController();

  Timer? _debounce;

  // =========================================
  // STATE
  // =========================================

  final List<Productsmodel>
      _products = [];

  bool _isLoading = false;

  bool _hasSearched = false;

  int _resultCount = 0;

  String _currentQuery = '';

  // =========================================
  // SEARCH
  // =========================================

  Future<void> _performSearch(
    String query,
  ) async {

    query = query.trim();

    // =====================================
    // CANCEL PREVIOUS
    // =====================================

    _debounce?.cancel();

    // =====================================
    // DEBOUNCE
    // =====================================

    _debounce = Timer(
      const Duration(
        milliseconds: 350,
      ),
      () async {

        // =================================
        // EMPTY QUERY
        // =================================

        if (query.isEmpty) {

          if (!mounted) return;

          setState(() {

            _products.clear();

            _hasSearched = false;

            _resultCount = 0;

            _currentQuery = '';

            _isLoading = false;
          });

          return;
        }

        // =================================
        // START LOADING
        // =================================

        if (!mounted) return;

        setState(() {

          _isLoading = true;

          _hasSearched = true;

          _currentQuery = query;
        });

        try {

          // =================================
          // ALGOLIA SEARCH
          // =================================

          final results =
              await AlgoliaService
                  .searchProducts(
            query,
          );

          // =================================
          // PARSE PRODUCTS
          // =================================

          final parsedProducts =
              results.map((item) {

            return Productsmodel.fromJson(
              item,
            );

          }).toList();

          // =================================
          // UPDATE UI
          // =================================

          if (!mounted) return;

          setState(() {

            _products
              ..clear()
              ..addAll(
                parsedProducts,
              );

            _resultCount =
                parsedProducts.length;

            _isLoading = false;
          });

        } catch (e) {

          debugPrint(
            'Search error: $e',
          );

          if (!mounted) return;

          setState(() {

            _isLoading = false;
          });
        }
      },
    );
  }

  // =========================================
  // DISPOSE
  // =========================================

  @override
  void dispose() {

    _debounce?.cancel();

    _searchController.dispose();

    super.dispose();
  }

  // =========================================
  // BUILD
  // =========================================

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const SizedBox(
              height: 20,
            ),

            // =================================
            // HEADER
            // =================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 25,
              ),

              child: Row(
                children: [

                  GestureDetector(
                    onTap: () {

                      if (
                        context.canPop()
                      ) {

                        context.pop();

                      } else {

                        context.go('/');
                      }
                    },

                    child: Container(
                      height: 42,
                      width: 42,

                      decoration:
                          BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(
                          12,
                        ),

                        color:
                            const Color(
                          0xFFF5F5F5,
                        ),
                      ),

                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 16,
                  ),

                  Text(
                    'Search',

                    style:
                        GoogleFonts.inter(
                      fontSize: 42,

                      fontWeight:
                          FontWeight.w700,

                      color:
                          Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            // =================================
            // SEARCH FIELD
            // =================================

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 25,
              ),

              child: Container(
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF6F6F6,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),

                child: TextField(
                  controller:
                      _searchController,

                  onChanged: (value) {

                    setState(() {});

                    _performSearch(
                      value,
                    );
                  },

                  textInputAction:
                      TextInputAction.search,

                  decoration:
                      InputDecoration(

                    hintText:
                        "Search products...",

                    hintStyle:
                        GoogleFonts.inter(
                      color:
                          Colors.grey[500],
                    ),

                    prefixIcon:
                        const Icon(
                      Icons.search,
                    ),

                    suffixIcon:
                        _searchController
                                .text
                                .isNotEmpty
                            ? GestureDetector(
                                onTap: () {

                                  _searchController
                                      .clear();

                                  _performSearch(
                                    '',
                                  );

                                  setState(
                                    () {},
                                  );
                                },

                                child:
                                    const Icon(
                                  Icons.close,
                                ),
                              )
                            : null,

                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      borderSide:
                          BorderSide.none,
                    ),

                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      borderSide:
                          BorderSide.none,
                    ),

                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),

                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFF6F0562,
                        ),
                      ),
                    ),

                    filled: true,

                    fillColor:
                        const Color(
                      0xFFF6F6F6,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            // =================================
            // RESULTS INFO
            // =================================

            if (_hasSearched)

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 25,
                ),

                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [

                    Text(
                      "$_resultCount RESULTS",

                      style:
                          GoogleFonts.inter(
                        fontSize: 12,

                        letterSpacing:
                            2,

                        fontWeight:
                            FontWeight.w600,

                        color:
                            Colors.grey[
                                500],
                      ),
                    ),

                    if (_currentQuery
                        .isNotEmpty)

                      Expanded(
                        child: Align(
                          alignment:
                              Alignment
                                  .centerRight,

                          child: Text(
                            "\"$_currentQuery\"",

                            overflow:
                                TextOverflow
                                    .ellipsis,

                            style:
                                GoogleFonts
                                    .inter(
                              fontSize: 12,

                              fontWeight:
                                  FontWeight
                                      .w500,

                              color:
                                  const Color(
                                0xFF6F0562,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(
              height: 10,
            ),

            // =================================
            // BODY
            // =================================

            Expanded(
              child: Builder(
                builder: (_) {

                  // ===========================
                  // INITIAL STATE
                  // ===========================

                  if (!_hasSearched) {

                    return Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [

                          Icon(
                            Icons.search,
                            size: 70,

                            color:
                                Colors
                                    .grey[300],
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          Text(
                            "Search skincare products",

                            style:
                                GoogleFonts
                                    .inter(
                              fontSize: 16,

                              fontWeight:
                                  FontWeight
                                      .w500,

                              color:
                                  Colors
                                      .grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ===========================
                  // LOADING
                  // ===========================

                  if (_isLoading) {

                    return const Center(
                      child:
                          CircularProgressIndicator(
                        color:
                            Color(
                          0xFF6F0562,
                        ),
                      ),
                    );
                  }

                  // ===========================
                  // EMPTY STATE
                  // ===========================

                  if (_products.isEmpty) {

                    return Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                        children: [

                          Icon(
                            Icons
                                .search_off_rounded,

                            size: 70,

                            color:
                                Colors
                                    .grey[300],
                          ),

                          const SizedBox(
                            height: 18,
                          ),

                          Text(
                            "No products found",

                            style:
                                GoogleFonts
                                    .inter(
                              fontSize: 18,

                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            "Try different keywords",

                            style:
                                GoogleFonts
                                    .inter(
                              color:
                                  Colors
                                      .grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // ===========================
                  // RESULTS GRID
                  // ===========================

                  return GridView.builder(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 20,
                    ),

                    itemCount:
                        _products.length,

                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(

                      crossAxisCount: 2,

                      mainAxisSpacing: 20,

                      crossAxisSpacing: 15,

                      childAspectRatio:
                          0.68,
                    ),

                    itemBuilder:
                        (
                      context,
                      index,
                    ) {

                      final p =
                          _products[index];

                      return GestureDetector(
                        onTap: () {

                          context.push(
                            '/product/${p.id}',
                          );
                        },

                        child: ProductsList(

                          id:
                              p.id
                                  .toString(),

                          name:
                              p.name,

                          imageUrl:
                              p.image,

                          product: p,

                          onAddToCart:
                              () {},
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