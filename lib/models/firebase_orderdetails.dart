import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:glowfit/models/order_itemmodel.dart';

class FirebaseOrder {
  final String id;
  final String orderNumber;

  final String status;
  final String paymentStatus;
  final String paymentMethod;

  final double subtotal;
  final double shipping;
  final double tax;
  final double codCharge;
  final double total;

  final double couponDiscount;
  final double walletUsed;

  final Timestamp? createdAt;

  final List<OrderItem> items;

  final Map<String, dynamic> billing;
  final Map<String, dynamic> shippingAddress;

  final String? trackingNumber;
  final String? trackingUrl;
  final String? courierName;

  final List<dynamic> statusHistory;

  FirebaseOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotal,
    required this.shipping,
    required this.tax,
    required this.codCharge,
    required this.total,
    required this.couponDiscount,
    required this.walletUsed,
    required this.createdAt,
    required this.items,
    required this.billing,
    required this.shippingAddress,
    required this.trackingNumber,
    required this.trackingUrl,
    required this.courierName,
    required this.statusHistory,
  });
}
