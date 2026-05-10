import 'package:flutter/material.dart';
import 'package:glowfit/models/addressmodel.dart';
import 'package:glowfit/services/firestoreservice.dart';
import 'package:go_router/go_router.dart';

class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  final FirestoreService _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Addresses"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,

        /// 🔙 BACK BUTTON
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      backgroundColor: const Color(0xFFFCF9F9),
      body: Column(
        children: [
          Expanded(child: _buildAddressList()),

          /// ➕ ADD NEW ADDRESS BUTTON
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _openAddAddressSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F0562),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Add New Address"),
            ),
          ),
        ],
      ),
    );
  }

  // =======================================================
  // 📦 ADDRESS LIST
  // =======================================================
  Widget _buildAddressList() {
    return StreamBuilder<List<AddressModel>>(
      stream: _service.getAddresses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final addresses = snapshot.data ?? [];

        if (addresses.isEmpty) {
          return const Center(child: Text("No addresses found"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: addresses.length,
          itemBuilder: (context, index) {
            final address = addresses[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F3F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${address.address}, ${address.city}",
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          "${address.state} - ${address.pincode}",
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          address.phone,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  /// 🗑 DELETE
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _service.deleteAddress(address.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =======================================================
  // ➕ ADD ADDRESS SHEET
  // =======================================================
  void _openAddAddressSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    final stateController = TextEditingController();
    final pincodeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Add Address",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                _input(nameController, "Name"),
                _input(phoneController, "Phone"),
                _input(addressController, "Address"),
                _input(cityController, "City"),
                _input(stateController, "State"),
                _input(pincodeController, "Pincode"),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () async {
                    await _service.addAddress(
                      AddressModel(
                        id: '',
                        name: nameController.text,
                        phone: phoneController.text,
                        address: addressController.text,
                        city: cityController.text,
                        state: stateController.text,
                        pincode: pincodeController.text,
                      ),
                    );

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6F0562),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Save Address"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =======================================================
  // 🧩 INPUT FIELD
  // =======================================================
  Widget _input(TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: const Color(0xFFF6F3F4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}