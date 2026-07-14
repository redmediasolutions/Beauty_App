import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glowfit/models/coupon_model.dart';
import 'package:glowfit/models/freegit.dart';
import 'package:glowfit/pages/cart/address_section.dart';
import 'package:glowfit/pages/cart/bill_summary.dart';
import 'package:glowfit/pages/cart/cart_item_widget.dart';
import 'package:glowfit/pages/cart/cart_progress_update.dart';
import 'package:glowfit/pages/cart/cart_repository.dart';
import 'package:glowfit/pages/cart/checkout_button_widget.dart';
import 'package:glowfit/pages/cart/freegiftbanner.dart';
import 'package:glowfit/pages/cart/offer_card_widget.dart';
import 'package:glowfit/pages/cart/payment_tilewidget.dart';
import 'package:glowfit/pages/cart/savingscard.dart';
import 'package:glowfit/pages/cart/summary_row_widget.dart';
import 'package:glowfit/services/firestoreservice.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ScrollController _scrollController = ScrollController();
  final CartRepository _repository = CartRepository();
  final FirestoreService _firestoreService = FirestoreService();
  late Razorpay _razorpay;

  final bool _usePoints = false;
  bool _isProcessing = false;
  String _selectedPayment = "cod";
  Map<String, dynamic>? _selectedAddress;
  Map<String, dynamic> _rates = {};
  Map<String, double> _totals = {};

  String? _razorpayOrderId;
  String? _razorpayKey;

  List<CouponModel> coupons = [];
  CouponModel? selectedCoupon;
  bool isLoadingCoupons = true;

  double _couponDiscountAmount = 0;
  double _finalCheckoutTotal = 0;
  double _adjustedTaxAmount = 0;
  FreeGiftModel? _freeGiftSettings;

bool _loadingFreeGift = true;

bool _giftAdded = false;

double _codThreshold = 499;
double _codChargeBelowThreshold = 16;
double _codChargeAboveThreshold = 0;

double _shippingThreshold = 499;
double _shippingChargeBelowThreshold = 49;
double _shippingChargeAboveThreshold = 0;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _setupRazorpay();
    _loadRates();
    _loadAvailableCoupons();
    _loadFreeGiftSettings();
    _loadCheckoutSettings();   // Load COD settings
  }

  @override
  void dispose() {
    _razorpay.clear();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFreeGiftSettings() async {
  try {
    print("==================================");
    print("🎁 LOADING FREE GIFT SETTINGS");
    print("==================================");

    final result =
        await _firestoreService
            .getFreeGiftSettings();

    if (result == null) {
      print("❌ Firestore returned NULL");
    } else {
      print("✅ Campaign: ${result.campaignName}");
      print("✅ Enabled: ${result.enabled}");
      print("✅ Start: ${result.startAt}");
      print("✅ End: ${result.endAt}");
      print("✅ Tier Count: ${result.tiers.length}");

      for (final tier in result.tiers) {
        print("--------------------------------");
        print("Minimum Order: ₹${tier.minimumOrder}");
        print("Product ID: ${tier.productId}");
        print("Product Name: ${tier.productName}");
        print("Quantity: ${tier.quantity}");
        print("Image: ${tier.image}");
      }
    }

    if (!mounted) return;

    setState(() {
      _freeGiftSettings = result;
      _loadingFreeGift = false;
    });

    print("✅ State Updated");
    print("Loading = $_loadingFreeGift");
    print(
      "Settings Loaded = ${_freeGiftSettings != null}",
    );

    print("==================================");
  } catch (e, stack) {
    print("==================================");
    print("❌ FREE GIFT LOAD ERROR");
    print(e);
    print(stack);
    print("==================================");

    if (mounted) {
      setState(() {
        _loadingFreeGift = false;
      });
    }
  }
}

Future<void> _loadCheckoutSettings() async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('app_settings')
        .doc('checkout')
        .get();

    if (!doc.exists || !mounted) return;

    final data = doc.data()!;

    setState(() {
      _codThreshold =
          (data['cod_threshold'] as num?)?.toDouble() ?? 999;

      _codChargeBelowThreshold =
          (data['cod_charge_below_threshold'] as num?)?.toDouble() ?? 49;

      _codChargeAboveThreshold =
          (data['cod_charge_above_threshold'] as num?)?.toDouble() ?? 29;

          _shippingThreshold =
    (data['shipping_threshold'] as num?)?.toDouble() ?? 499;

_shippingChargeBelowThreshold =
    (data['shipping_charge_below_threshold'] as num?)?.toDouble() ?? 49;

_shippingChargeAboveThreshold =
    (data['shipping_charge_above_threshold'] as num?)?.toDouble() ?? 0;
    });

    debugPrint("Checkout Settings Loaded");
    debugPrint("Threshold: $_codThreshold");
    debugPrint("Below: $_codChargeBelowThreshold");
    debugPrint("Above: $_codChargeAboveThreshold");
  } catch (e) {
    debugPrint("Failed to load checkout settings: $e");
  }
}

  Future<void> _openAddAddressSheet() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final pincodeController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add Address",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                _buildInputField(controller: nameController, hint: "Full Name"),
                _buildInputField(
                  controller: phoneController,
                  hint: "Phone Number",
                  keyboardType: TextInputType.phone,
                ),
                _buildInputField(
                  controller: addressController,
                  hint: "House No, Street, Area",
                  maxLines: 3,
                ),
                _buildInputField(controller: cityController, hint: "City"),
                _buildInputField(controller: stateController, hint: "State"),
                _buildInputField(
                  controller: pincodeController,
                  hint: "Pincode",
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),

                /// SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.trim().isEmpty ||
                          phoneController.text.trim().isEmpty ||
                          addressController.text.trim().isEmpty ||
                          cityController.text.trim().isEmpty ||
                          stateController.text.trim().isEmpty ||
                          pincodeController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please fill all fields"),
                          ),
                        );
                        return;
                      }

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final addressData = {
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'address': addressController.text.trim(),
                          'city': cityController.text.trim(),
                          'state': stateController.text.trim(),
                          'pincode': pincodeController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(),
                        };

                        await FirebaseFirestore.instance
                            .collection('Users')
                            .doc(user.uid)
                            .collection('addresses')
                            .add(addressData);

                        setState(() {
                          _selectedAddress = addressData;
                        });

                        if (!mounted) return;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text("Address added successfully"),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to save address: $e")),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6F0562),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Save Address",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF6F3F4),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _openAddressSelector() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return SizedBox(
          height: 520,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Users')
                .doc(user.uid)
                .collection('addresses')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              /// EMPTY ADDRESS
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "No addresses found",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Add a delivery address to continue checkout",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _openAddAddressSheet();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6F0562),
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("Add Address"),
                      ),
                    ],
                  ),
                );
              }

              /// ADDRESS LIST
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Select Address",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _openAddAddressSheet();
                          },
                          child: const Text("Add Address"),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final bool isSelected =
                            _selectedAddress?['address'] == data['address'];

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAddress = data;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F3F4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF6F0562)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      data['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF6F0562),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${data['address']}, ${data['city']}",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${data['state']} - ${data['pincode']}",
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['phone'] ?? '',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _setupRazorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) async {
      if (mounted) {
        context.push('/processingpayment');
      }
      await _finalizeOrder(
        response.orderId,
        response.paymentId,
        response.signature,
      );
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (
      PaymentFailureResponse response,
    ) {
      if (mounted && context.canPop()) {
        context.pop();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Payment Failed")));
    });
  }

  Future<void> _loadAvailableCoupons() async {
    try {
      final fetchedCoupons = await _firestoreService.fetchCoupons();

      setState(() {
        coupons = fetchedCoupons;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          final String? referredByCode = userData['referredBy'];

          if (referredByCode != null && referredByCode.isNotEmpty) {
            final influencerCoupon = await _firestoreService
                .getInfluencerCouponByReferral(referredByCode);

            if (influencerCoupon != null) {
              setState(() {
                selectedCoupon = influencerCoupon;
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Referral code active: '${influencerCoupon.code}' applied!",
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: const Color(0xFF6F0562),
                  ),
                );
              });
            }
          }
        }
      }

      setState(() {
        isLoadingCoupons = false;
      });
    } catch (e) {
      setState(() {
        isLoadingCoupons = false;
      });
      debugPrint("Error processing coupon lifecycle layout initialization: $e");
    }
  }

  Future<void> _loadRates() async {
    try {
      final rates = await _repository.fetchRates(
        paymentMethod: _selectedPayment,
      );
      if (!mounted) return;

      setState(() {
        _rates = rates;
      });
    } catch (e) {
      debugPrint("Rates error: $e");
    }
  }

  Future<void> _startCheckout() async {
    if (_isProcessing) return;

    if (_selectedAddress == null) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.location_on_outlined, color: Color(0xFF6F0562)),
                SizedBox(width: 8),
                Text("Address Required"),
              ],
            ),
            content: const Text(
              "Please select a delivery address before placing your order.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return;
    }

    try {
      setState(() {
        _isProcessing = true;
      });

      if (mounted) {
        context.push('/processing-order');
      }

      // =========================================
      // CALCULATE COUPON DISCOUNT SAFELY
      // =========================================
      double couponDiscountAmount = 0;

      if (selectedCoupon != null) {
        final cartSnap = await FirebaseFirestore.instance
            .collection('carts')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('items')
            .get();

        double subtotal = 0;

        for (final doc in cartSnap.docs) {
          final data = doc.data();
          subtotal +=
              ((data['salePrice'] ?? 0).toDouble()) *
              ((data['quantity'] ?? 1).toDouble());
        }

        couponDiscountAmount = subtotal * (selectedCoupon!.discount / 100);
        // ROUND TO 2 DECIMALS
        couponDiscountAmount = double.parse(
          couponDiscountAmount.toStringAsFixed(2),
        );
      }
debugPrint("========== COUPON DEBUG ==========");
debugPrint("selectedCoupon=${selectedCoupon?.code}");
debugPrint("discount=${selectedCoupon?.discount}");
debugPrint("couponDiscountAmount=$couponDiscountAmount");
debugPrint("=================================");
      // =========================================
      // CREATE ORDER
      // =========================================
      final result = await _repository.createSecureOrder(
        paymentMethod: _selectedPayment,
        useWallet: _usePoints,
        couponId: selectedCoupon?.id,
        couponCode: selectedCoupon?.code,
        couponDiscount: couponDiscountAmount,
      );

      final payable = (_finalCheckoutTotal - _couponDiscountAmount)
    .clamp(0, double.infinity)
    .toDouble();
      _razorpayOrderId = result['razorpayOrderId'];
      _razorpayKey = result['razorpayKey'];

      // =========================================
      // COD FLOW
      // =========================================
      if (_selectedPayment == "cod" || payable <= 0) {
        await _finalizeOrder(null, null, null);
        return;
      }

      // =========================================
      // ONLINE PAYMENT FLOW
      // =========================================
      if (mounted && context.canPop()) {
        context.pop();
      }

      _openRazorpay(payable);
    } catch (e) {
      if (mounted && context.canPop()) {
        context.pop();
      }
      debugPrint('Checkout error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Checkout failed")));
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _openRazorpay(double amount) {
    final user = FirebaseAuth.instance.currentUser;

    final options = {
      'key': _razorpayKey,
      'amount': (amount * 100).toInt(),
      'currency': 'INR',
      'order_id': _razorpayOrderId,
      'name': 'GlowFit',
      'description': 'Order Payment',
      'prefill': {
        'contact': _selectedAddress?['phone'],
        'email': user?.email ?? '',
      },
      'theme': {'color': '#6F0562'},
    };

    _razorpay.open(options);
  }

  Future<void> _finalizeOrder(
    String? orderId,
    String? paymentId,
    String? signature,
  ) async {
    try {
      final billing = {
        'first_name': _selectedAddress!['name'],
        'phone': _selectedAddress!['phone'],
        'address_1': _selectedAddress!['address'],
        'city': _selectedAddress!['city'],
        'state': _selectedAddress!['state'],
        'postcode': _selectedAddress!['pincode'],
        'country': 'IN',
      };

      final result = await _repository.finalizeOrder(
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
        useWallet: _usePoints,
        billing: billing,
        shipping: billing,
        couponId: selectedCoupon?.id,
        couponCode: selectedCoupon?.code,
        couponDiscount: _couponDiscountAmount,
      );

      final wooOrderId = result['orderId'].toString();

      if (!mounted) return;
      context.go('/ordersuccess', extra: wooOrderId);
    } catch (e) {
      if (!mounted) return;
      context.go('/orderfailed', extra: "Failed to place order");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login")));
    }

    

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F9),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('carts')
              .doc(user.uid)
              .collection('items')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            // ========================================
            // DEBUG CART DATA
            // ========================================
            debugPrint("========== CART ITEMS ==========");
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
             debugPrint("""

Product: ${data['name']}

ProductId: ${data['productId']}

Qty: ${data['quantity']}

MRP: ${data['mrp']}

SalePrice: ${data['salePrice']}

GST Rate: ${data['taxRate']}

""");
            }
            debugPrint("================================");

            double totalSavings = 0;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;

              final mrp = (data['mrp'] as num?)?.toDouble() ?? 0;
              final salePrice = (data['salePrice'] as num?)?.toDouble() ?? mrp;
              final qty = (data['quantity'] as num?)?.toInt() ?? 1;

              if (mrp > salePrice) {
                totalSavings += (mrp - salePrice) * qty;
              }
            }

            double totalMrp = docs.fold(0.0, (sum, doc) {
              final data = doc.data() as Map<String, dynamic>;
              final mrp = (data['mrp'] as num?)?.toDouble() ?? 0;
              final qty = (data['quantity'] as num?)?.toInt() ?? 1;
              return sum + (mrp * qty);
            });

            if (docs.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 120,
                        width: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6F0562).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 60,
                          color: Color(0xFF6F0562),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Your cart is empty",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D2424),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Looks like you haven't added any products yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            context.go('/AllProducts');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6F0562),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            "Browse Products",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // ========================================
            // CART TOTALS
            // ========================================
            _totals = _repository.calculateTotals(docs: docs, rates: _rates);

            final double subtotal = _totals['subtotal'] ?? 0;
            final eligibleGift =
    _freeGiftSettings == null
        ? null
        : _firestoreService
            .getEligibleGift(
              subtotal: subtotal,
              settings: _freeGiftSettings!,
            );

final nextGift =
    _freeGiftSettings == null
        ? null
        : _firestoreService
            .getNextGiftTier(
              subtotal: subtotal,
              settings: _freeGiftSettings!,
            );
            final double shipping =
    subtotal >= _shippingThreshold
        ? _shippingChargeAboveThreshold
        : _shippingChargeBelowThreshold;

            // ========================================
            // COUPON DISCOUNT
            // ========================================
            // ========================================
            // COUPON DISCOUNT
            // ========================================
            // Coupon calculated on products only
_couponDiscountAmount = 0;

if (selectedCoupon != null) {
  _couponDiscountAmount =
      subtotal * (selectedCoupon!.discount / 100);

  _couponDiscountAmount = double.parse(
    _couponDiscountAmount.toStringAsFixed(2),
  );
}

// ========================================
// GST CALCULATION FROM FIRESTORE TAX CLASS
// ========================================
// ========================================
// GST CALCULATION FROM taxRate
// ========================================

final Map<int, double> gstBreakup = {};

double totalTax = 0;

for (final doc in docs) {

  final data =
      doc.data() as Map<String, dynamic>;

  final salePrice =
      (data['salePrice'] as num?)
              ?.toDouble() ??
          0;

  final qty =
      (data['quantity'] as num?)
              ?.toInt() ??
          1;

  final gstRate =
      (data['taxRate'] as num?)
              ?.toDouble() ??
          18;

  final taxableAmount =
      salePrice * qty;

  final lineTax =
      taxableAmount *
      (gstRate / 100);

  totalTax += lineTax;

  gstBreakup.update(
    gstRate.toInt(),
    (value) => value + lineTax,
    ifAbsent: () => lineTax,
  );

  debugPrint(
    "${data['name']} | GST=$gstRate% | Taxable=₹${taxableAmount.toStringAsFixed(2)} | Tax=₹${lineTax.toStringAsFixed(2)}",
  );
}

_adjustedTaxAmount =
    double.parse(
      totalTax.toStringAsFixed(2),
    );

            // ========================================
            // DISCOUNTED SUBTOTAL
            // ========================================

            debugPrint(
              "Payment=$_selectedPayment "
              "Rates=$_rates "
              "COD=${_rates['cod_charges']}",
            );

            // ========================================
            // COD CHARGES
            // ========================================
            final double codChargesAmount =
    _selectedPayment == "cod"
        ? (subtotal >= _codThreshold
            ? _codChargeAboveThreshold
            : _codChargeBelowThreshold)
        : 0.0;

        // ========================================
// PRE-DISCOUNT TOTAL
// ========================================


// ========================================
// POINTS DISCOUNT
// ========================================
final double pointsDiscountAmount =
    _usePoints ? 50 : 0;

final double discountedSubtotal =
    subtotal -
    _couponDiscountAmount -
    pointsDiscountAmount;

final double safeSubtotal =
    discountedSubtotal < 0
        ? 0
        : discountedSubtotal;
// ========================================
// TOTAL DISCOUNT
// ========================================

            // ========================================
            // FINAL TOTAL
            // ========================================
           _finalCheckoutTotal =

    safeSubtotal +

    _adjustedTaxAmount +

    shipping +

    codChargesAmount;

_finalCheckoutTotal = double.parse(

  _finalCheckoutTotal.toStringAsFixed(2),

);
            return SingleChildScrollView(

              
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// HEADER BAR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/');
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Text(
                        "Cart",
                        style: TextStyle(
                          fontSize: 26,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6F0562),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Your Selection",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),

                  /// CART ITEMS
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: CartItemWidget(
                          name: data['name'] ?? '',
                          mrp: (data['mrp'] ?? 0).toDouble(),
                          salePrice: (data['salePrice'] ?? data['mrp'] ?? 0)
                              .toDouble(),
                          imageUrl: data['image'] ?? '',
                          quantity: data['quantity'] ?? 1,
                          onIncrement: () async {
                            await _repository.updateQty(docId: docId, delta: 1);
                          },
                          onDecrement: () async {
                            await _repository.updateQty(
                              docId: docId,
                              delta: -1,
                            );
                          },
                          onRemove: () async {
                            await _repository.removeItem(docId);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  /// ➕ ADD MORE PRODUCTS

SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton.icon(
    onPressed: () {
      context.go('/AllProducts');
    },
    icon: const Icon(
      Icons.add,
      color: Colors.white,
    ),
    label: const Text(
      "Add More Items",
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF6F0562),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  ),
),

const SizedBox(height: 24),



if (_freeGiftSettings != null &&
    (eligibleGift != null || nextGift != null))
  FreeGiftBanner(
    cartTotal: subtotal,
    unlockAmount:
        eligibleGift?.minimumOrder ??
        nextGift!.minimumOrder,
    giftName:
        eligibleGift?.productName ??
        nextGift!.productName,
    giftImage:
        eligibleGift?.image ??
        nextGift!.image,
    isUnlocked: eligibleGift != null,
    giftAdded: _giftAdded,
    onAddGift: eligibleGift == null
        ? null
        : () async {
            await _repository.addFreeGift(
              productId: eligibleGift.productId,
              productName:
                  eligibleGift.productName,
              image: eligibleGift.image,
              quantity:
                  eligibleGift.quantity,
            );

            setState(() {
              _giftAdded = true;
            });
          },
  ),

    buildChargeProgressCard(
  title: 'Free Shipping',
  icon: Icons.local_shipping_outlined,
  subtotal: subtotal,
  threshold: _shippingThreshold,
  chargeBelowThreshold: _shippingChargeBelowThreshold,
  benefitLabel: 'free shipping',
),
if (_selectedPayment == 'cod') ...[
  const SizedBox(height: 12),
  buildChargeProgressCard(
    title: 'Cash on Delivery',
    icon: Icons.payments_outlined,
    subtotal: subtotal,
    threshold: _codThreshold,
    chargeBelowThreshold: _codChargeBelowThreshold,
    benefitLabel: 'free COD',
  ),
],

const SizedBox(height: 30),
                  /// OFFERS & POINTS SECTION
                  Row(
                    children: [
                      Expanded(
                        child: isLoadingCoupons
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6F0562),
                                  ),
                                ),
                              )
                            : OfferCardWidget(
                                icon: Icons.local_offer_outlined,
                                title: "Apply Coupon",
                                subtitle: selectedCoupon != null
                                    ? "${selectedCoupon!.code} Applied"
                                    : "View offers",
                                selectedCouponCode: selectedCoupon?.code,
                                coupons: coupons,
                                onCouponSelected: (coupon) {
                                  setState(() {
                                    selectedCoupon = coupon;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${coupon.code} applied successfully",
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: const Color(0xFF6F0562),
                                    ),
                                  );
                                },
                                onCouponRemoved: () {
                                  setState(() {
                                    selectedCoupon = null;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Coupon removed successfully",
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  /// ADDRESS SECTION
                  AddressSectionWidget(
                    selectedAddress: _selectedAddress,
                    onTap: _openAddressSelector,
                  ),
                  const SizedBox(height: 30),

                  /// PAYMENT METHOD
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "PAYMENT METHOD",
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      PaymentTileWidget(
                        value: "online",
                        title: "Pay Now",
                        icon: Icons.credit_card,
                        selected: _selectedPayment == "online",
                        onTap: () {
                          setState(() {
                            _selectedPayment = "online";
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      PaymentTileWidget(

  value: "cod",

  title: "Cash on Delivery",

  subtitle: subtotal >= _codThreshold
    ? "Estimated COD charge ₹${_codChargeAboveThreshold.toStringAsFixed(0)}"
    : "Estimated COD charge ₹${_codChargeBelowThreshold.toStringAsFixed(0)}",

  icon: Icons.money,

  selected: _selectedPayment == "cod",

  onTap: () {

    setState(() {

      _selectedPayment = "cod";

    });

  },

),
                    ],
                  ),
                  const SizedBox(height: 30),

                  if (totalSavings > 0) ...[
                    SavingsCardWidget(
                      productSavings: totalSavings,
                      couponSavings: _couponDiscountAmount,
                    ),
                    const SizedBox(height: 24),
                  ],

                
                  const SizedBox(height: 30),

                  /// BILL SUMMARY
                  BillSummaryWidget(
                    totalMrp: totalMrp,
                    subtotal: subtotal,
                    tax: _adjustedTaxAmount,
                    gstBreakup: gstBreakup,
                    shipping: shipping,
                    total: _finalCheckoutTotal,
                    usePoints: _usePoints,
                    couponDiscount: _couponDiscountAmount,
                    codCharges: codChargesAmount,
                  ),
                  const SizedBox(height: 30),

                  /// CHECKOUT BUTTON
                  CheckoutButtonWidget(
                    isProcessing: _isProcessing,
                    onTap: _startCheckout,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
