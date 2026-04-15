import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final ScrollController _scrollController = ScrollController();
  bool _usePoints = false;
  String _selectedPayment = "online";
  late Razorpay _razorpay;
  Map<String, dynamic>? _selectedAddress;

Map<String, dynamic> _rates = {};
Map<String, double> _totals = {};

String? _razorpayOrderId;

  @override
void initState() {
  super.initState();

  _razorpay = Razorpay();

  _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
      (PaymentSuccessResponse response) async {
    await _finalizeOrder(
      response.orderId,
      response.paymentId,
      response.signature,
    );
  });

  _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
      (PaymentFailureResponse response) {
    debugPrint("Payment Failed");
  });

  _fetchRates();
} 

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

Future<void> _fetchRates() async {
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('getCartRates')
        .call({
      'paymentMethod': _selectedPayment,
    });

    setState(() {
      _rates = Map<String, dynamic>.from(result.data);
    });
  } catch (e) {
    debugPrint("Rates error: $e");
  }
}

Future<void> _startCheckout() async {
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('createSecureOrder')
        .call({
      'paymentMethod': _selectedPayment,
      'useWallet': false,
    });

    final data = Map<String, dynamic>.from(result.data);

    final double payable = (data['finalPayable'] ?? 0).toDouble();
    _razorpayOrderId = data['razorpayOrderId'];

    if (_selectedPayment == "cod" || payable <= 0) {
      await _finalizeOrder(null, null, null);
      return;
    }

    if (_selectedAddress == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Please select an address")),
  );
  return;
}

    _openRazorpay(payable);
  } catch (e) {
    debugPrint("Checkout error: $e");
  }
}

void _openRazorpay(double amount) {
  final options = {
    'key': 'rzp_live_xxxxx', // 🔥 replace
    'amount': (amount * 100).toInt(),
    'currency': 'INR',
    'order_id': _razorpayOrderId,
    'name': 'Gladskin',
  };

  _razorpay.open(options);
}

Future<void> _finalizeOrder(
    String? orderId,
    String? paymentId,
    String? signature,
    ) async {
  try {
    await FirebaseFunctions.instance
        .httpsCallable('finalizeOrder')
        .call({
      'razorpayOrderId': orderId,
      'razorpayPaymentId': paymentId,
      'razorpaySignature': signature,
    'billing': {
  'first_name': _selectedAddress!['name'],
  'phone': _selectedAddress!['phone'],
  'address_1': _selectedAddress!['address'],
  'city': _selectedAddress!['city'],
  'state': _selectedAddress!['state'],
  'postcode': _selectedAddress!['pincode'],
  'country': 'IN',
},
'shipping': {
  'first_name': _selectedAddress!['name'],
  'phone': _selectedAddress!['phone'],
  'address_1': _selectedAddress!['address'],
  'city': _selectedAddress!['city'],
  'state': _selectedAddress!['state'],
  'postcode': _selectedAddress!['pincode'],
  'country': 'IN',
},
    });

    context.go('/orderSuccess');
  } catch (e) {
    debugPrint("Finalize error: $e");
  }
}

void _calculateTotals(List docs) {
  double subtotal = 0;

  for (var doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    double price =
        double.tryParse(data['salePrice']?.toString() ?? '0') ?? 0;
    int qty = (data['quantity'] ?? 1).toInt();

    subtotal += price * qty;
  }

  final shipping = subtotal <= (_rates['freeShippingThreshold'] ?? 500)
      ? (_rates['shippingBelowThreshold'] ?? 49)
      : (_rates['shippingAboveThreshold'] ?? 0);

  final tax = subtotal * (_rates['taxPercentage'] ?? 0.05);

  final total = subtotal + shipping + tax;

  _totals = {
    "subtotal": subtotal,
    "shipping": shipping.toDouble(),
    "tax": tax,
    "total": total,
  };
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F9),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home'); // fallback
                          }
                        },
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

                  _buildCartOverlay(context),

                  const SizedBox(height: 40),
                ],
              ),
            ),

          
          ],
        ),
      ),
    );
  }

  Widget _buildCartOverlay(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const Center(child: Text("Please login to view your cart"));
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(child: Text("Error: ${snapshot.error}"));
      }

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.black),
        );
      }

      final docs = snapshot.data?.docs ?? [];

      if (docs.isEmpty) {
        return Center(
          child: Column(
            children: [
              const SizedBox(height: 100),
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.grey[200],
              ),
              const SizedBox(height: 20),
              Text(
                "Your cart is empty",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        );
      }

      // ✅ Calculate totals using cloud config
      _calculateTotals(docs);

      final subtotal = _totals['subtotal'] ?? 0;
      final tax = _totals['tax'] ?? 0;
      final shipping = _totals['shipping'] ?? 0;
      final total = _totals['total'] ?? 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🛒 CART ITEMS
          ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String docId = docs[index].id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: _buildCartItem(
                  name: data['name']?.toString() ?? 'Unnamed Product',
                  price: "₹${data['salePrice']?.toString() ?? '0'}",
                  imageUrl: data['image']?.toString() ?? '',
                  quantity: (data['quantity'] ?? 1).toInt(),
                  onIncrement: () => _updateQty(docId, 1),
                  onDecrement: () => _updateQty(docId, -1),
                  onRemove: () => _removeItem(docId),
                ),
              );
            },
          ),

          const SizedBox(height: 30),

          /// 💰 SUMMARY CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F3F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  "Subtotal",
                  "₹${subtotal.toStringAsFixed(0)}",
                ),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  "Tax",
                  "₹${tax.toStringAsFixed(0)}",
                ),
                const SizedBox(height: 10),
                _buildSummaryRow(
                  "Shipping",
                  "₹${shipping.toStringAsFixed(0)}",
                ),
                const Divider(height: 30),
                _buildSummaryRow(
                  "Total Amount",
                  "₹${total.toStringAsFixed(0)}",
                  isTotal: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          /// 🎁 OFFERS
          _buildOffersSection(),

          const SizedBox(height: 30),

          /// 📍 ADDRESS
          _buildAddressSection(),

          const SizedBox(height: 30),

          /// 💳 PAYMENT
          _buildPaymentSection(),

          const SizedBox(height: 30),

          /// 🧾 FINAL BILL (with discount)
          _buildBillSummary(subtotal, tax, shipping, total),

          const SizedBox(height: 30),

          /// 🚀 CHECKOUT BUTTON
          _buildCheckoutButton(),
        ],
      );
    },
  );
}

  Widget _buildOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "OFFERS & REWARDS",
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 2,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _offerCard(
                icon: Icons.local_offer_outlined,
                title: "Apply Coupon",
                subtitle: "View offers",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _usePoints = !_usePoints),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _usePoints
                        ? const Color(0xFF6F0562).withOpacity(0.1)
                        : const Color(0xFFF6F3F4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "2,450 Points",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Tap to redeem",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "DELIVERY ADDRESS",
            style: TextStyle(
              fontSize: 12,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ),
          TextButton(
            onPressed: _openAddressSelector,
            child: const Text("Change"),
          ),
        ],
      ),
      const SizedBox(height: 10),

      GestureDetector(
        onTap: _openAddressSelector,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F3F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined),
              const SizedBox(width: 10),

              Expanded(
                child: _selectedAddress == null
                    ? const Text("Select Address")
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedAddress!['name'] ?? '',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "${_selectedAddress!['address']}, ${_selectedAddress!['city']}",
                          ),
                          Text(
                            "${_selectedAddress!['state']} - ${_selectedAddress!['pincode']}",
                          ),
                          Text(_selectedAddress!['phone'] ?? ''),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    ],
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
        height: 400,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('addresses')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("No addresses found"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAddress = data;
                    });

                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F3F4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedAddress?['address'] ==
                                data['address']
                            ? const Color(0xFF6F0562)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['name'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("${data['address']}, ${data['city']}"),
                        Text("${data['state']} - ${data['pincode']}"),
                        Text(data['phone'] ?? ''),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "PAYMENT METHOD",
          style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.grey),
        ),
        const SizedBox(height: 12),

        _paymentTile("online", "Pay Now", Icons.credit_card),
        const SizedBox(height: 10),
        _paymentTile("cod", "Cash on Delivery", Icons.money),
      ],
    );
  }

  Widget _paymentTile(String value, String title, IconData icon) {
    final selected = _selectedPayment == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF6F0562) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF6F0562)),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF6F0562)),
          ],
        ),
      ),
    );
  }

  Widget _buildBillSummary(
    double subtotal,
    double tax,
    double shipping,
    double total,
  ) {
    double discount = _usePoints ? 50 : 0;
    double finalTotal = total - discount;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildSummaryRow("Subtotal", "₹${subtotal.toStringAsFixed(0)}"),
          _buildSummaryRow("Tax", "₹${tax.toStringAsFixed(0)}"),
          _buildSummaryRow("Shipping", "₹${shipping.toStringAsFixed(0)}"),

          if (_usePoints)
            _buildSummaryRow(
              "Points Discount",
              "-₹${discount.toStringAsFixed(0)}",
            ),

          const Divider(height: 30),

          _buildSummaryRow(
            "Total Amount",
            "₹${finalTotal.toStringAsFixed(0)}",
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _offerCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6F0562)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem({
    required String name,
    required String price,
    required String imageUrl,
    required int quantity,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 90,
                    height: 110,
                    fit: BoxFit.cover,
                  )
                : Container(width: 90, height: 110, color: Colors.grey[200]),
          ),

          const SizedBox(width: 16),

          // DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE + REMOVE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onRemove,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  "Premium Product",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),

                const SizedBox(height: 12),

                // QTY + PRICE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // QTY
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: onDecrement,
                            child: const Icon(Icons.remove, size: 16),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text("$quantity"),
                          ),
                          GestureDetector(
                            onTap: onIncrement,
                            child: const Icon(Icons.add, size: 16),
                          ),
                        ],
                      ),
                    ),

                    // PRICE
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6F0562),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: Colors.black),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 20 : 15,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isTotal ? 20 : 15,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: _startCheckout,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
        ),
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6F0562), Color(0xFF8C277B)],
            ),
            borderRadius: BorderRadius.all(Radius.circular(40)),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "CHECKOUT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DATABASE OPERATIONS ---

  void _updateQty(String docId, int delta) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(docId);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        int currentQty =
            (snapshot.data() as Map<String, dynamic>)['quantity'] ?? 1;
        int newQty = currentQty + delta;

        if (newQty <= 0) {
          transaction.delete(docRef);
        } else {
          transaction.update(docRef, {'quantity': newQty});
        }
      });
    } catch (e) {
      debugPrint("Update error: $e");
    }
  }

  void _removeItem(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('carts')
        .doc(user.uid)
        .collection('items')
        .doc(docId)
        .delete();
  }
}
