import 'package:flutter/material.dart';
import 'package:glowfit/components/orderhistory.dart';

class Orderlist extends StatelessWidget {
  const Orderlist({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9), // Matching your soft gray background
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Order History",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 26,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D212C),
                ),
              ),
              TextButton(
                onPressed: () {}, // Navigate to full history
                child: Text(
                  "VIEW ALL",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: const Color(0xFF8A206E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // List of orders
          Orderhistory(
            orderId: "OE-9821",
            date: "Nov 12, 2023",
            price: "142.00",
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 20),
          Orderhistory(
            orderId: "OE-9455",
            date: "Sep 28, 2023",
            price: "89.00",
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 20),
          Orderhistory(
            orderId: "OE-9102",
            date: "Aug 05, 2023",
            price: "215.50",
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }
}
