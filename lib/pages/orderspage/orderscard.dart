import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderCard extends StatelessWidget {
  final int orderId;
  final String date;
  final String status;
  final Color statusColor;
  final Color iconBg;
  final String items;
  final String amount;
  final String delivery;
  final bool showTrack;
  final bool showReorder;
  final Icon odericon;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.iconBg,
    required this.items,
    required this.amount,
    required this.delivery,
    this.showTrack = false,
    this.showReorder = false, 
    required this.odericon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: odericon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order $orderId",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Info Row
            Row(
              children: [
                _info("Total Items", items),
                _info("Total Amount", amount),
              ],
            ),

            if (delivery.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "Estimated Delivery\n$delivery",
                style: const TextStyle(fontSize: 12),
              ),
            ],

            const SizedBox(height: 16),

            /// Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A5F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      context.pushNamed(
  'orderDetail',
  pathParameters: {
    'id': orderId.toString(), // ✅ FIXED
  },
);
                    },
                    child: const Text("View Details", style: TextStyle(color: Colors.white),),
                  ),
                ),
                if (showTrack) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text("Track", style: TextStyle(color: Color.fromARGB(255, 6, 39, 66)),),
                  ),
                ],
                if (showReorder) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text("Reorder",style: TextStyle(color: Color.fromARGB(255, 6, 39, 66))),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String title, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
