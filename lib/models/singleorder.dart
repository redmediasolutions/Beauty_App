

import 'package:glowfit/models/feemodel.dart';
import 'package:glowfit/models/lineitem.dart';
import 'package:glowfit/models/shippingaddress.dart';

class SingleOrder {
  final int id;
  final String status;
  final String total;
  final DateTime createdAt;
  final List<LineItem> lineItems;
  final ShippingAddress? shipping;

  final String subtotal;
  final String totalTax;
  final String shippingTotal;
  final List<FeeLine> feeLines;

  final String paymentMethodTitle; // 👈 add this too (useful in UI)

  SingleOrder({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.lineItems,
    this.shipping,
    required this.subtotal,
    required this.totalTax,
    required this.shippingTotal,
    required this.feeLines,
    required this.paymentMethodTitle,
  });
factory SingleOrder.fromJson(Map<String, dynamic> json) {

final double total =
      double.tryParse(json['total']?.toString() ?? '0') ?? 0.0;

  final double shipping =
      double.tryParse(json['shipping_total']?.toString() ?? '0') ?? 0.0;

  final double totalTax =
      double.tryParse(json['total_tax']?.toString() ?? '0') ?? 0.0;

  final double discount =
      double.tryParse(json['discount_total']?.toString() ?? '0') ?? 0.0;

  // 🔥 Calculate total fees
  double totalFees = 0.0;
  final feeLinesRaw = json['fee_lines'] as List? ?? [];

  for (final fee in feeLinesRaw) {
    final feeTotal =
        double.tryParse(fee['total']?.toString() ?? '0') ?? 0.0;
    totalFees += feeTotal;
  }

  // 🔥 Final Correct Subtotal
  final double computedSubtotal =
      total - shipping - totalTax - totalFees + discount;


  return SingleOrder(
    id: json['id'] as int,
    status: json['status'] ?? '',
    total: json['total'] ?? '0',
    createdAt: DateTime.tryParse(
          json['date_created'] ?? '',
        ) ??
        DateTime.now(),
    subtotal: computedSubtotal.toStringAsFixed(2),
    totalTax: json['total_tax'] ?? '0',
    shippingTotal: json['shipping_total'] ?? '0',
    feeLines: (json['fee_lines'] as List?)
            ?.map((e) => FeeLine.fromJson(e))
            .toList() ??
        [],
    lineItems: (json['line_items'] as List<dynamic>? ?? [])
        .map((e) => LineItem.fromJson(e))
        .toList(),
    shipping: json['shipping'] != null
        ? ShippingAddress.fromJson(
            json['shipping'] as Map<String, dynamic>,
          )
        : null,
    paymentMethodTitle:
        json['payment_method_title'] ?? '',
  );
}

  /// 📅 Formatted order date
  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  /// 📦 Total items count
  int get totalItems {
    return lineItems.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
  }
}