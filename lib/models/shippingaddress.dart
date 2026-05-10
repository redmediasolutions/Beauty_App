class ShippingAddress {
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  

  ShippingAddress({
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  /// Optional helper
  String get formatted {
    return [
      address1,
      address2,
      city,
      state,
      postcode,
    ].where((e) => e.isNotEmpty).join(', ');
  }
}
