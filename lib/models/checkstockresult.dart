class StockCheckResult {
  final bool hasOutOfStock;
  final List<OutOfStockItem> items;

  const StockCheckResult({
    required this.hasOutOfStock,
    required this.items,
  });
}

class OutOfStockItem {
  final int productId;
  final String name;
  final String reason;

  /// Firestore cart document id
  final String? docId;

  const OutOfStockItem({
    required this.productId,
    required this.name,
    required this.reason,
    this.docId,
  });
}