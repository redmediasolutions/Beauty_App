import 'package:flutter/material.dart';
import 'package:glowfit/models/orderstatus.dart';
import 'package:glowfit/models/singleorder.dart';
import 'package:glowfit/pages/orderspage/orderscard.dart';
import 'package:glowfit/services/api.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  /// 🔹 Status → UI mapper
  OrderStatusUI _statusConfig(String status) {
    switch (status) {
      case 'completed':
        return OrderStatusUI(
          label: 'Delivered',
          color: const Color(0xFF22C55E),
          bgColor: const Color(0xFFDCFCE7),
          icon: Icons.done,
        );

      case 'processing':
        return OrderStatusUI(
          label: 'Processing',
          color: const Color(0xFFF97316),
          bgColor: const Color(0xFFFFEDD5),
          icon: Icons.local_shipping,
        );

      case 'cancelled':
        return OrderStatusUI(
          label: 'Cancelled',
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
      body: StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance
      .collection('Orders')
      .where('uid', isEqualTo: user.uid)
      //.orderBy('createdAt', descending: true)
      .snapshots(),

  builder: (context, snap) {
    debugPrint("📡 [OrdersPage] Firestore stream triggered");

    if (snap.connectionState == ConnectionState.waiting) {
      debugPrint("⏳ [OrdersPage] Waiting for Firestore data...");
      return const Center(child: CircularProgressIndicator());
    }

    if (snap.hasError) {
      debugPrint("❌ [OrdersPage] Firestore Error: ${snap.error}");
      return const Center(child: Text("Error loading orders"));
    }

    final docs = snap.data?.docs ?? [];

    debugPrint("📦 [OrdersPage] Orders fetched: ${docs.length}");
    debugPrint("👤 [OrdersPage] Current UID: ${user.uid}");

    if (docs.isEmpty) {
      debugPrint("⚠️ [OrdersPage] No orders found for user");
      return const Center(child: Text("No orders yet"));
    }

    /// 🔍 PRINT EACH FIRESTORE ORDER
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      debugPrint("🧾 [Firestore Order]");
      debugPrint("   📄 Doc ID: ${doc.id}");
      debugPrint("   🆔 WooOrderId (docId): ${doc.id}");
      debugPrint("   👤 UID: ${data['uid']}");
      debugPrint("   💰 Subtotal: ${data['subtotal']}");
      debugPrint("   🚚 Shipping: ${data['shipping']}");
      debugPrint("   🧾 Tax: ${data['tax']}");
      debugPrint("   📌 Status: ${data['status']}");
      debugPrint("   🕒 CreatedAt: ${data['createdAt']}");
    }

    /// 🔥 Extract Woo Order IDs
    final wooIds = docs
        .map((d) => int.tryParse(d.id))
        .whereType<int>()
        .toList();

    debugPrint("🔢 [OrdersPage] Woo Order IDs: $wooIds");

    /// 🔥 STEP 2: CALL WOO API
    return FutureBuilder<List<SingleOrder>>(
      future: APIService.fetchOrdersByIds(wooIds),

      builder: (context, orderSnap) {
        debugPrint("🌐 [OrdersPage] Woo API Future triggered");

        if (orderSnap.connectionState == ConnectionState.waiting) {
          debugPrint("⏳ [OrdersPage] Waiting for Woo API...");
          return const Center(child: CircularProgressIndicator());
        }

        if (orderSnap.hasError) {
          debugPrint("❌ [OrdersPage] Woo API Error: ${orderSnap.error}");
          return const Center(child: Text("Error loading orders"));
        }

        final orders = orderSnap.data ?? [];

        debugPrint("✅ [OrdersPage] Woo orders fetched: ${orders.length}");

        if (orders.isEmpty) {
          debugPrint("⚠️ [OrdersPage] Woo returned empty list");
          return const Center(child: Text("No orders found"));
        }

        /// 🔍 PRINT EACH WOO ORDER
        for (var order in orders) {
          debugPrint("🧾 [Woo Order]");
          debugPrint("   🆔 ID: ${order.id}");
          debugPrint("   📌 Status: ${order.status}");
          debugPrint("   📅 Date: ${order.formattedDate}");
          debugPrint("   📦 Items: ${order.totalItems}");
          debugPrint("   💰 Total: ${order.total}");
        }

        /// 🔥 STEP 3: UI LIST
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),

          itemBuilder: (context, index) {
            final order = orders[index];
            final statusUi = _statusConfig(order.status);

            debugPrint("🎯 [OrdersPage] Rendering order index: $index (ID: ${order.id})");

            return GestureDetector(
              onTap: () {
                debugPrint("➡️ Navigating to order detail: ${order.id}");
                context.go('/order/${order.id}');
              },

              child: OrderCard(
                odericon: Icon(statusUi.icon),
                orderId: order.id,
                date: order.formattedDate,
                status: statusUi.label,
                statusColor: statusUi.color,
                iconBg: statusUi.bgColor,
                items: '${order.totalItems} Items',
                amount: '₹${order.total}',
                delivery: '',
                showTrack: order.status == 'processing',
                showReorder: order.status == 'completed',
              ),
            );
          },
        );
      },
    );
  },
),
    );
  }
}