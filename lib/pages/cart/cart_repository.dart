import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartRepository {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseFunctions functions =
      FirebaseFunctions.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  /// ======================================================
  /// FETCH RATES
  /// ======================================================

  Future<Map<String, dynamic>> fetchRates({
    required String paymentMethod,
  }) async {
    final result = await functions
        .httpsCallable('getCartRates')
        .call({
      'paymentMethod': paymentMethod,
    });

    return Map<String, dynamic>.from(
      result.data,
    );
  }

  /// ======================================================
  /// CREATE ORDER
  /// ======================================================

Future<Map<String, dynamic>> createSecureOrder({
  required String paymentMethod,
  required bool useWallet,
  double walletAmount = 0,
  String? couponId,
  String? couponCode,
  double couponDiscount = 0,
}) async {
  debugPrint("===== CREATE ORDER REQUEST =====");
  debugPrint("paymentMethod=$paymentMethod");
  debugPrint("useWallet=$useWallet");
  debugPrint("walletAmount=$walletAmount");
  debugPrint("couponId=$couponId");
  debugPrint("couponCode=$couponCode");
  debugPrint("couponDiscount=$couponDiscount");
  debugPrint("===============================");

  final result = await functions
      .httpsCallable('createSecureOrder')
      .call({
        'paymentMethod': paymentMethod,
        'useWallet': useWallet,
        'walletAmount': walletAmount,
        'couponId': couponId,
        'couponCode': couponCode,
        'couponDiscount': couponDiscount,
      });

  return Map<String, dynamic>.from(result.data);
}

  /// ======================================================
  /// FINALIZE ORDER
  /// ======================================================

Future<Map<String, dynamic>> finalizeOrder({
  required String? razorpayOrderId,
  required String? razorpayPaymentId,
  required String? razorpaySignature,
  required bool useWallet,
  required double walletAmount,
  required Map<String, dynamic> billing,
  required Map<String, dynamic> shipping,

  // Coupon
  required String? couponId,
  required String? couponCode,
  required double couponDiscount,
}) async {
  final result = await functions
      .httpsCallable('finalizeOrder')
      .call({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,

        'useWallet': useWallet,
        'walletAmount': walletAmount,

        'billing': billing,
        'shipping': shipping,

        'couponId': couponId,
        'couponCode': couponCode,
        'couponDiscount': couponDiscount,
      });

  return Map<String, dynamic>.from(result.data);
}

  /// ======================================================
  /// UPDATE QUANTITY
  /// ======================================================

  Future<void> updateQty({
    required String docId,
    required int delta,
  }) async {
    final user = auth.currentUser;

    if (user == null) return;

    final docRef = firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(docId);

    await firestore.runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(docRef);

        if (!snapshot.exists) return;

        int currentQty =
            (snapshot.data()?['quantity'] ?? 1);

        int newQty = currentQty + delta;

        if (newQty <= 0) {
          transaction.delete(docRef);
        } else {
          transaction.update(
            docRef,
            {'quantity': newQty},
          );
        }
      },
    );
  }

  /// ======================================================
  /// REMOVE ITEM
  /// ======================================================

  Future<void> removeItem(
    String docId,
  ) async {
    final user = auth.currentUser;

    if (user == null) return;

    await firestore
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(docId)
        .delete();
  }

  /// ======================================================
  /// CALCULATE TOTALS
  /// ======================================================

  Map<String, double> calculateTotals({
  required List docs,
  required Map<String, dynamic> rates,
}) {
  double subtotal = 0;

  for (final doc in docs) {
    final data = doc.data() as Map<String, dynamic>;

    final double salePrice =
        (data['salePrice'] as num?)?.toDouble() ?? 0;

    final int qty =
        (data['quantity'] as num?)?.toInt() ?? 1;

    subtotal += salePrice * qty;
  }

  final double shipping =
      subtotal <=
              ((rates['freeShippingThreshold'] ?? 500) as num)
          ? ((rates['shippingBelowThreshold'] ?? 49) as num)
              .toDouble()
          : ((rates['shippingAboveThreshold'] ?? 0) as num)
              .toDouble();

  return {
    "subtotal": double.parse(
      subtotal.toStringAsFixed(2),
    ),
    "shipping": double.parse(
      shipping.toStringAsFixed(2),
    ),
  };
}

Future<void> addFreeGift({

  required int productId,

  required String productName,

  required String image,

  int quantity = 1,

}) async {

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {

    throw Exception("User not logged in");

  }

  final cartRef = FirebaseFirestore.instance

      .collection('carts')

      .doc(user.uid)

      .collection('items');

  final existing = await cartRef

      .where('productId', isEqualTo: productId)

      .limit(1)

      .get();

  if (existing.docs.isNotEmpty) {

    return;

  }

  await cartRef.add({

    'productId': productId,

    'name': productName,

    'image': image,

    'quantity': quantity,

    // Gift flags

    'isFreeGift': true,

    'freeGift': true,

    // Pricing

    'mrp': 0,

    'salePrice': 0,

    'taxRate': 0,

    'createdAt': FieldValue.serverTimestamp(),

  });

  print("🎁 Free gift added to cart");

}
}