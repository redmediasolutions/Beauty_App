// Inside your coupon_model.dart file:

import 'package:cloud_firestore/cloud_firestore.dart';

class CouponModel {
  final String id;
  final String code;
  final double discount;
  final bool isActive;
  final int maxUsage;
  final int usedCount;
  final Timestamp? startDate;
  final Timestamp? endDate;
  final Timestamp? createdAt;
  // 1. ADD THIS FIELD
  final bool autoSuggest; 
  final bool isInfluencerCoupon;

  CouponModel({
    required this.id,
    required this.code,
    required this.discount,
    required this.isActive,
    required this.maxUsage,
    required this.usedCount,
    this.startDate,
    this.endDate,
    this.createdAt,
    required this.autoSuggest, // 2. ADD TO CONSTRUCTOR
    required this.isInfluencerCoupon,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CouponModel(
      id: doc.id,
      code: data['code'] ?? '',
      discount: (data['discount'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? false,
      maxUsage: data['maxUsage'] ?? -1,
      usedCount: data['usedCount'] ?? 0,
      startDate: data['startDate'],
      endDate: data['endDate'],
      createdAt: data['createdAt'],
      // 3. MAP IT HERE (fallback to false if missing in old documents)
      autoSuggest: data['autosuggest'] ?? false, 
      isInfluencerCoupon: data['isInfluencerCoupon'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discount': discount,
      'isActive': isActive,
      'maxUsage': maxUsage,
      'usedCount': usedCount,
      'startDate': startDate,
      'endDate': endDate,
      'createdAt': createdAt,
      'autosuggest': autoSuggest, // 4. ADD TO MAP
      'isInfluencerCoupon': isInfluencerCoupon
    };
  }

  // Your existing validation getters remain completely unchanged...
  bool get isValid => isActive && !isExpired && isStarted && !isUsageExceeded;
  bool get isExpired => endDate == null ? false : endDate!.toDate().isBefore(DateTime.now());
  bool get isStarted => startDate == null ? true : startDate!.toDate().isBefore(DateTime.now());
  bool get isUsageExceeded => maxUsage == -1 ? false : usedCount >= maxUsage;
}