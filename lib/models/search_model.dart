class SearchProductModel {

  final int id;

  final String name;

  final String image;

  final double regularPrice;

  final double salePrice;

  final String category;

  final String? brand;

  SearchProductModel({

    required this.id,

    required this.name,

    required this.image,

    required this.regularPrice,

    required this.salePrice,

    required this.category,

    this.brand,
  });

  // =========================================
  // FROM ALGOLIA JSON
  // =========================================

  factory SearchProductModel.fromJson(
    Map<String, dynamic> json,
  ) {

    return SearchProductModel(

      id:
          int.tryParse(
                json['objectID']
                        ?.toString() ??
                    json['id']
                        ?.toString() ??
                    '0',
              ) ??
              0,

      name:
          json['name']
                  ?.toString() ??
              '',

      image:
          json['image']
                  ?.toString() ??
              '',

      regularPrice:
          double.tryParse(
                json['regularPrice']
                        ?.toString() ??
                    json['regular_price']
                        ?.toString() ??
                    '0',
              ) ??
              0,

      salePrice:
          double.tryParse(
                json['salePrice']
                        ?.toString() ??
                    json['sale_price']
                        ?.toString() ??
                    json['price']
                        ?.toString() ??
                    '0',
              ) ??
              0,

      category:
          json['categories']
                  ?.toString() ??
              '',

      brand:
          json['brand']
              ?.toString(),
    );
  }
}