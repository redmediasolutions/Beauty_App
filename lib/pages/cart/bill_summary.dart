import 'package:flutter/material.dart';
import 'summary_row_widget.dart';

class BillSummaryWidget extends StatelessWidget {
  final double subtotal; // Cart Total baseline
  final double tax;
  final double shipping;
  final double total;
  final bool usePoints;
  final double couponDiscount;
  final double codCharges; // Added parameter for COD handling
  final double totalMrp;
  final double gst18;
final double gst5;

  const BillSummaryWidget({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.usePoints,
    required this.couponDiscount,
    required this.codCharges, // Initialize parameter
    required this.totalMrp,
    required this.gst18,
    required this.gst5,
  });

  @override
  Widget build(BuildContext context) {
    final double cartTotal = subtotal;

    // Combine discounts
    final double pointsDiscountAmount = usePoints ? 50 : 0;
    final double totalDeductedDiscount = couponDiscount + pointsDiscountAmount;

    // Subtotal calculation (Cart Total - Discount)
    final double runningSubtotal = (cartTotal - totalDeductedDiscount) < 0 
        ? 0.0 
        : (cartTotal - totalDeductedDiscount);

    // Recalculate tax rate dynamically based on running subtotal base
    final double recalculatedTax =
    gst18 + gst5;

    // Final Total computation block including dynamic COD charges
    final double finalTotal = runningSubtotal + recalculatedTax + shipping + codCharges;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
  Row(
    mainAxisAlignment:
        MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        "MRP",
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      ),
      Text(
        "₹${totalMrp.toStringAsFixed(0)}",
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
          decoration:
              TextDecoration.lineThrough,
        ),
      ),
    ],
  ),

  const SizedBox(height: 10),
          /// CART TOTAL
          SummaryRowWidget(
            label: "Sale Total",
            value: "₹${cartTotal.toStringAsFixed(0)}",
          ),
          
          /// DISCOUNT ROW
          if (totalDeductedDiscount > 0) ...[
            const SizedBox(height: 10),
            SummaryRowWidget(
              label: "Coupon Discount",
              value: "-₹${totalDeductedDiscount.toStringAsFixed(0)}",
            ),
          ],
          
          const Divider(height: 24),

          /// RUNNING SUBTOTAL (Bold, normal size)
          SummaryRowWidget(
            label: "Subtotal",
            value: "₹${runningSubtotal.toStringAsFixed(0)}",
            isSubtotal: true,
          ),
          const SizedBox(height: 10),

          /// TAX (+)
          if (gst18 > 0) ...[
            SummaryRowWidget(
              label: "GST (18%)",
              value: "+₹${gst18.toStringAsFixed(0)}",
            ),
            const SizedBox(height: 10),
          ],

          if (gst5 > 0) ...[
            SummaryRowWidget(
              label: "GST (5%)",
              value: "+₹${gst5.toStringAsFixed(0)}",
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 10),

          /// SHIPPING (+)
          SummaryRowWidget(
            label: "Shipping",
            value: "+₹${shipping.toStringAsFixed(0)}",
          ),

          /// CASH ON DELIVERY EXTRA CHARGES ROW
          if (codCharges > 0) ...[
            const SizedBox(height: 10),
            SummaryRowWidget(
              label: "COD Charges",
              value: "+₹${codCharges.toStringAsFixed(0)}",
            ),
          ],

          const Divider(height: 30),

          /// FINAL TOTAL AMOUNT
          SummaryRowWidget(
            label: "Total Amount",
            value: "₹${finalTotal.toStringAsFixed(0)}",
            isTotal: true,
          ),
        ],
      ),
    );
  }
}