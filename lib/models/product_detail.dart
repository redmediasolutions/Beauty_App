import 'package:glowfit/models/product_imagesmodel.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:glowfit/models/producthighlight.dart';

class ProductDetail {

  final int id;

  final String name;

  final String slug;

  final int menuOrder;

  /// EXTRA DETAILS
  final String manufacturer;

  final String content;

  final String shortdescription;

  /// MEDIA
  final List<String> images;

  /// PRICING
  final double price;

  final double? salePrice;

  /// RELATIONS
  final List<int> relatedProductIds;

  /// ✅ RELATED PRODUCTS
  final List<Productsmodel>
      relatedProducts;

  /// STOCK
  final bool manageStock;

  final String stockStatus;

  final int? stockQuantity;

  final bool isOutOfStock;

  /// CATEGORY
  final List<int> categoryIds;

  final bool isNotForSale;

  /// FINAL UI CONTROL
  final bool canAddToCart;

  /// PRODUCT HIGHLIGHTS
  final List<ProductHighlight>
      highlights;

  final String packing;

  final List<ProductImage>
      addimages;

final String taxClass;

final String taxStatus;

final double taxRate;

  ProductDetail({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.content,
    this.shortdescription = '',
    required this.images,
    required this.price,
    this.salePrice,
    required this.relatedProductIds,
    required this.slug,
    required this.menuOrder,

    /// ✅ ADD THIS
    this.relatedProducts = const [],

    // TAX
    // TAX
required this.taxClass,
required this.taxStatus,
required this.taxRate,

    required this.manageStock,
    required this.stockStatus,
    required this.stockQuantity,
    required this.isOutOfStock,
    required this.categoryIds,
    required this.isNotForSale,
    required this.canAddToCart,
    required this.highlights,
    required this.packing,
    this.addimages = const [],
  });

  factory ProductDetail.fromJson(
    Map<String, dynamic> json,
  ) {

    // =====================================
    // BRAND / MANUFACTURER
    // =====================================

    String manufacturer = '';

    if (
      json['brands'] is List &&
      json['brands'].isNotEmpty
    ) {

      final brand =
          json['brands'][0];

      if (
        brand
            is Map<String, dynamic>
      ) {

        manufacturer =
            brand['name']
                    ?.toString() ??
                '';
      }
    }

    // =====================================
    // DESCRIPTIONS
    // =====================================

    String content =
        json['description']
                ?.toString() ??
            '';

    String shortDescription =
        json['short_description']
                ?.toString() ??
            json['shortDescription']
                ?.toString() ??
            '';

    final String slug =
    json['slug']?.toString() ?? '';

    final int menuOrder =
        json['menu_order'] is int
            ? json['menu_order']
            : int.tryParse(
                  json['menu_order']?.toString() ?? '',
              ) ??
              0;
    // =====================================
    // IMAGES
    // =====================================

    final List<String> images =
        (json['images'] as List?)
                ?.map(
                  (e) => e['src']
                      ?.toString(),
                )
                .whereType<String>()
                .toList() ??
            [];

    // =====================================
    // ADDITIONAL IMAGES
    // =====================================

    final List<ProductImage>
        addimages =
            (json['images']
                        as List?)
                    ?.skip(1)
                    .map(
                      (e) => ProductImage(
                        url:
                            e['src']
                                    ?.toString() ??
                                '',

                        alt:
                            e['alt']
                                    ?.toString() ??
                                '',
                      ),
                    )
                    .where(
                      (e) =>
                          e.url
                              .isNotEmpty,
                    )
                    .toList() ??
                [];

    // =====================================
    // RELATED PRODUCT IDS
    // =====================================

    final List<int>
        relatedProductIds =
            (json['related_ids']
                        as List?)
                    ?.map(
                      (e) => e is int
                          ? e
                          : int.tryParse(
                              e.toString(),
                            ),
                    )
                    .whereType<int>()
                    .toList() ??
                [];

    // =====================================
    // ✅ RELATED PRODUCTS
    // =====================================

    final List<Productsmodel>
        relatedProducts =
            (json['related_products']
                        as List?)
                    ?.map(
                      (e) =>
                          Productsmodel
                              .fromJson(
                        e,
                      ),
                    )
                    .toList() ??
                [];

    // =====================================
    // CATEGORY IDS
    // =====================================

    final List<int>
        categoryIds =
            (json['categories']
                        as List?)
                    ?.map(
                      (e) => e['id'],
                    )
                    .whereType<int>()
                    .toList() ??
                [];

    final bool isNotForSale =
        categoryIds.contains(40);

    // =====================================
    // PACKING
    // =====================================

    String extractPacking(
      List<dynamic>? metaData,
    ) {

      if (metaData == null) {
        return '';
      }

      for (var item in metaData) {

        final key =
            item['key']
                ?.toString();

        if (
          key == 'package' ||
          key == 'packing'
        ) {

          final value =
              item['value']
                  ?.toString()
                  .trim();

          if (
            value != null &&
            value.isNotEmpty &&
            value != '0'
          ) {

            return value;
          }
        }
      }

      return '';
    }

    final packing =
        extractPacking(
      json['meta_data'],
    );

    // =====================================
    // STOCK
    // =====================================

    final bool manageStock =
        json['manage_stock'] ==
            true;

    final String stockStatus =
        json['stock_status']
                ?.toString() ??
            'instock';

    final int? stockQuantity =
        json['stock_quantity'] !=
                null
            ? int.tryParse(
                json['stock_quantity']
                    .toString(),
              )
            : null;

    bool isOutOfStock = false;

    if (manageStock) {

      if (
        stockQuantity == null ||
        stockQuantity < 10
      ) {

        isOutOfStock = true;
      }

    } else {

      isOutOfStock =
          stockStatus !=
              'instock';
    }

    // =====================================
    // FINAL CART RULE
    // =====================================

    final bool canAddToCart =
        !isOutOfStock &&
            !isNotForSale;

    // =====================================
    // HIGHLIGHTS
    // =====================================

    List<ProductHighlight>
        extractHighlights(
      List<dynamic>? metaData,
    ) {

      if (metaData == null) {
        return [];
      }

      Map<String, dynamic> map =
          {};

      for (var item in metaData) {

        map[item['key']] =
            item['value'];
      }

      String clean(
        dynamic value,
      ) {

        if (value == null) {
          return '';
        }

        final v =
            value.toString().trim();

        if (
          v.isEmpty ||
          v == '0'
        ) {

          return '';
        }

        return v;
      }

      List<ProductHighlight>
          list = [];

      void addHighlight(
        String prefix,
      ) {

        final iconData =
            map['${prefix}_icon'];

        final title = clean(
          map['${prefix}_title'],
        );

        final desc = clean(
          map['${prefix}_description'],
        );

        String icon = '';

        if (
          iconData is Map &&
          iconData['value'] != null
        ) {

          final rawIcon =
              iconData['value']
                  .toString();

          if (rawIcon != '0') {

            icon = rawIcon;
          }
        }

        if (
          title.isEmpty &&
          desc.isEmpty
        ) {

          return;
        }

        list.add(
          ProductHighlight(
            icon: icon,
            title: title,
            description: desc,
          ),
        );
      }

      addHighlight(
        'highlights',
      );

      addHighlight(
        'highlights_copy',
      );

      addHighlight(
        'highlights_copy2',
      );

      addHighlight(
        'highlights_copy3',
      );

      return list;
    }

    final highlights =
        extractHighlights(
      json['meta_data'],
    );

// =====================================
// GST RATE
// =====================================

// =====================================
// TAX
// =====================================

final String taxClass =
    json['tax_class']
            ?.toString() ??
        '';

final String taxStatus =
    json['tax_status']
            ?.toString() ??
        'taxable';

// =====================================
// GST RATE FROM META
// =====================================

double taxRate = 18;

final List<dynamic> metaData =

    json['meta_data'] as List? ?? [];

for (final item in metaData) {

  final key =

      item['key']?.toString();

  if (key == 'gst_rate') {

    final parsedRate =

        double.tryParse(

              item['value']?.toString() ?? '',

            ) ??

            18;

    taxRate =

        parsedRate <= 0

            ? 18

            : parsedRate;

    break;

  }

}

    // =====================================
    // PRICING
    // =====================================

    final double price =
        double.tryParse(
              json['regular_price']
                      ?.toString() ??
                  '',
            ) ??
            double.tryParse(
                  json['price']
                          ?.toString() ??
                      '',
                ) ??
            0.0;

    final double? salePrice =
        double.tryParse(
      json['sale_price']
              ?.toString() ??
          '',
    );

    // =====================================
    // FINAL MODEL
    // =====================================

    return ProductDetail(

      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(
                      json['id']
                          .toString(),
                    ) ??
                  0,

      name:
          json['name']
                  ?.toString() ??
              '',

      slug: slug,

      menuOrder: menuOrder,

      manufacturer:
          manufacturer,

      content:
          content,

      shortdescription:
          shortDescription,

      images:
          images,

      addimages:
          addimages,

      taxClass: taxClass,
taxStatus: taxStatus,
taxRate: taxRate,


      price:
          price,

      salePrice:
          salePrice,

      relatedProductIds:
          relatedProductIds,

      /// ✅ ADD THIS
      relatedProducts:
          relatedProducts,

      manageStock:
          manageStock,

      stockStatus:
          stockStatus,

      stockQuantity:
          stockQuantity,

      isOutOfStock:
          isOutOfStock,

      categoryIds:
          categoryIds,

      isNotForSale:
          isNotForSale,

      canAddToCart:
          canAddToCart,

      highlights:
          highlights,

      packing:
          packing,
    );
  }
}