import 'package:flutter/material.dart';
import 'package:glowfit/models/orderstatus.dart';
import 'package:glowfit/pages/orderspage/orderscard.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  /// 🔹 Status → UI mapper
  OrderStatusUI _statusConfig(String status) {
  switch (status.toLowerCase()) {
    case "processing":
      return OrderStatusUI(
        label: "Processing",
        color: const Color(0xFFF97316),
        bgColor: const Color(0xFFFFEDD5),
        icon: Icons.hourglass_top,
      );

    case "packed":
      return OrderStatusUI(
        label: "Packed",
        color: Colors.deepPurple,
        bgColor: Colors.deepPurple.shade50,
        icon: Icons.inventory_2,
      );

    case "shipped":
      return OrderStatusUI(
        label: "Shipped",
        color: Colors.blue,
        bgColor: Colors.blue.shade50,
        icon: Icons.local_shipping,
      );

    case "out_for_delivery":
      return OrderStatusUI(
        label: "Out for Delivery",
        color: Colors.indigo,
        bgColor: Colors.indigo.shade50,
        icon: Icons.delivery_dining,
      );

    case "completed":
    case "delivered":
      return OrderStatusUI(
        label: "Delivered",
        color: const Color(0xFF22C55E),
        bgColor: const Color(0xFFDCFCE7),
        icon: Icons.check_circle,
      );

    case "cancelled":
      return OrderStatusUI(
        label: "Cancelled",
        color: const Color(0xFFEF4444),
        bgColor: const Color(0xFFFEE2E2),
        icon: Icons.cancel,
      );

    default:
      return OrderStatusUI(
        label: status.toUpperCase(),
        color: Colors.grey,
        bgColor: Colors.grey.shade200,
        icon: Icons.receipt_long,
      );
  }
}

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please login")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F9),
      appBar: AppBar(
        title: const Text("My Orders"),
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
      ),

      /// 🔥 STEP 1: GET ORDER IDS FROM FIRESTORE
body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  stream: FirebaseFirestore.instance
      .collection("Orders")
      .where("uid", isEqualTo: user.uid)
      .orderBy("createdAt", descending: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(snapshot.error.toString()),
      );
    }

    final docs = snapshot.data?.docs ?? [];

    if (docs.isEmpty) {
      return const Center(
        child: Text("No orders yet"),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final order = docs[index].data();

        final status =
            (order["status"] ?? "processing")
                .toString();

        final statusUi =
            _statusConfig(status);

        final createdAt =
            order["createdAt"] as Timestamp?;

        final date = createdAt == null
            ? "-"
            : "${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}";

        final items =
            order["totalQuantity"] ??
                order["itemCount"] ??
                0;

        final invoiceNumber =
    (order["orderNumber"] ?? "GLAD---")
        .toString();

return GestureDetector(
  onTap: () {
    context.go("/order/${docs[index].id}");
  },
  child: OrderCard(
    onTap: () => context.push("/order/${docs[index].id}"),
    odericon: Icon(statusUi.icon),

    // 👇 Show invoice number instead of Woo order ID
    orderId: invoiceNumber,

    date: date,
    status: statusUi.label,
    statusColor: statusUi.color,
    iconBg: statusUi.bgColor,
    items: "$items Items",
    amount:
        "${order["finalPayable"] ?? order["grossTotal"] ?? 0}",
    delivery: "",
    showTrack:
        status != "completed" &&
        status != "cancelled",
    showReorder:
        status == "completed",
  ),
);
      },
    );
  },
),
    );
  }
}