class CategoryModel {
  final int id;
  final String name;
  final String image;
  final int parent;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.parent,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image']?['src'] ?? '',
      parent: json['parent'] ?? 0,
    );
  }
}