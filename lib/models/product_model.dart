class Productsmodel {
  final int id;
  final String name;
  final String? brand; // Used for general brand display
  final String? image;
  final List<String> galleryImages;
  final String description;
  final String? manufactured; // Specifically for the "Manufacturer" field
  final String? composition;
  final String? packagesize;
  final String categories;
  final String? sideeeffects;
  final String? working;
  final double? regularPrice;
  final double? salePrice;
  final List<int> categoryIds;
  final bool isNotForSale;
  final bool canAddToCart;

  Productsmodel({
    required this.id,
    required this.name,
    this.brand,
    this.image,
    required this.galleryImages,
    required this.description,
    required this.categories,
    this.sideeeffects,
    this.working,
    this.regularPrice,
    this.salePrice,
    required this.categoryIds,
    required this.isNotForSale,
    required this.canAddToCart,
    this.manufactured,
    this.composition,
    this.packagesize,
  });

  factory Productsmodel.fromJson(Map<String, dynamic> json) {
    String? sideffects;
    String? howdoesitwork;
    String? brandValue =
        json['name'] ?? json['manufacturer'] ?? json['brands'] ?? '';

    String? compositionValue =json['composition_meta']?.toString() ?? json['composition']?.toString();

    String? packageValue =json['package_meta']?.toString() ?? json['package']?.toString();

    // 2. BRANDS ARRAY (For plugin data like Steris)
    if (json['brands'] is List && (json['brands'] as List).isNotEmpty) {
      final brandList = json['brands'] as List;
      final firstBrand = brandList.first;
      if (firstBrand is Map && firstBrand['name'] != null) {
        brandValue = firstBrand['name'].toString();
      }
    }

    // 3. NESTED META_DATA (Fallback for Standard WooCommerce API)
    if (json['meta_data'] is List) {
      for (final item in json['meta_data']) {
        if (item is Map<String, dynamic>) {
          final key = item['key'];
          final value = item['value'];

          switch (key) {
            case 'side_effects':
              sideffects = _cleanHtml(value);
              break;
            case 'how_does_it_work':
              howdoesitwork = _cleanHtml(value);
              break;
            case 'composition':
              compositionValue ??= _cleanHtml(value);
              break;
            case 'package':
              packageValue ??= _cleanHtml(value);
              break;
            case 'manufacturer':
            case 'brands':
              brandValue ??= value?.toString();
              break;
          }
        }
      }
    }

    // 4. IMAGE HANDLING
    List<String> galleryImages = [];

if (json['images'] is List) {
  galleryImages = (json['images'] as List)
      .map(
        (img) => img is Map ? (img['src']?.toString() ?? '') : img.toString(),
      )
      .where((url) => url.isNotEmpty)
      .toList();
} else if (json['image'] != null && json['image'].toString().isNotEmpty) {
  galleryImages.add(json['image'].toString());
}

// --- Fallback Logic ---
if (galleryImages.isEmpty) {
  galleryImages.add('https://img.freepik.com/free-photo/cosmetic-male-beauty-products-with-display_23-2150435210.jpg?semt=ais_hybrid&w=740&q=80');
}

    // 5. CATEGORY HANDLING
    final List categoriesList = json['categories'] is List
        ? json['categories']
        : [];
    final List<int> categoryIds = categoriesList
        .map(
          (e) =>
              int.tryParse(e is Map ? e['id'].toString() : e.toString()) ?? 0,
        )
        .toList();

    String categoryName = '';
    if (categoriesList.isNotEmpty) {
      categoryName = categoriesList[0] is Map
          ? (categoriesList[0]['name']?.toString() ?? '')
          : categoriesList[0].toString();
    }

    return Productsmodel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      description: _cleanHtml(json['description'] ?? '') ?? '',
      categories: categoryName,
      sideeeffects: sideffects,
      working: howdoesitwork,
      manufactured: brandValue,
      brand: brandValue, 
      composition: compositionValue,
      packagesize: packageValue,
      image: galleryImages.isNotEmpty ? galleryImages.first : null,
      galleryImages: galleryImages,
      regularPrice: _parseDouble(json['regular_price'] ?? json['price']),
      salePrice: _parseDouble(json['sale_price']),
      categoryIds: categoryIds,
      isNotForSale: categoryIds.contains(94),
      canAddToCart:
          json['stock_status'] == 'instock' && !categoryIds.contains(94),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null || value == '') return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String? _cleanHtml(dynamic value) {
    if (value == null || value == '') return null;
    String clean = value
        .toString()
        .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
        .trim();
    return clean.isEmpty ? null : clean;
  }
}
