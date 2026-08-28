class CategoryModel {
  final int id;
  final String name;
  final String image;
  final int parent;
  final String description;

  CategoryModel({
    required this.id,
    required this.name,
    required this.image,
    required this.parent,
    this.description = '',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image']?['src'] ?? '',
      parent: json['parent'] ?? 0,
      description: json['description'] ?? '',
    );
  }
}