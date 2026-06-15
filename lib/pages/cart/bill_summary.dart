import 'package:flutter/material.dart';
import 'summary_row_widget.dart';

class BillSummaryWidget extends StatelessWidget {
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final bool usePoints;
  final double couponDiscount;
  final double codCharges;
  final double totalMrp;

  final Map<int, double> gstBreakup;

  const BillSummaryWidget({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.usePoints,
    required this.couponDiscount,
    required this.codCharges,
    required this.totalMrp,
    required this.gstBreakup,
  });

  @override
  Widget build(BuildContext context) {
    final double pointsDiscount =
        usePoints ? 50 : 0;

    final double totalDiscount =
        couponDiscount +
        pointsDiscount;

    final double saleTotal =
        subtotal;

    final double discountedSubtotal =
        (saleTotal - totalDiscount)
            .clamp(0.0, double.infinity);

    final sortedGstEntries =

    gstBreakup.entries.toList()

      ..sort(

        (a, b) =>

            a.key.compareTo(b.key),

      );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          /// MRP
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

          /// SALE TOTAL
          SummaryRowWidget(
            label: "Sale Total",
            value:
                "₹${saleTotal.toStringAsFixed(0)}",
          ),

          /// COUPON
          if (couponDiscount > 0) ...[
            const SizedBox(height: 10),
            SummaryRowWidget(
              label: "Coupon Discount",
              value:
                  "-₹${couponDiscount.toStringAsFixed(0)}",
            ),
          ],

          /// WALLET
          if (pointsDiscount > 0) ...[
            const SizedBox(height: 10),
            SummaryRowWidget(
              label: "Wallet Discount",
              value:
                  "-₹${pointsDiscount.toStringAsFixed(0)}",
            ),
          ],

          const Divider(height: 24),

          /// SUBTOTAL AFTER DISCOUNT
          SummaryRowWidget(
            label: "Subtotal",
            value:
                "₹${discountedSubtotal.toStringAsFixed(0)}",
            isSubtotal: true,
          ),

          /// GST BREAKUP
          if (gstBreakup.isNotEmpty) ...[
  const SizedBox(height: 14),

  ...sortedGstEntries.map(
    (entry) => Padding(
      padding: const EdgeInsets.only(
        top: 10,
      ),
      child: SummaryRowWidget(
        label: "GST (${entry.key}%)",
        value:
            "+₹${entry.value.toStringAsFixed(2)}",
      ),
    ),
  ),

  const SizedBox(height: 10),

  SummaryRowWidget(
    label: "Total GST",
    value:
        "₹${tax.toStringAsFixed(2)}",
  ),
],

          const SizedBox(height: 10),

          /// SHIPPING
          SummaryRowWidget(
            label: "Shipping",
            value:
                shipping <= 0
                    ? "FREE"
                    : "+₹${shipping.toStringAsFixed(0)}",
          ),

          /// COD
          if (codCharges > 0) ...[
            const SizedBox(height: 10),
            SummaryRowWidget(
              label: "COD Charges",
              value:
                  "+₹${codCharges.toStringAsFixed(0)}",
            ),
          ],

          const Divider(height: 30),

          /// GRAND TOTAL
          SummaryRowWidget(
            label: "Total Amount",
            value:
                "₹${total.toStringAsFixed(0)}",
            isTotal: true,
          ),
        ],
      ),
    );
  }
}