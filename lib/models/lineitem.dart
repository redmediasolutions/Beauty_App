class LineItem {
  final int productId;
  final String name;
  final int quantity;
  final String total;

  LineItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.total, 
  });

  factory LineItem.fromJson(Map<String, dynamic> json) {



  return LineItem(
    productId: json['product_id'] ?? 0,
    name: json['name'] ?? '',
    quantity: json['quantity'] ?? 0,
    total: json['total']?.toString() ?? '0',
  );
}


  String? operator [](String other) {
    return null;
  }
}
