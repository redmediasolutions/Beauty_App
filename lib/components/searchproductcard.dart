import 'package:flutter/material.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchProductCard extends StatefulWidget {

  final String? id;

  final String? imageUrl;

  final String name;

  final String saleprice;
  final String regularprice;

  final VoidCallback? onAddToCart;

  final VoidCallback? onTap;

  final Productsmodel product;

  const SearchProductCard( {
    super.key,
    this.id,
    this.imageUrl,
    required this.name,
    this.onAddToCart,
    this.onTap,
    required this.product,
    this.saleprice="", 
    this.regularprice="",
  });

  @override
  State<SearchProductCard>
      createState() =>
          _SearchProductCardState();
}

class _SearchProductCardState
    extends State<SearchProductCard> {

  @override
  Widget build(BuildContext context) {

    final double regular =
        double.tryParse(
              widget.product
                      .regularPrice
                      ?.toString() ??
                  '',
            ) ??
            0;

    final double sale =
        double.tryParse(
              widget.product
                      .salePrice
                      ?.toString() ??
                  '',
            ) ??
            0;

    final bool hasDiscount =
        sale > 0 &&
            sale < regular;

    final int discountPercent =
        hasDiscount
            ? (((regular - sale) /
                        regular) *
                    100)
                .round()
            : 0;

    return GestureDetector(

      onTap: widget.onTap,

      child: Container(

        decoration: BoxDecoration(
          color:
              const Color(
            0xFFF9F9F9,
          ),

          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            // ================= IMAGE =================

            Expanded(
              flex: 6,

              child: Stack(
                children: [

                  Padding(
                    padding:
                        const EdgeInsets.all(
                      12,
                    ),

                    child:
                        widget.imageUrl !=
                                null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(
                                  15,
                                ),

                                child:
                                    Image.network(
                                  widget
                                      .imageUrl!,

                                  fit:
                                      BoxFit.contain,

                                  width:
                                      double.infinity,

                                  height:
                                      double.infinity,

                                  errorBuilder:
                                      (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {

                                    return Container(
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            Colors.grey[
                                                100],

                                        borderRadius:
                                            BorderRadius.circular(
                                          15,
                                        ),
                                      ),

                                      child:
                                          const Center(
                                        child:
                                            Icon(
                                          Icons
                                              .image_not_supported,

                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              )

                            : Container(
                                decoration:
                                    BoxDecoration(
                                  color:
                                      Colors.grey[
                                          100],

                                  borderRadius:
                                      BorderRadius.circular(
                                    15,
                                  ),
                                ),

                                child:
                                    const Center(
                                  child: Icon(
                                    Icons
                                        .image_not_supported,

                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ),
                  ),

                  /// 🔥 DISCOUNT BADGE

                  if (hasDiscount)

                    Positioned(
                      top: 10,
                      left: 10,

                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              Colors.black,

                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                        ),

                        child: Text(
                          "$discountPercent% OFF",

                          style:
                              const TextStyle(
                            color:
                                Colors.white,

                            fontSize: 10,

                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  /// OUT OF STOCK

                  if (!widget
                      .product
                      .canAddToCart)

                    Positioned.fill(
                      child: Container(
                        decoration:
                            BoxDecoration(
                          color: Colors.black
<<<<<<< Updated upstream
                              .withOpacity(
                            0.45,
=======
                              .withValues(
                            alpha: 0.45,
>>>>>>> Stashed changes
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),

                        child: Center(
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),

                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white,

                              borderRadius:
                                  BorderRadius.circular(
                                30,
                              ),
                            ),

                            child: Text(
                              "OUT OF STOCK",

                              style:
                                  GoogleFonts.inter(
                                fontSize: 11,

                                fontWeight:
                                    FontWeight.w700,

                                letterSpacing:
                                    1,
                              ),
                            ),
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
                padding:
                    const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  12,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceEvenly,

                  children: [

                    /// CATEGORY

                    if (widget
                        .product
                        .categories
                        .isNotEmpty)

                      Text(
                        widget.product
                            .categories
                            .toUpperCase(),

                        maxLines: 1,

                        overflow:
                            TextOverflow
                                .ellipsis,

                        style:
                            GoogleFonts.inter(
                          fontSize: 10,

                          letterSpacing:
                              1.2,

                          fontWeight:
                              FontWeight.w600,

                          color:
                              Colors.grey[
                                  500],
                        ),
                      ),

                    /// PRODUCT NAME

                    Text(
                      widget.name
                          .toUpperCase(),

                      maxLines: 2,

                      overflow:
                          TextOverflow
                              .ellipsis,

                      style:
                          GoogleFonts.inter(
                        fontSize: 12,

                        letterSpacing:
                            1.1,

                        fontWeight:
                            FontWeight.w600,

                        color:
                            Colors.black87,
                      ),
                    ),

                    /// PRICE SECTION

                    Flexible(
                      child: Row(
                        children: [

                          /// SALE / FINAL PRICE

                          Text(
                            "₹${(hasDiscount ? sale : sale).toStringAsFixed(0)}",

                            style:
                                GoogleFonts.inter(
                              fontSize: 16,

                              fontWeight:
                                  FontWeight.w700,

                              color:
                                  Colors.black,
                            ),
                          ),

                          const SizedBox(
                            width: 6,
                          ),

                          /// REGULAR PRICE

                            Flexible(
                              child: Text(
                                "₹${regular.toStringAsFixed(0)}",

                                style:
                                    GoogleFonts.inter(
                                  fontSize: 12,

                                  color:
                                      Colors.grey,

                                  decoration:
                                      TextDecoration
                                          .lineThrough,
                                ),

                                overflow:
                                    TextOverflow
                                        .ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}