class Productsmodel {
  final int id;

  final String name;

  final String slug;

  final String? brand;

  final String? image;

  final List<String> galleryImages;

  final String description;

  final String? manufactured;

  final String? composition;

  final String? packagesize;

  final String categories;

  final String? sideeeffects;

  final String? working;

  // =====================================
  // PRICING
  // =====================================

  final double? regularPrice;

  final double? salePrice;

  // =====================================
  // TAX
  // =====================================

  final String taxClass;

  final String taxStatus;

  final double taxRate;

  // =====================================
  // CATEGORY / STOCK
  // =====================================

  final List<int> categoryIds;

  final bool isNotForSale;

  final bool canAddToCart;

  final int menuOrder;

  // =====================================
  // RELATED PRODUCTS
  // =====================================

  final List<int> relatedProductIds;

  Productsmodel({
    required this.id,
    required this.name,
    required this.slug,
    this.brand,
    this.image,
    required this.galleryImages,
    required this.description,
    required this.categories,
    this.sideeeffects,
    this.working,
    this.regularPrice,
    this.salePrice,

    // TAX
    this.taxClass = '',
    this.taxStatus = 'taxable',
    this.taxRate = 18,

    required this.categoryIds,
    required this.isNotForSale,
    required this.canAddToCart,

    this.menuOrder = 0,

    this.relatedProductIds = const [],

    this.manufactured,
    this.composition,
    this.packagesize,
  });

  // =========================================
  // FROM JSON
  // =========================================

  factory Productsmodel.fromJson(
    Map<String, dynamic> json,
  ) {
    String? sideffects;

    String? howdoesitwork;

    String? brandValue =
        json['manufacturer']?.toString();

    String? compositionValue =
        json['composition_meta']?.toString() ??
        json['composition']?.toString();

    String? packageValue =
        json['package_meta']?.toString() ??
        json['package']?.toString();

    // =====================================
    // BRANDS ARRAY
    // =====================================

    if (
      json['brands'] is List &&
      (json['brands'] as List).isNotEmpty
    ) {
      final brandList =
          json['brands'] as List;

      final firstBrand =
          brandList.first;

      if (
        firstBrand is Map &&
        firstBrand['name'] != null
      ) {
        brandValue =
            firstBrand['name'].toString();
      }
    }

    // =====================================
    // META DATA
    // =====================================

    final List<dynamic> metaData =
        json['meta_data'] is List
            ? json['meta_data'] as List
            : [];

    for (final item in metaData) {
      if (item is Map) {
        final key =
            item['key']?.toString();

        final value =
            item['value'];

        switch (key) {
          case 'side_effects':
            sideffects =
                _cleanHtml(value);
            break;

          case 'how_does_it_work':
            howdoesitwork =
                _cleanHtml(value);
            break;

          case 'composition':
            compositionValue ??=
                _cleanHtml(value);
            break;

          case 'package':
          case 'packing':
            packageValue ??=
                _cleanHtml(value);
            break;

          case 'manufacturer':
            brandValue ??=
                value?.toString();
            break;
        }
      }
    }

    // =====================================
    // TAX
    // =====================================

    final String taxClass =
        json['tax_class']?.toString() ?? '';

    final String taxStatus =
        json['tax_status']?.toString() ??
        'taxable';

    // =====================================
    // GST RATE
    // =====================================

    double taxRate = 18;

    for (final item in metaData) {
      if (item is Map) {
        final key =
            item['key']?.toString();

        if (key == 'gst_rate') {
          final parsedRate =
              double.tryParse(
                    item['value']
                            ?.toString() ??
                        '',
                  ) ??
                  18;

          taxRate =
              parsedRate <= 0
                  ? 18
                  : parsedRate;

          break;
        }
      }
    }

    // =====================================
    // IMAGES
    // =====================================

    List<String> galleryImages = [];

    if (json['images'] is List) {
      galleryImages =
          (json['images'] as List)
              .map((img) {
                if (img is Map) {
                  return img['src']
                          ?.toString() ??
                      '';
                }

                return img.toString();
              })
              .where(
                (url) => url.isNotEmpty,
              )
              .toList();
    } else if (
        json['image'] != null &&
        json['image']
            .toString()
            .isNotEmpty) {
      galleryImages.add(
        json['image'].toString(),
      );
    }

    // =====================================
    // FALLBACK IMAGE
    // =====================================

    if (galleryImages.isEmpty) {
      galleryImages.add(
        'https://img.freepik.com/free-photo/cosmetic-male-beauty-products-with-display_23-2150435210.jpg?semt=ais_hybrid&w=740&q=80',
      );
    }

    // =====================================
    // SLUG
    // =====================================

    final String slug =
        json['slug']?.toString() ?? '';

    // =====================================
    // CATEGORIES
    // =====================================

    final List categoriesList =
        json['categories'] is List
            ? json['categories']
            : [];

    final List<int> categoryIds =
        categoriesList.map((e) {
          if (e is Map) {
            return int.tryParse(
                  e['id'].toString(),
                ) ??
                0;
          }

          return int.tryParse(
                e.toString(),
              ) ??
              0;
        }).toList();

    String categoryName = '';

    if (categoriesList.isNotEmpty) {
      if (categoriesList.first is Map) {
        categoryName =
            categoriesList.first['name']
                    ?.toString() ??
                '';
      } else {
        categoryName =
            categoriesList.first.toString();
      }
    }

    // =====================================
    // RELATED PRODUCTS
    // =====================================

    final List<int> relatedProductIds =
        (json['related_ids'] as List?)
                ?.map((e) {
                  if (e is int) {
                    return e;
                  }

                  return int.tryParse(
                    e.toString(),
                  );
                })
                .whereType<int>()
                .toList() ??
            [];

    // =====================================
    // PRICE LOGIC
    // =====================================

    final double? regularPrice =
        _parseDouble(
          json['regular_price'] ??
              json['regularPrice'] ??
              json['mrp'] ??
              json['price'],
        );

    double? salePrice =
        _parseDouble(
          json['sale_price'] ??
              json['salePrice'] ??
              json['price'],
        );

    // =====================================
    // FALLBACK:
    // IF SALE PRICE MISSING
    // =====================================

    salePrice ??=
        regularPrice;

    // =====================================
    // ALGOLIA OBJECT ID
    // =====================================

    final int parsedId =
        int.tryParse(
              json['id']?.toString() ??
                  json['objectID']
                      ?.toString() ??
                  '0',
            ) ??
            0;

    // =====================================
    // STOCK STATUS
    // =====================================

    final String stockStatus =
        json['stock_status']?.toString() ??
        'instock';

    // =====================================
    // FINAL MODEL
    // =====================================

    return Productsmodel(
      id: parsedId,

      menuOrder:
          (json['menu_order'] as num?)
                  ?.toInt() ??
              0,

      name:
          json['name']?.toString() ?? '',

      description:
          _cleanHtml(
                json['description'],
              ) ??
              '',

      categories:
          categoryName,

      sideeeffects:
          sideffects,

      slug:
          slug,

      working:
          howdoesitwork,

      manufactured:
          brandValue,

      brand:
          brandValue,

      composition:
          compositionValue,

      packagesize:
          packageValue,

      image:
          galleryImages.first,

      galleryImages:
          galleryImages,

      regularPrice:
          regularPrice,

      salePrice:
          salePrice,

      // ===================================
      // TAX
      // ===================================

      taxClass:
          taxClass,

      taxStatus:
          taxStatus,

      taxRate:
          taxRate,

      // ===================================
      // CATEGORY
      // ===================================

      categoryIds:
          categoryIds,

      relatedProductIds:
          relatedProductIds,

      isNotForSale:
          categoryIds.contains(94),

      canAddToCart:
          stockStatus == 'instock' &&
          !categoryIds.contains(94),
    );
  }

  // =========================================
  // PARSE DOUBLE
  // =========================================

  static double? _parseDouble(
    dynamic value,
  ) {
    if (
      value == null ||
      value == ''
    ) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
  }

  // =========================================
  // CLEAN HTML
  // =========================================

  static String? _cleanHtml(
    dynamic value,
  ) {
    if (
      value == null ||
      value == ''
    ) {
      return null;
    }

    String clean =
        value
            .toString()
            .replaceAll(
              RegExp(
                r'<[^>]*>|&[^;]+;',
              ),
              ' ',
            )
            .replaceAll(
              RegExp(r'\s+'),
              ' ',
            )
            .trim();

    return clean.isEmpty
        ? null
        : clean;
  }
}