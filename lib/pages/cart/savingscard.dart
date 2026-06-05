import 'package:flutter/material.dart';

class SavingsCardWidget extends StatelessWidget {
  final double productSavings;
  final double couponSavings;

  const SavingsCardWidget({
    super.key,
    required this.productSavings,
    required this.couponSavings,
  });

  double get totalSavings =>
      productSavings + couponSavings;

  @override
  Widget build(BuildContext context) {
    if (totalSavings <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFDF5F8),
            Color(0xFFF8E9F0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8C7D8),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF6F0562,
            ).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 62,
            width: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFB34E6F),
                  Color(0xFF6F0562),
                ],
              ),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: 
            
            Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Beauty Savings",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "₹${totalSavings.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 30,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6F0562),
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  "saved on this order ✨",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB34E6F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                 if (couponSavings > 0) ...[

      const SizedBox(height: 4),

      Text(

        "Includes ₹${couponSavings.toStringAsFixed(0)} coupon savings",

        style: TextStyle(

          fontSize: 11,

          color: Colors.grey.shade700,

        ),

      ),

    ],
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                30,
              ),
            ),
            child: const Text(
              "YOU SAVE",
              style: TextStyle(
                color: Color(0xFF6F0562),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}