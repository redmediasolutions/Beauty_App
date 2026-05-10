import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:glowfit/models/addressmodel.dart';

/// =======================================================
/// 🔥 FIRESTORE SERVICE
/// =======================================================
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📍 ADDRESS REFERENCE
  CollectionReference get _addressRef => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('addresses');

  // =======================================================
  // 📥 GET ADDRESSES (STREAM)
  // =======================================================
  Stream<List<AddressModel>> getAddresses() {
    return _addressRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AddressModel.fromDoc(doc))
          .toList();
    });
  }

  // =======================================================
  // ➕ ADD ADDRESS
  // =======================================================
  Future<void> addAddress(AddressModel address) async {
    await _addressRef.add(address.toMap());
  }

  // =======================================================
  // 🗑 DELETE ADDRESS
  // =======================================================
  Future<void> deleteAddress(String id) async {
    await _addressRef.doc(id).delete();
  }
}