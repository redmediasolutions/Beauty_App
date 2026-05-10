import 'package:flutter/material.dart';
import 'package:glowfit/models/singleorder.dart';
import 'package:glowfit/services/api.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:styled_divider/styled_divider.dart';

class OrderDetailWidget extends StatefulWidget {
  const OrderDetailWidget({
    super.key,
    required this.orderId,
  });

  final int? orderId;

  @override
  State<OrderDetailWidget> createState() => _OrderDetailWidgetState();
}

class _OrderDetailWidgetState extends State<OrderDetailWidget> {
  late Future<SingleOrder?> _orderFuture;

  // 🎨 COLORS (Gladskin Style)
  final bg = const Color(0xFFF7F7F5);
  final primary = const Color(0xFF1F3D2B);
  final accent = const Color(0xFF8FAF9F);
  final textPrimary = const Color(0xFF222222);
  final textSecondary = const Color(0xFF777777);

  @override
  void initState() {
    super.initState();
    _orderFuture = APIService.fetchSingleOrder(widget.orderId!);
  }

  bool _canCancelOrder(SingleOrder order) {
    if (order.status.toLowerCase() == 'cancelled' ||
        order.status.toLowerCase() == 'completed') {
      return false;
    }

    final createdAt = DateTime.tryParse(order.createdAt.toString());
    if (createdAt == null) return false;

    final diff = DateTime.now().difference(createdAt).inHours;
    return diff < 24;
  }

  Future<void> _cancelOrder(SingleOrder order) async {
    try {
      await APIService.cancelOrder(order.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order cancelled successfully")),
      );

      setState(() {
        _orderFuture = APIService.fetchSingleOrder(widget.orderId!);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to cancel order")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderId == null) {
      return const Scaffold(body: Center(child: Text('Invalid order ID')));
    }

    return FutureBuilder<SingleOrder?>(
      future: _orderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: bg,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('Failed to load order')),
          );
        }

        final order = snapshot.data!;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
    ),
            backgroundColor: bg,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
            title: Text(
              "Order Details",
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(order),
                _buildItems(order),
                _buildBillSummary(order),
                _buildShippingAddress(order),
                _buildCancelSection(order),
                const SizedBox(height: 80),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🔹 HEADER
  Widget _buildHeader(SingleOrder order) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order #${order.id}",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            order.status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 13,
              color: accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 CARD WRAPPER
  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  // 🔹 ITEMS
  Widget _buildItems(SingleOrder order) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Items",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const StyledDivider(
            thickness: 1,
            color: Colors.black12,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.lineItems.length,
            itemBuilder: (context, index) {
              final item = order.lineItems[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      "x${item.quantity}",
                      style: GoogleFonts.inter(color: textSecondary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "₹${item.total}",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔹 BILL SUMMARY
  Widget _buildBillSummary(SingleOrder order) {
    Widget row(String label, String value, {bool bold = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            Text(
              "₹${value}",
              style: GoogleFonts.inter(
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bill Summary",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          row("Subtotal", order.subtotal),
          for (final fee in order.feeLines) row(fee.name, fee.total),
          if (order.shippingTotal != "0")
            row("Shipping", order.shippingTotal),
          if (order.totalTax != "0") row("Tax", order.totalTax),
          const Divider(),
          row("Total", order.total, bold: true),
          const SizedBox(height: 6),
          row("Payment", order.paymentMethodTitle),
        ],
      ),
    );
  }

  // 🔹 ADDRESS
  Widget _buildShippingAddress(SingleOrder order) {
    final shipping = order.shipping;

    if (shipping == null || shipping.address1.isEmpty) {
      return const SizedBox();
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Shipping Address",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Text(shipping.address1),
          if (shipping.address2.isNotEmpty) Text(shipping.address2),
          Text("${shipping.city}, ${shipping.state}"),
          Text("${shipping.postcode}, ${shipping.country}"),
        ],
      ),
    );
  }

  // 🔹 CANCEL BUTTON
  Widget _buildCancelSection(SingleOrder order) {
    final canCancel = _canCancelOrder(order);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: canCancel
                ? () async {
                    final confirm = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Cancel Order"),
                        content: const Text(
                            "Are you sure you want to cancel this order?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text("No"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text("Yes"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      _cancelOrder(order);
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  canCancel ? Colors.red : Colors.grey.shade300,
              foregroundColor:
                  canCancel ? Colors.white : Colors.black54,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text("Cancel Order"),
          ),
          const SizedBox(height: 8),
          Text(
            canCancel
                ? "You can cancel within 24 hours"
                : "Cancellation period expired",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: canCancel
                  ? Colors.grey
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}