class FeeLine {
  final String name;
  final String total;

  FeeLine({
    required this.name,
    required this.total,
  });

  factory FeeLine.fromJson(Map<String, dynamic> json) {
    return FeeLine(
      name: json['name'] ?? '',
      total: json['total'] ?? '0',
    );
  }
}