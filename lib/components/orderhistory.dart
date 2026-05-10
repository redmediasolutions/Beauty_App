import 'package:flutter/material.dart';

class Orderhistory extends StatelessWidget {
  final String orderId;
  final String date;
  final String price;
  final IconData icon;
  const Orderhistory({
    super.key,
    required this.orderId,
    required this.date,
    required this.price,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Icon Container (The gray square)
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: const Color(0xFFEBEBEB), // Soft gray from the image
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF6B6B6B), size: 24),
        ),
        const SizedBox(width: 15),

        // 2. Order Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order #$orderId",
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 2),
              Text(
                "Delivered • $date",
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),

        // 3. Price
        Text(
          "₹$price",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontSize: 15, color: Colors.black),
        ),
      ],
    );
  }
}
