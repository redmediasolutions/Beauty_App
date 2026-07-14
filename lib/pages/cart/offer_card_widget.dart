import 'package:flutter/material.dart';
import 'package:glowfit/models/coupon_model.dart';
import 'package:collection/collection.dart';

class OfferCardWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  /// AVAILABLE COUPONS (Sorted by highest discount from Firestore Service)
  final List<CouponModel> coupons;

  /// SELECTED COUPON CODE
  final String? selectedCouponCode;

  /// APPLY CALLBACK
  final Function(CouponModel coupon)? onCouponSelected;

  /// REMOVE CALLBACK (New property to clear selected coupon)
  final VoidCallback? onCouponRemoved;

  const OfferCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.coupons,
    this.selectedCouponCode,
    this.onCouponSelected,
    this.onCouponRemoved, // Initialize callback
  });

  @override
  Widget build(BuildContext context) {
    final hasSelectedCoupon = selectedCouponCode != null;

    // Look for any active coupon flagged explicitly for auto-suggest
    final autoSuggestCoupons = coupons.where((c) => c.autoSuggest).toList();
    final CouponModel? autoCoupon = autoSuggestCoupons.isNotEmpty ? autoSuggestCoupons.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        /// =====================================================
        /// 💡 AUTOSUGGEST QUICK-APPLY BANNER (INSIDE GAP LOCATION)
        /// =====================================================
        if (!hasSelectedCoupon && autoCoupon != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6F0562).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6F0562).withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                /// ICON
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F0562).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: Color(0xFF6F0562),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),

                /// TEXTS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Save ${autoCoupon.discount.toStringAsFixed(0)}% with code ${autoCoupon.code}",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6F0562),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Click apply to add this deal instantly.",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                /// APPLY BUTTON
                ElevatedButton(
                  onPressed: () {
                    if (onCouponSelected != null) {
                      onCouponSelected!(autoCoupon);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F0562),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Apply",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        /// =====================================================
        /// 🎟️ MAIN CLICKABLE OFFER ENTRY CARD TILE
        /// =====================================================
        GestureDetector(
          onTap: () => _showCouponsSheet(context),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3F4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: hasSelectedCoupon ? const Color(0xFF6F0562) : Colors.grey.shade200,
                width: hasSelectedCoupon ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                /// ICON
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6F0562).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6F0562),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                /// TEXTS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (hasSelectedCoupon)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6F0562),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                selectedCouponCode!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasSelectedCoupon ? "Coupon applied successfully" : subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                /// ACTION TRAILING SLOT: SHOW REMOVE BUTTON OR STATIC ARROW
                if (hasSelectedCoupon)
                  TextButton(
                    onPressed: () {
                      if (onCouponRemoved != null) {
                        onCouponRemoved!();
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Remove",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// COUPON BOTTOM SHEET WITH AUTOSUGGEST HIGHLIGHT
  /// COUPON BOTTOM SHEET (Handles filtering out Influencer coupons)
  void _showCouponsSheet(BuildContext context) {

  final couponController = TextEditingController();

  final List<CouponModel> displayCoupons = coupons

      .where((coupon) => !coupon.isInfluencerCoupon)

      .toList();

  CouponModel? suggestedCoupon;

  List<CouponModel> otherCoupons = [];

  if (displayCoupons.isNotEmpty) {

    final autosuggestIndex = displayCoupons.indexWhere(

      (c) => c.autoSuggest,

    );

    if (autosuggestIndex != -1) {

      suggestedCoupon = displayCoupons[autosuggestIndex];

      otherCoupons = List.from(displayCoupons)

        ..removeAt(autosuggestIndex);

    } else {

      suggestedCoupon = displayCoupons.first;

      otherCoupons = displayCoupons.length > 1

          ? displayCoupons.sublist(1)

          : [];

    }

  }

  showModalBottomSheet(

    context: context,

    isScrollControlled: true,

    backgroundColor: Colors.white,

    shape: const RoundedRectangleBorder(

      borderRadius: BorderRadius.vertical(

        top: Radius.circular(28),

      ),

    ),

    builder: (context) {

      return SizedBox(

        height: MediaQuery.of(context).size.height * 0.80,

        child: Column(

          crossAxisAlignment:

              CrossAxisAlignment.start,

          children: [

            Center(

              child: Container(

                margin: const EdgeInsets.only(

                  top: 12,

                ),

                width: 50,

                height: 5,

                decoration: BoxDecoration(

                  color: Colors.grey[300],

                  borderRadius:

                      BorderRadius.circular(20),

                ),

              ),

            ),

            Padding(

              padding:

                  const EdgeInsets.only(

                    left: 20,

                    right: 10,

                    top: 10,

                    bottom: 5,

                  ),

              child: Row(

                mainAxisAlignment:

                    MainAxisAlignment

                        .spaceBetween,

                children: [

                  const Text(

                    "Available Coupons",

                    style: TextStyle(

                      fontSize: 20,

                      fontWeight:

                          FontWeight.bold,

                    ),

                  ),

                  IconButton(

                    onPressed: () =>

                        Navigator.pop(

                          context,

                        ),

                    icon: const Icon(

                      Icons.close,

                    ),

                  ),

                ],

              ),

            ),

            /// MANUAL COUPON ENTRY

            Padding(

              padding:

                  const EdgeInsets.symmetric(

                    horizontal: 20,

                  ),

              child: Row(

                children: [

                  Expanded(

                    child: TextField(

                      controller:

                          couponController,

                      textCapitalization:

                          TextCapitalization

                              .characters,

                      decoration:

                          InputDecoration(

                            hintText:

                                "Enter coupon code",

                            filled: true,

                            fillColor:

                                const Color(

                                  0xFFF6F3F4,

                                ),

                            border:

                                OutlineInputBorder(

                                  borderRadius:

                                      BorderRadius.circular(

                                        14,

                                      ),

                                  borderSide:

                                      BorderSide.none,

                                ),

                          ),

                    ),

                  ),

                  const SizedBox(width: 10),

                  SizedBox(

                    height: 54,

                    child: ElevatedButton(

                      onPressed: () {

                        final enteredCode =

                            couponController.text

                                .trim()

                                .toUpperCase();

                        if (enteredCode

                            .isEmpty) {

                          return;

                        }

                        final coupon =

                            coupons

                                .firstWhereOrNull(

                                  (

                                    c,

                                  ) =>

                                      c.code

                                          .toUpperCase() ==

                                      enteredCode,

                                );

                        if (coupon ==

                            null) {

                          ScaffoldMessenger.of(

                            context,

                          ).showSnackBar(

                            const SnackBar(

                              content: Text(

                                "Invalid coupon code",

                              ),

                            ),

                          );

                          return;

                        }

                        Navigator.pop(

                          context,

                        );

                        if (onCouponSelected !=

                            null) {

                          onCouponSelected!(

                            coupon,

                          );

                        }

                      },

                      style:

                          ElevatedButton.styleFrom(

                            backgroundColor:

                                const Color(

                                  0xFF6F0562,

                                ),

                            shape:

                                RoundedRectangleBorder(

                                  borderRadius:

                                      BorderRadius.circular(

                                        14,

                                      ),

                                ),

                          ),

                      child: const Text(

                        "Apply",

                        style: TextStyle(

                          color:

                              Colors.white,

                          fontWeight:

                              FontWeight.w600,

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

            const SizedBox(height: 20),
                
              /// LIST DISPLAY SLOT
              if (displayCoupons.isNotEmpty)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔥 HIGHLIGHTED TOP SECTION (SUGGESTED / AUTOSUGGEST)
                        if (suggestedCoupon != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, top: 5),
                            child: Row(
                              children: [
                                const Icon(Icons.stars_rounded, color: Color(0xFF6F0562), size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  suggestedCoupon.autoSuggest ? "Recommended Offer" : "Suggested Best Offer",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6F0562),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildCouponCard(context, suggestedCoupon, isSuggested: true),
                          const SizedBox(height: 10),
                        ],

                        /// 🎟️ OTHER STANDARD PROMOTIONS LIST
                        if (otherCoupons.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12, top: 8),
                            child: Text(
                              "Other Promotions",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: otherCoupons.length,
                            itemBuilder: (context, index) {
                              return _buildCouponCard(context, otherCoupons[index], isSuggested: false);
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCouponCard(BuildContext context, CouponModel coupon, {required bool isSuggested}) {
    final bool isSelected = selectedCouponCode == coupon.code;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected 
              ? const Color(0xFF6F0562) 
              : (isSuggested ? const Color(0xFF6F0562).withValues(alpha: 0.3) : Colors.transparent),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6F0562),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  coupon.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isSuggested)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: coupon.autoSuggest ? const Color(0xFF6F0562).withValues(alpha: 0.1) : Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: coupon.autoSuggest ? const Color(0xFF6F0562) : Colors.amber.shade700, 
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    coupon.autoSuggest ? "SUGGESTED" : "BEST VALUE",
                    style: TextStyle(
                      color: coupon.autoSuggest ? const Color(0xFF6F0562) : Colors.amber.shade900,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                "${coupon.discount.toStringAsFixed(0)}% OFF",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF6F0562),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Special Offer: ${coupon.code}",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Get a total discount of ${coupon.discount.toStringAsFixed(0)}% off on your current order.",
            style: TextStyle(
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    coupon.endDate != null 
                        ? "This coupon is valid until ${coupon.endDate!.toDate().day}/${coupon.endDate!.toDate().month}/${coupon.endDate!.toDate().year}."
                        : "Limited time offer while coupon slots last.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: isSelected
                  ? null
                  : () {
                      Navigator.pop(context);
                      if (onCouponSelected != null) {
                        onCouponSelected!(coupon);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.grey : const Color(0xFF6F0562),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isSelected ? "Applied" : "Apply Coupon",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}