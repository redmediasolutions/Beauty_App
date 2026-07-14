import 'package:cloud_firestore/cloud_firestore.dart';

class FreeGiftModel {
  final bool enabled;
  final String campaignName;

  final Timestamp? startAt;
  final Timestamp? endAt;

  final List<FreeGiftTier> tiers;

  FreeGiftModel({
    required this.enabled,
    required this.campaignName,
    required this.startAt,
    required this.endAt,
    required this.tiers,
  });

  factory FreeGiftModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return FreeGiftModel(
      enabled: map['enabled'] ?? false,
      campaignName:
          map['campaignName'] ?? '',
      startAt: map['startAt'],
      endAt: map['endAt'],
      tiers:
          (map['tiers'] as List<dynamic>? ?? [])
              .map(
                (e) => FreeGiftTier.fromMap(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
    );
  }
}

class FreeGiftTier {
  final double minimumOrder;

  final int productId;

  final String productName;

  final String image;

  final int quantity;

  FreeGiftTier({
    required this.minimumOrder,
    required this.productId,
    required this.productName,
    required this.image,
    required this.quantity,
  });

  factory FreeGiftTier.fromMap(
    Map<String, dynamic> map,
  ) {
    return FreeGiftTier(
      minimumOrder:
          (map['minimumOrder'] as num)
              .toDouble(),
      productId: map['productId'],
      productName:
          map['productName'] ?? '',
      image: map['image'] ?? '',
      quantity: map['quantity'] ?? 1,
    );
  }
}