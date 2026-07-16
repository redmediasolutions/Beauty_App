import 'package:flutter/material.dart';

class CartItemWidget extends StatelessWidget {
  final String name;
  final String imageUrl;
  final int quantity;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  final double mrp;

  final double salePrice;

  final double taxRate;

  const CartItemWidget({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.mrp,
    required this.salePrice,
    required this.taxRate,

  });

  @override
  Widget build(BuildContext context) {
  
double withTax(double price) {
  return price * (1 + taxRate / 100);
}

// Original prices
final double originalMrp = mrp;
final double originalSale = salePrice;

// Display prices (GST inclusive)
final double displayMrp = withTax(originalMrp);
final double displaySale = withTax(originalSale);

final int discountPercent =
    originalMrp > originalSale
        ? (((originalMrp - originalSale) / originalMrp) * 100).round()
        : 0;

final double totalSalePrice =
    displaySale * quantity;

final double totalMrp =
    displayMrp * quantity;

// Keep savings based on original prices
final double totalSavings =
    (originalMrp - originalSale) * quantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 90,
                    height: 110,
                    fit: BoxFit.contain,
                  )
                : Container(width: 90, height: 110, color: Colors.grey[200]),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                   Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      quantity > 1
          ? "₹${totalSalePrice.toStringAsFixed(0)}"
          : "₹${displaySale.toStringAsFixed(0)}",
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6F0562),
      ),
    ),

    const SizedBox(height: 2),

    if (quantity > 1)
      Text(
        "${quantity} × ₹${displaySale.toStringAsFixed(0)}",
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),

    const SizedBox(height: 4),

    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mrp > salePrice)
          Text(
            "₹${(quantity > 1 ? totalMrp : displayMrp).toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              decoration: TextDecoration.lineThrough,
            ),
          ),

        if (discountPercent > 0) ...[
          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.shade300,
              ),
            ),
            child: Text(
              "$discountPercent% OFF",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ],
    ),

    if (totalSavings > 0) ...[
      const SizedBox(height: 4),

      Text(
        "You save ₹${totalSavings.toStringAsFixed(0)}",
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB34E6F),
        ),
      ),
    ],
  ],
),
                    Container(
  height: 42,
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    border: Border.all(
      color: Colors.grey.shade300,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      InkWell(
        onTap: quantity == 1
            ? onRemove
            : onDecrement,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: quantity == 1
                ? Colors.red.shade50
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            quantity == 1
                ? Icons.delete_outline
                : Icons.remove,
            size: 18,
            color: quantity == 1
                ? Colors.red.shade600
                : Colors.black87,
          ),
        ),
      ),

      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Text(
          quantity.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      InkWell(
        onTap: onIncrement,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF6F0562),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    ],
  ),
)
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
