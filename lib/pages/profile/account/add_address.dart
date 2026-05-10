import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddShippingAddress extends StatefulWidget {
  const AddShippingAddress({super.key});

  @override
  State<AddShippingAddress> createState() => _AddShippingAddressState();
}

class _AddShippingAddressState extends State<AddShippingAddress> {
  // 1. Controllers for address fields
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  
  bool _isLoading = false;

  // 2. Logic to save address to Firestore
  Future<void> _saveAddress() async {
    // Basic Validation
    if (_houseController.text.isEmpty || _cityController.text.isEmpty || _pincodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // Saving as a document in a sub-collection 'addresses'
        // await FirebaseFirestore.instance
        //     .collection('users')
        //     .doc(uid)
        //     .collection('addresses')
        //     .add({
        //   'houseNumber': _houseController.text.trim(),
        //   'street': _streetController.text.trim(),
        //   'city': _cityController.text.trim(),
        //   'pincode': _pincodeController.text.trim(),
        //   'landmark': _landmarkController.text.trim(),
        //   'isDefault': true, // Assuming first added is default
        //   'createdAt': FieldValue.serverTimestamp(),
        // });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Address saved successfully!")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error saving address: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "Shipping Address",
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Where should we send your routine?",
              style: GoogleFonts.inter(color: Colors.black45, fontSize: 14),
            ),
            const SizedBox(height: 40),
            
            // --- Input Fields ---
            _buildField("Flat / House No. / Building", _houseController),
            const SizedBox(height: 15),
            _buildField("Street / Area", _streetController),
            const SizedBox(height: 15),
            _buildField("City", _cityController),
            const SizedBox(height: 15),
            _buildField("Pincode", _pincodeController, isNumber: true),
            const SizedBox(height: 15),
            _buildField("Landmark (Optional)", _landmarkController),
            
            const SizedBox(height: 40),
            
            // --- Action Button ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A206E), // Matching Navy Blue
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "Save Address",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Reusable Field Helper (Matches Editprofile style)
  Widget _buildField(String hint, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.black38, fontSize: 15),
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      ),
    );
  }
}