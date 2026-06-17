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
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.grey.shade200,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        /// ICON
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(
              0xFF6F0562,
            ).withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF6F0562),
            size: 22,
          ),
        ),

        const SizedBox(width: 14),

        /// ORDER DETAILS
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                "Order #$orderId",
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
              ),

              const SizedBox(height: 4),

              Text(
                date,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),

        /// PRICE + STATUS
        Column(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Text(
              "₹$price",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(
                      0xFF6F0562,
                    ),
                  ),
            ),

            const SizedBox(height: 6),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green
                    .withOpacity(0.10),
                borderRadius:
                    BorderRadius.circular(30),
              ),
              child: const Text(
                "DELIVERED",
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
}
