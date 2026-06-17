import 'package:flutter/material.dart';
import 'summary_row_widget.dart';

class BillSummaryWidget extends StatefulWidget {
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
  State<BillSummaryWidget> createState() => _BillSummaryWidgetState();
}

class _BillSummaryWidgetState extends State<BillSummaryWidget> {
  bool _showGstBreakup = false;

  @override
  Widget build(BuildContext context) {
    final double pointsDiscount = widget.usePoints ? 50 : 0;

    final double saleTotal = widget.subtotal;

    final double grandTotal =
        saleTotal +
        widget.tax +
        widget.shipping +
        widget.codCharges;

    final double payableTotal =
        grandTotal -
        widget.couponDiscount -
        pointsDiscount;

    final sortedGstEntries = widget.gstBreakup.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MRP",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              Text(
                "₹${widget.totalMrp.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// SUBTOTAL
          SummaryRowWidget(
            label: "Subtotal",
            value: "₹${saleTotal.toStringAsFixed(2)}",
            isSubtotal: true,
          ),

          const SizedBox(height: 12),

          /// GST SECTION
          if (widget.gstBreakup.isNotEmpty) ...[
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                setState(() {
                  _showGstBreakup = !_showGstBreakup;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Total GST",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _showGstBreakup
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    Text(
                      "₹${widget.tax.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _showGstBreakup
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                children: sortedGstEntries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      top: 8,
                    ),
                    child: 
                    
                    Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    SummaryRowWidget(
      label: "GST (${entry.key}%)",
      value: "₹${entry.value.toStringAsFixed(2)}",
    ),

    if (entry.key == 5)
      const Padding(
        padding: EdgeInsets.only(
          left: 4,
          top: 2,
        ),
        child: Text(
          "Applicable on Soap, Shampoo & Hair Oil",
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
  ],
),
                  );
                }).toList(),
              ),
              secondChild: const SizedBox.shrink(),
            ),
          ],

          const SizedBox(height: 12),

          /// SHIPPING
          SummaryRowWidget(
            label: "Shipping",
            value: widget.shipping <= 0
                ? "FREE"
                : "+₹${widget.shipping.toStringAsFixed(0)}",
          ),

          /// COD
          if (widget.codCharges > 0) ...[
            const SizedBox(height: 10),
            SummaryRowWidget(
              label: "COD Charges",
              value:
                  "+₹${widget.codCharges.toStringAsFixed(0)}",
            ),
          ],

          const Divider(height: 30),

          /// GRAND TOTAL
          SummaryRowWidget(
            label: "Grand Total",
            value: "₹${grandTotal.toStringAsFixed(2)}",
            isTotal: true,
          ),

          /// COUPON DISCOUNT
          if (widget.couponDiscount > 0) ...[
            const SizedBox(height: 10),
            SummaryRowWidget(
              label: "Coupon Discount",
              value:
                  "-₹${widget.couponDiscount.toStringAsFixed(2)}",
            ),
          ],

          /// WALLET DISCOUNT
          if (pointsDiscount > 0) ...[
            const SizedBox(height: 10),
            SummaryRowWidget(
              label: "Wallet Discount",
              value:
                  "-₹${pointsDiscount.toStringAsFixed(2)}",
            ),
          ],

          const Divider(height: 30),

          /// PAYABLE TOTAL
          SummaryRowWidget(
            label: "Payable Total",
            value: "₹${payableTotal.toStringAsFixed(2)}",
            isTotal: true,
          ),
        ],
      ),
    );
  }
}