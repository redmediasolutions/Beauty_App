class OrderItem {
  final int productId;
  final String name;
  final String image;
  final String brand;
  final String packing;

  final int quantity;

  final double mrp;
  final double salePrice;

  final double lineSubtotal;
  final double lineTax;
  final double lineTotal;

  final double taxRate;
  final String taxClass;
  final String taxStatus;

  OrderItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.brand,
    required this.packing,
    required this.quantity,
    required this.mrp,
    required this.salePrice,
    required this.lineSubtotal,
    required this.lineTax,
    required this.lineTotal,
    required this.taxRate,
    required this.taxClass,
    required this.taxStatus,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double parse(dynamic value) =>
        double.tryParse(value.toString()) ?? 0;

    return OrderItem(
      productId: json["productId"] ?? 0,
      name: json["name"] ?? "",
      image: json["image"] ?? "",
      brand: json["brand"] ?? "",
      packing: json["packing"] ?? "",
      quantity: json["quantity"] ?? 1,
      mrp: parse(json["mrp"]),
      salePrice: parse(json["salePrice"]),
      lineSubtotal: parse(json["lineSubtotal"]),
      lineTax: parse(json["lineTax"]),
      lineTotal: parse(json["lineTotal"]),
      taxRate: parse(json["taxRate"]),
      taxClass: json["taxClass"] ?? "",
      taxStatus: json["taxStatus"] ?? "",
    );
  }
}