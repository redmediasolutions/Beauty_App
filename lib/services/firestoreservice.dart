import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glowfit/models/addressmodel.dart';
import 'package:glowfit/models/coupon_model.dart';
import 'package:glowfit/models/freegit.dart';
import 'package:glowfit/models/herosectionmodel.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// =======================================================
  /// 📍 ADDRESS REFERENCE
  /// =======================================================

  CollectionReference get _addressRef {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return _db
        .collection('Users')
        .doc(user.uid)
        .collection('addresses');
  }

  /// =======================================================
  /// 📥 GET ADDRESSES (STREAM)
  /// =======================================================

  Stream<List<AddressModel>> getAddresses() {
    return _addressRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AddressModel.fromDoc(doc))
          .toList();
    });
  }

  /// =======================================================
  /// ➕ ADD ADDRESS
  /// =======================================================

  Future<void> addAddress(AddressModel address) async {
    await _addressRef.add(address.toMap());
  }

  /// =======================================================
  /// 🗑 DELETE ADDRESS
  /// =======================================================

  Future<void> deleteAddress(String id) async {
    await _addressRef.doc(id).delete();
  }

  /// =====================================================
  /// 🎟 FETCH COUPONS
  /// =====================================================

Future<List<CouponModel>> fetchCoupons() async {
    try {
      print("🎟️ [FirestoreService] Starting to fetch coupons...");

      final snapshot = await _db
          .collection('coupons')
          .where('isActive', isEqualTo: true)
          .get();

      print("📦 [FirestoreService] Found ${snapshot.docs.length} total raw coupon documents in Firestore.");

      final coupons = snapshot.docs
          .map((doc) => CouponModel.fromFirestore(doc))
          .where((coupon) {
            final isValid = coupon.isValid;
            if (!isValid) {
              print("⚠️ [FirestoreService] Filtering out invalid/expired coupon: CODE: ${coupon.code}, ID: ${coupon.id}");
            }
            return isValid;
          })
          .toList();

      print("✅ [FirestoreService] Successfully parsed ${coupons.length} valid coupons.");

      /// SORT BY HIGHEST DISCOUNT
      coupons.sort((a, b) => b.discount.compareTo(a.discount));
      
      if (coupons.isNotEmpty) {
        print("🔝 [FirestoreService] Top coupon after sorting: ${coupons.first.code} (${coupons.first.discount}% OFF)");
      }

      return coupons;
    } catch (e) {
      print("❌ [FirestoreService] CRITICAL ERROR while fetching coupons: $e");
      throw Exception("Failed to fetch coupons: $e");
    }
  }

  /// =====================================================
  /// 🎯 FETCH INFLUENCER COUPON BY REFERRAL CODE
  /// =====================================================
  Future<CouponModel?> getInfluencerCouponByReferral(String referralCode) async {
    try {
      print("🔍 [FirestoreService] Checking if referral code '$referralCode' belongs to an influencer...");
      
      // Query the top-level Users collection for the matching influencer referral code
      final userSnapshot = await _db
          .collection('Users')
          .where('influencerData.referralCode', isEqualTo: referralCode)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("ℹ️ [FirestoreService] No influencer found with referral code: $referralCode");
        return null;
      }

      final userData = userSnapshot.docs.first.data();
      final String? couponCode = userData['influencerCouponCode'];

      if (couponCode == null || couponCode.isEmpty) {
        print("⚠️ [FirestoreService] Influencer found, but 'influencerCouponCode' field is missing or empty.");
        return null;
      }

      print("🎯 [FirestoreService] Influencer code found! Auto-fetching coupon details for: '$couponCode'");
      
      // Look up the actual coupon model details from the coupons collection
      final couponSnapshot = await _db
          .collection('coupons')
          .where('code', isEqualTo: couponCode.toUpperCase())
          .limit(1)
          .get();

      if (couponSnapshot.docs.isEmpty) {
        print("❌ [FirestoreService] The coupon '$couponCode' linked to this influencer does not exist in 'coupons' collection.");
        return null;
      }

      final coupon = CouponModel.fromFirestore(couponSnapshot.docs.first);
      
      // Make sure the coupon is active/valid before returning it
      if (!coupon.isValid) {
        print("⚠️ [FirestoreService] Influencer coupon '$couponCode' is expired or inactive.");
        return null;
      }

      print("✅ [FirestoreService] Influencer coupon '$couponCode' successfully verified and ready to apply!");
      return coupon;
    } catch (e) {
      print("❌ [FirestoreService] Error processing influencer check: $e");
      return null;
    }
  }

  /// =====================================================
  /// ✅ VALIDATE COUPON
  /// =====================================================

  Future<CouponModel?> validateCoupon(String code) async {
    try {
      final snapshot = await _db
          .collection('coupons')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final coupon = CouponModel.fromFirestore(snapshot.docs.first);

      if (!coupon.isValid) {
        return null;
      }

      return coupon;
    } catch (e) {
      throw Exception("Coupon validation failed: $e");
    }
  }

  /// =====================================================
  /// 📈 INCREMENT COUPON USAGE
  /// =====================================================

  Future<void> incrementCouponUsage(String couponId) async {
    try {
      await _db.collection('coupons').doc(couponId).update({
        'usedCount': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception("Failed to update coupon usage: $e");
    }
  }

  /// =====================================================
/// 🎁 FETCH FREE GIFT SETTINGS
/// =====================================================

Future<FreeGiftModel?> getFreeGiftSettings() async {
  try {
    print("🎁 Fetching free gift settings...");

    final snapshot = await _db
        .collection('app_settings')
        .doc('free_gift')
        .get();

    print("📄 Document exists: ${snapshot.exists}");

    if (!snapshot.exists) {
      print("❌ free_gifts document not found");
      return null;
    }

    final data = snapshot.data();

    print("📦 Raw Firestore Data:");
    print(data);

    if (data == null) {
      print("❌ Document data is null");
      return null;
    }

    final settings =
        FreeGiftModel.fromMap(data);

    print("✅ Model parsed successfully");
    print("Enabled: ${settings.enabled}");
    print("Start At: ${settings.startAt}");
    print("End At: ${settings.endAt}");

    if (!settings.enabled) {
      print("❌ Free gifts disabled");
      return null;
    }

    final now = DateTime.now();

    print("🕒 Current Time: $now");

    if (settings.startAt != null &&
        now.isBefore(settings.startAt!.toDate())) {
      print(
        "❌ Campaign not started yet. Starts: ${settings.startAt!.toDate()}",
      );
      return null;
    }

    if (settings.endAt != null &&
        now.isAfter(settings.endAt!.toDate())) {
      print(
        "❌ Campaign expired. Ended: ${settings.endAt!.toDate()}",
      );
      return null;
    }

    print("🎉 Free gift campaign is ACTIVE");
    return settings;
  } catch (e, stack) {
    print("❌ Failed to fetch free gifts");
    print("Error: $e");
    print("Stack: $stack");
    return null;
  }
}

/// =====================================================
/// 🎁 GET ELIGIBLE GIFT FOR CART TOTAL
/// =====================================================

FreeGiftTier? getEligibleGift({
  required double subtotal,
  required FreeGiftModel settings,
}) {
  if (!settings.enabled) {
    return null;
  }

  FreeGiftTier? eligible;

  final sortedTiers =
      [...settings.tiers]
        ..sort(
          (a, b) => a.minimumOrder
              .compareTo(
                b.minimumOrder,
              ),
        );

  for (final tier in sortedTiers) {
    if (subtotal >= tier.minimumOrder) {
      eligible = tier;
    }
  }

  return eligible;
}


/// =====================================================
/// 🎁 GET NEXT GIFT TIER
/// =====================================================

FreeGiftTier? getNextGiftTier({
  required double subtotal,
  required FreeGiftModel settings,
}) {
  final sortedTiers =
      [...settings.tiers]
        ..sort(
          (a, b) => a.minimumOrder
              .compareTo(
                b.minimumOrder,
              ),
        );

  for (final tier in sortedTiers) {
    if (subtotal < tier.minimumOrder) {
      return tier;
    }
  }

  return null;
}

Future<HeroSettings?> getHeroSettings() async {
  try {
    final doc =
        await FirebaseFirestore.instance
            .collection('app_settings')
            .doc('hero')
            .get();

    if (!doc.exists) {
      return null;
    }

    return HeroSettings.fromMap(
      doc.data()!,
    );
  } catch (e) {
    debugPrint(
      "Hero settings error: $e",
    );
    return null;
  }
}
}