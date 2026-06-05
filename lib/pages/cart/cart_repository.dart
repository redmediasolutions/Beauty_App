import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    String? couponId,

  String? couponCode,

  double couponDiscount = 0,
  }) async {
    final result = await functions
        .httpsCallable('createSecureOrder')
        .call({
      'paymentMethod': paymentMethod,
      'useWallet': useWallet,
    });

    return Map<String, dynamic>.from(
      result.data,
    );
  }

  /// ======================================================
  /// FINALIZE ORDER
  /// ======================================================

Future<Map<String, dynamic>> finalizeOrder({
  required String? razorpayOrderId,
  required String? razorpayPaymentId,
  required String? razorpaySignature,
  required bool useWallet,
  required Map<String, dynamic> billing,
  required Map<String, dynamic> shipping,

  // ✅ ADD THESE
  required String? couponId,
  required String? couponCode,
  required double couponDiscount,
}) async {

  final result = await functions
      .httpsCallable('finalizeOrder')
      .call({

    'razorpayOrderId':
        razorpayOrderId,

    'razorpayPaymentId':
        razorpayPaymentId,

    'razorpaySignature':
        razorpaySignature,

    'useWallet':
        useWallet,

    'billing':
        billing,

    'shipping':
        shipping,

    // ✅ PASS COUPON DATA
    'couponId':
        couponId,

    'couponCode':
        couponCode,

    'couponDiscount':
        couponDiscount,
  });

  return Map<String, dynamic>.from(
    result.data,
  );
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

    for (var doc in docs) {
      final data =
          doc.data() as Map<String, dynamic>;

      double price = double.tryParse(
            data['salePrice']
                    ?.toString() ??
                '0',
          ) ??
          0;

      int qty =
          (data['quantity'] ?? 1).toInt();

      subtotal += price * qty;
    }

    final shipping =
        subtotal <=
                (rates[
                        'freeShippingThreshold'] ??
                    500)
            ? (rates[
                        'shippingBelowThreshold'] ??
                    49)
                .toDouble()
            : (rates[
                        'shippingAboveThreshold'] ??
                    0)
                .toDouble();

    final tax = subtotal *
        (rates['taxPercentage'] ?? 0.05);

    final total =
        subtotal + shipping + tax;

    return {
      "subtotal": subtotal,
      "shipping": shipping,
      "tax": tax,
      "total": total,
    };
  }
}