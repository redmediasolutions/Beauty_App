import 'package:flutter/material.dart';

class FreeGiftBanner extends StatelessWidget {
  final double cartTotal;
  final double unlockAmount;

  final String giftName;
  final String giftImage;
  final bool isUnlocked;

  final VoidCallback? onAddGift;
final bool giftAdded;

const FreeGiftBanner({
  super.key,
  required this.cartTotal,
  required this.unlockAmount,
  required this.giftName,
  required this.giftImage,
  this.isUnlocked = false,
  this.onAddGift,
  this.giftAdded = false,
});

  @override
  Widget build(BuildContext context) {
    
    final bool unlocked =
        cartTotal >= unlockAmount;

    final double remaining =
        (unlockAmount - cartTotal)
            .clamp(0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(

  color: unlocked

      ? const Color(0xFFF7EEF5)

      : const Color(0xFFFDF7FB),

  borderRadius: BorderRadius.circular(20),

  border: Border.all(

    color: const Color(

      0xFF6F0562,

    ).withValues(alpha: 0.15),

  ),

),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: Image.network(
              giftImage,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                   Icon(

  unlocked

      ? Icons.card_giftcard

      : Icons.card_giftcard_outlined,

  color: const Color(0xFF6F0562),

),
                    const SizedBox(width: 6),
                    Text(

  unlocked

      ? "Free Gift Unlocked"

      : "Unlock Your Free Gift",

  style: const TextStyle(

    fontSize: 16,

    fontWeight: FontWeight.w700,

    color: Color(0xFF6F0562),

  ),

),
                  ],
                ),

                const SizedBox(height: 8),

                if (unlocked)
                  Text(
                    "Congratulations! You qualify for a FREE $giftName.",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  )
                else
                  Text(
                    "Add ₹${remaining.toStringAsFixed(0)} more to unlock a FREE $giftName.",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),

                const SizedBox(height: 10),

                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(10),
                  child:
                      LinearProgressIndicator(
  minHeight: 8,
  value: (cartTotal / unlockAmount)
      .clamp(0.0, 1.0),
  backgroundColor: const Color(
    0xFF6F0562,
  ).withValues(alpha: 0.08),
  valueColor:
      const AlwaysStoppedAnimation(
        Color(0xFF6F0562),
      ),
),
                ),

                const SizedBox(height: 6),

                Text(
                  "₹${cartTotal.toStringAsFixed(0)} / ₹${unlockAmount.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),

if (unlocked)
  SizedBox(
    height: 40,
    child: ElevatedButton.icon(
      onPressed: giftAdded
          ? null
          : onAddGift,
      icon: Icon(
        giftAdded
            ? Icons.check
            : Icons.card_giftcard,
        size: 18,
      ),
      label: Text(
        giftAdded
            ? "Gift Added"
            : "Add Free Gift",
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(
          0xFF6F0562,
        ),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(30),
        ),
      ),
    ),
  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}