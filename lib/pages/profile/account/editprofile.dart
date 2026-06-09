import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Editprofile extends StatefulWidget {
  const Editprofile({super.key});

  @override
  State<Editprofile> createState() => _EditprofileState();
}

class _EditprofileState extends State<Editprofile> {
  // 1. Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 2. Load existing data so the user doesn't have to re-type everything
void _loadUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  _nameController.text = user.displayName ?? "";

  try {
    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

    _nameController.text =
        data['name'] ?? user.displayName ?? "";

    _emailController.text =
        data['email'] ?? user.email ?? "";

    _phoneController.text =
        data['phoneNumber'] ??
        data['phone'] ??
        user.phoneNumber ??
        "";
  } catch (e) {
    debugPrint("Profile load error: $e");
  }
}

  // 3. The logic to save data to the 'users' table
  Future<void> _saveProfile() async {
  if (_nameController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter your name"),
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    await user.updateDisplayName(
      _nameController.text.trim(),
    );

    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNumber': _phoneController.text.trim(),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Profile updated successfully"),
      ),
    );

    context.pop();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceAll('Exception: ', ''),
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
  onPressed: () {
    if (context.canPop()) {
      context.pop(); // This is the GoRouter-friendly way to go back
    } else {
      context.go('/profile'); // Fallback: send them to the profile route if no history
    }
  },
),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              "Update your Profile",
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 40),
            
            _buildField(
  label: "Full Name",
  controller: _nameController,
  icon: Icons.person_outline,
),

const SizedBox(height: 16),

_buildField(
  label: "Email Address",
  controller: _emailController,
  icon: Icons.email_outlined,
),

const SizedBox(height: 16),

_buildField(
  label: "Mobile Number",
  controller: _phoneController,
  icon: Icons.phone_outlined,
  enabled: false,
),
            
            const SizedBox(height: 12),
          Align(
  alignment: Alignment.centerLeft,
  child: Text(
    "This mobile number is used to sign in to your account and cannot be changed.",
    style: GoogleFonts.inter(
      color: Colors.black45,
      fontSize: 13,
      height: 1.4,
    ),
  ),
),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A206E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Text(
                      "Continue to App",
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
  required String label,
  required TextEditingController controller,
  required IconData icon,
  bool enabled = true,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),

      const SizedBox(height: 8),

      TextField(
        controller: controller,
        enabled: enabled,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    ],
  );
}
}