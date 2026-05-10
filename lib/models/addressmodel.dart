import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final Timestamp? createdAt;

  AddressModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.createdAt,
  });

  /// 🔹 FROM FIRESTORE
  factory AddressModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AddressModel(
      id: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      address: data['address'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      pincode: data['pincode'] ?? '',
      createdAt: data['createdAt'],
    );
  }

  /// 🔹 TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "phone": phone,
      "address": address,
      "city": city,
      "state": state,
      "pincode": pincode,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }
}