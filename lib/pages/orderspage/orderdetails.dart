import 'package:cloud_firestore/cloud_firestore.dart';
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

  final String orderId;

  @override
  State<OrderDetailWidget> createState() =>
      _OrderDetailWidgetState();
}

class _OrderDetailWidgetState extends State<OrderDetailWidget> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _orderFuture;

  // 🎨 COLORS (Gladskin Style)
  final bg = const Color(0xFFFDFBFC);
final primary = const Color(0xFF6F0562);
final accent = const Color(0xFFC06A83);
final textPrimary = const Color(0xFF1D212C);
final textSecondary = const Color(0xFF7A7A7A);

bool _allowCancel = false;

  @override
  void initState() {
    super.initState();
      _loadOrderSettings();
      _orderFuture = FirebaseFirestore.instance
    .collection("Orders")
    .doc(widget.orderId.toString())
    .get();
  }


  Future<void> _loadOrderSettings() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('orders')
        .get();

    if (!mounted) return;

    setState(() {
      _allowCancel = (doc.data()?['allow_cancel'] ?? false) as bool;
    });
  } catch (e) {
    debugPrint("Failed to load order settings: $e");

    if (!mounted) return;

    setState(() {
      _allowCancel = false;
    });
  }
}

  bool _canCancelOrder(Map<String, dynamic> order) {
  final status =
      (order["status"] ?? "").toString().toLowerCase();

  if (status == "cancelled" ||
      status == "completed") {
    return false;
  }

  final created =
      order["createdAt"] as Timestamp?;

  if (created == null) {
    return false;
  }

  final diff = DateTime.now()
      .difference(created.toDate())
      .inHours;

  return diff < 24;
}

Future<void> _cancelOrder() async {
  try {
    await FirebaseFirestore.instance
        .collection("Orders")
        .doc(widget.orderId.toString())
        .update({
      "status": "cancelled",
      "updatedAt": FieldValue.serverTimestamp(),
      "statusHistory": FieldValue.arrayUnion([
        {
          "status": "cancelled",
          "at": Timestamp.now(),
        }
      ]),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Order cancelled successfully"),
      ),
    );

    setState(() {
      _orderFuture = FirebaseFirestore.instance
          .collection("Orders")
          .doc(widget.orderId.toString())
          .get();
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    if (widget.orderId.isEmpty) {
  return const Scaffold(
    body: Center(child: Text("Invalid order ID")),
  );
}
    return FutureBuilder<DocumentSnapshot<Map<String,dynamic>>>(
      
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
    body: Center(child: Text("Failed to load order")),
  );
}

final doc = snapshot.data!;

if (!doc.exists || doc.data() == null) {
  return const Scaffold(
    body: Center(
      child: Text("Order not found"),
    ),
  );
}

final order = doc.data()!;
debugPrint(order.toString());
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
_buildTracking(order),
if (_allowCancel)
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
  // 🔹 HEADER
Widget _buildHeader(Map<String, dynamic> order) {
  final orderNumber =
      order["orderNumber"]?.toString() ??
      widget.orderId.toString();

  final status =
      (order["status"] ?? "processing")
          .toString()
          .toUpperCase();

  final total =
      (order["finalPayable"] ?? 0)
          .toString();

  final paymentMethod =
      order["paymentMethod"] ?? "";

  final paymentStatus =
      order["paymentStatus"] ?? "";

  Timestamp? createdAt =
      order["createdAt"] as Timestamp?;

  String placedOn = "";

  if (createdAt != null) {
    final date = createdAt.toDate();

    placedOn =
        "${date.day}/${date.month}/${date.year}";
  }

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.all(24),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF6F0562),
          Color(0xFF8C277B),
        ],
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        Text(
          "ORDER #$orderNumber",
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          "₹$total",
          style: GoogleFonts.lora(
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 18),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [

            _headerChip(status),

          ],
        ),

        if (placedOn.isNotEmpty) ...[
          const SizedBox(height: 18),

          Text(
            "Placed on $placedOn",
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _headerChip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius:
          BorderRadius.circular(30),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1,
      ),
    ),
  );
}

  // 🔹 CARD WRAPPER
Widget _card({
  required Widget child,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),

    padding: const EdgeInsets.all(20),

    decoration: BoxDecoration(
      color: Colors.white,

      borderRadius:
          BorderRadius.circular(24),

      border: Border.all(
        color: Colors.grey.shade200,
      ),

      boxShadow: [
        BoxShadow(
          color:
              Colors.black.withValues(
            alpha: 0.03,
          ),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),

    child: child,
  );
}

  // 🔹 ITEMS
  // 🔹 ITEMS
Widget _buildItems(Map<String, dynamic> order) {
  final List items =
      order["items"] as List? ?? [];

  return _card(
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          Icons.shopping_bag_outlined,
          "Items",
        ),

        const SizedBox(height: 10),

        const StyledDivider(
          thickness: 1,
          color: Colors.black12,
        ),

        ListView.separated(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item =
                items[index]
                    as Map<String, dynamic>;

            final image =
                item["image"] ?? "";

            final quantity =
                item["quantity"] ?? 1;

            final name =
                item["name"] ?? "";

            final packing =
                item["packing"] ?? "";

            final salePrice =
                (item["salePrice"] ?? 0)
                    .toString();

            final lineTotal =
                (item["lineTotal"] ?? 0)
                    .toString();

            return Container(
              padding:
                  const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color:
                    const Color(0xFFF8EEF7),

                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  /// PRODUCT IMAGE
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    child: Image.network(
                      image,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.image,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [

                        Text(
                          name,
                          style:
                              GoogleFonts.inter(
                            fontWeight:
                                FontWeight
                                    .w600,
                            fontSize: 15,
                          ),
                        ),

                        if (packing
                            .toString()
                            .isNotEmpty) ...[
                          const SizedBox(
                              height: 4),
                          Text(
                            packing,
                            style:
                                GoogleFonts.inter(
                              color:
                                  textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],

                        const SizedBox(
                            height: 8),

                        Row(
                          children: [

                            Text(
                              "Qty: $quantity",
                              style:
                                  GoogleFonts.inter(
                                color:
                                    textSecondary,
                              ),
                            ),

                            const Spacer(),

                            Text(
                              "₹$lineTotal",
                              style:
                                  GoogleFonts.inter(
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                          ],
                        ),
                      ],
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

Widget _sectionTitle(
  IconData icon,
  String title,
) {
  return Row(
    children: [
      Icon(
        icon,
        size: 18,
        color: primary,
      ),

      const SizedBox(width: 8),

      Text(
        title,
        style: GoogleFonts.inter(
          fontWeight:
              FontWeight.w700,
          fontSize: 16,
          color: textPrimary,
        ),
      ),
    ],
  );
}

  // 🔹 BILL SUMMARY
// 🔹 BILL SUMMARY
Widget _buildBillSummary(Map<String, dynamic> order) {
  Widget row(
    String label,
    dynamic value, {
    bool bold = false,
    Color? color,
  }) {
    final amount =
        (double.tryParse(value.toString()) ?? 0)
            .toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: bold
                  ? FontWeight.w700
                  : FontWeight.normal,
              color: color,
            ),
          ),
          Text(
            "₹$amount",
            style: GoogleFonts.inter(
              fontWeight: bold
                  ? FontWeight.w700
                  : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  final subtotal = (order["subtotal"] ?? 0) as num;
final tax = (order["tax"] ?? 0) as num;

final totalWithTax = subtotal + tax;

final shipping = (order["shipping"] ?? 0) as num;
final codCharge = (order["codCharge"] ?? 0) as num;
final couponDiscount = (order["couponDiscount"] ?? 0) as num;
final walletUsed = (order["walletUsed"] ?? 0) as num;
final grandTotal = order["finalPayable"] ?? 0;

final paymentMethod = order["paymentMethod"] ?? "";
  return _card(
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [

        _sectionTitle(
          Icons.receipt_long_outlined,
          "Bill Summary",
        ),

        const SizedBox(height: 10),

row(
  "Items",
  totalWithTax,
),

if (shipping > 0)
  row(
    "Shipping",
    shipping,
  ),

if (codCharge > 0)
  row(
    "Cash on Delivery",
    codCharge,
  ),

if (couponDiscount > 0)
  row(
    "Coupon Discount",
    -couponDiscount,
    color: Colors.green,
  ),

if (walletUsed > 0)
  row(
    "Wallet Used",
    -walletUsed,
    color: Colors.green,
  ),

const Divider(height: 28),

Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: const Color(0xFFF8EEF7),
    borderRadius: BorderRadius.circular(14),
  ),
  child: row(
    "Grand Total",
    grandTotal,
    bold: true,
  ),
),

        const SizedBox(height: 18),

        Row(
          children: [

            const Icon(
              Icons.payments_outlined,
              size: 18,
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Text(
                "Payment Method",
                style:
                    GoogleFonts.inter(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            Text(
              paymentMethod
                  .toString()
                  .toUpperCase(),
              style:
                  GoogleFonts.inter(
                fontWeight:
                    FontWeight.w700,
                color: primary,
              ),
            ),
          ],
        ),

        if (order["paymentStatus"] != null) ...[
          const SizedBox(height: 10),

          Row(
            children: [

              const Icon(
                Icons.verified_outlined,
                size: 18,
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Text(
                  "Payment Status",
                  style:
                      GoogleFonts.inter(
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              Text(
                order["paymentStatus"]
                    .toString()
                    .toUpperCase(),
                style:
                    GoogleFonts.inter(
                  fontWeight:
                      FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}
  // 🔹 ADDRESS
  // 🔹 SHIPPING ADDRESS
Widget _buildShippingAddress(Map<String, dynamic> order) {
  final shipping =
      order["shippingAddress"] as Map<String, dynamic>?;

  if (shipping == null) {
    return const SizedBox();
  }

  final name =
      "${shipping["first_name"] ?? ""} ${shipping["last_name"] ?? ""}"
          .trim();

  final phone = shipping["phone"] ?? "";

  final address1 = shipping["address_1"] ?? "";
  final address2 = shipping["address_2"] ?? "";
  final city = shipping["city"] ?? "";
  final state = shipping["state"] ?? "";
  final postcode = shipping["postcode"] ?? "";
  final country = shipping["country"] ?? "";

  return _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          Icons.location_on_outlined,
          "Shipping Address",
        ),

        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8EEF7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              if (name.isNotEmpty)
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),

              if (phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      phone,
                      style: GoogleFonts.inter(),
                    ),
                  ],
                ),
              ],

              if (address1.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  address1,
                  style: GoogleFonts.inter(),
                ),
              ],

              if (address2.isNotEmpty)
                Text(
                  address2,
                  style: GoogleFonts.inter(),
                ),

              const SizedBox(height: 6),

              Text(
                "$city, $state",
                style: GoogleFonts.inter(),
              ),

              Text(
                "$postcode, $country",
                style: GoogleFonts.inter(),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildTracking(Map<String, dynamic> order) {
  final status =
      (order["status"] ?? "processing")
          .toString()
          .toLowerCase();

  final history =
      (order["statusHistory"] as List? ?? []);

  final trackingNumber =
      order["trackingNumber"] ?? "";

  final courier =
      order["courierName"] ?? "";

  final trackingUrl =
      order["trackingUrl"] ?? "";

  final orderPlaced = true;

  final shipped =
      status == "shipped" ||
      status == "completed";

  final delivered =
      status == "completed";

  Widget step(
    bool reached,
    String historyKey,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: reached
                ? Colors.green
                : Colors.grey.shade300,
            child: Icon(
              reached ? Icons.check : icon,
              size: 16,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),

                if (reached)
                  Text(
                    _statusTime(
                      history,
                      historyKey,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  return _card(
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          Icons.local_shipping_outlined,
          "Order Status",
        ),

        const SizedBox(height: 20),

        step(
          orderPlaced,
          "processing",
          "Order Placed",
          Icons.shopping_bag,
        ),

        step(
          shipped,
          "shipped",
          "Shipped",
          Icons.local_shipping,
        ),

        step(
          delivered,
          "completed",
          "Delivered",
          Icons.home,
        ),

        if (shipped || delivered) ...[
          const Divider(height: 30),

          if (courier.toString().isNotEmpty)
            _trackingRow(
              "Courier",
              courier,
            ),

          if (trackingNumber
              .toString()
              .isNotEmpty)
            _trackingRow(
              "Tracking Number",
              trackingNumber,
            ),

          if (trackingUrl
              .toString()
              .isNotEmpty) ...[
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO:
                  // launchUrl(
                  // Uri.parse(trackingUrl),
                  // mode: LaunchMode.externalApplication,
                  // );
                },
                icon: const Icon(
                  Icons.open_in_new,
                ),
                label: const Text(
                  "Track Shipment",
                ),
              ),
            ),
          ],
        ],
      ],
    ),
  );
}

String _statusTime(
  List history,
  String status,
) {
  try {
    final item = history.firstWhere(
      (e) =>
          (e["status"] ?? "")
              .toString()
              .toLowerCase() ==
          status,
    );

    final ts =
        item["at"] as Timestamp?;

    if (ts == null) {
      return "";
    }

    final d = ts.toDate();

    return "${d.day}/${d.month}/${d.year}  ${d.hour}:${d.minute.toString().padLeft(2, "0")}";
  } catch (_) {
    return "";
  }
}

Widget _trackingRow(
  String title,
  String value,
) {
  return Padding(
    padding: const EdgeInsets.only(
      bottom: 10,
    ),
    child: Row(
      children: [

        SizedBox(
          width: 110,
          child: Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.grey,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

  // 🔹 CANCEL BUTTON
  // 🔹 CANCEL BUTTON
Widget _buildCancelSection(Map<String, dynamic> order) {
  final status =
      (order["status"] ?? "")
          .toString()
          .toLowerCase();

  final createdAt =
      order["createdAt"] as Timestamp?;

  bool canCancel = _allowCancel;

  if (status == "completed" ||
      status == "cancelled" ||
      status == "refunded") {
    canCancel = false;
  }

  if (createdAt != null) {
    final diff =
        DateTime.now().difference(
          createdAt.toDate(),
        );

    if (diff.inHours >= 24) {
      canCancel = false;
    }
  }

  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        ElevatedButton(
          onPressed: !canCancel
              ? null
              : () async {
                  final confirm =
                      await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text(
                        "Cancel Order",
                      ),
                      content: const Text(
                        "Are you sure you want to cancel this order?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(
                            context,
                            false,
                          ),
                          child: const Text(
                            "No",
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(
                            context,
                            true,
                          ),
                          child: const Text(
                            "Yes",
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  await FirebaseFirestore
                      .instance
                      .collection("Orders")
                      .doc(widget.orderId)
                      .update({
                    "status": "cancelled",
                    "updatedAt":
                        FieldValue.serverTimestamp(),
                    "statusHistory":
                        FieldValue.arrayUnion([
                      {
                        "status": "cancelled",
                        "at": Timestamp.now(),
                      }
                    ]),
                  });

                  if (!mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Order cancelled successfully",
                      ),
                    ),
                  );

                  setState(() {
                    _orderFuture =
                        FirebaseFirestore.instance
                            .collection("Orders")
                            .doc(widget.orderId
                                .toString())
                            .get();
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: canCancel
                ? Colors.red
                : Colors.grey.shade300,
            foregroundColor: canCancel
                ? Colors.white
                : Colors.black54,
            minimumSize:
                const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            "Cancel Order",
          ),
        ),

        const SizedBox(height: 8),

        Text(
          !_allowCancel
              ? "Order cancellation is disabled."
              : canCancel
                  ? "You can cancel within 24 hours."
                  : "Cancellation period expired.",
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