import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pinput/pinput.dart';

class MobileLogin extends StatefulWidget {
  const MobileLogin({super.key});

  @override
  State<MobileLogin> createState() => _MobileLoginState();
}

final String categoryId = "0";

class _MobileLoginState extends State<MobileLogin> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isOtpSent = false;
  bool _isLoading = false;
  final Color primaryColor = const Color(0xFF6366F1); // Modern Indigo
  final Color secondaryColor = const Color(0xFFF1F5F9); // Light Slate
  String _reqId = "";
  final String baseUrl = "https://us-central1-glowfit-4dfe8.cloudfunctions.net";
  bool _isButtonLocked = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleButtonPress() async {
  if (_isLoading || _isButtonLocked) return;

  setState(() => _isButtonLocked = true);

  try {
    if (_isOtpSent) {
      await _verifyOtp();
    } else {
      await _sendOtp();
    }
  } finally {
    // Small delay to prevent rapid spam taps
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() => _isButtonLocked = false);
    }
  }
}

  //================================ SAVE USER TO FIRESTORE WITH TIMEOUT ================================
  Future<void> _saveUserToFirestore(User user) async {
    try {
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      await userDoc
          .set({
            'uid': user.uid,
            'phoneNumber': user.phoneNumber,
            'lastLogin': FieldValue.serverTimestamp(),
            'full_name': user.displayName ?? "",
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('Firestore save took too long');
            },
          );
    } catch (e) {
      debugPrint("Firestore save error: $e");
      // Don't rethrow - user is already authenticated, Firestore will retry
    }
  }

  //===============================OTP SENDING LOGIC - FIXED FOR iOS ===============================
 Future<void> _sendOtp() async {
  if (!mounted) return;

  final phone =
      _phoneController.text.replaceAll(RegExp(r'\D'), '');

  if (phone.length < 10) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter a valid mobile number")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    debugPrint("📤 Sending OTP to: $phone");

    final response = await http
        .post(
          Uri.parse("$baseUrl/sendGladskinOtp"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "phoneNumber": phone,
          }),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint("📨 Response Status: ${response.statusCode}");
    debugPrint("📨 Response Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Server error (${response.statusCode})");
    }

    final data = jsonDecode(response.body);

    if (data["success"] != true) {
      throw Exception(data["message"] ?? "OTP failed");
    }

    setState(() {
      _isOtpSent = true;
      _reqId = data["reqId"] ?? "";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP sent successfully")),
    );
  } catch (e) {
    debugPrint("❌ SEND OTP ERROR: $e");

    String message = "Failed to send OTP";

    if (e.toString().contains("SocketException")) {
      message = "No internet connection";
    } else if (e.toString().contains("TimeoutException")) {
      message = "Request timed out. Try again";
    } else if (e.toString().contains("Server error")) {
      message = "Server error. Try again later";
    } else if (e.toString().contains("OTP failed")) {
      message = "Failed to send OTP";
    } else {
      message = e.toString().replaceAll("Exception: ", "");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  //===============================OTP VERIFICATION LOGIC - FIXED FOR iOS ===============================
  Future<void> _verifyOtp() async {
  if (!mounted) return;

  final otp = _otpController.text.trim();
  final phone =
      _phoneController.text.replaceAll(RegExp(r'\D'), '');

  if (otp.length != 4) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter 4-digit OTP")),
    );
    return;
  }

  if (_reqId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session expired. Request OTP again")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    debugPrint("🔐 Verifying OTP for: $phone");
    debugPrint("📨 OTP: $otp | reqId: $_reqId");

    final response = await http
        .post(
          Uri.parse("$baseUrl/verifyGladskinOtp"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "phoneNumber": phone,
            "otp": otp,
            "reqId": _reqId,
          }),
        )
        .timeout(const Duration(seconds: 10));

    debugPrint("📨 Response Status: ${response.statusCode}");
    debugPrint("📨 Response Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Server error (${response.statusCode})");
    }

    final data = jsonDecode(response.body);

    if (data["success"] != true) {
      throw Exception(data["message"] ?? "Invalid OTP");
    }

    final token = data["token"];

    if (token == null || token.isEmpty) {
      throw Exception("Authentication token missing");
    }

    // 🔐 Firebase Custom Token Login
    final userCredential =
        await FirebaseAuth.instance.signInWithCustomToken(token);

    final user = userCredential.user;

    if (user != null) {
      await _saveUserToFirestore(user);
    }

    debugPrint("✅ Login successful: ${user?.uid}");

    // Optional success feedback (you can remove if using redirect only)
    if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("Login successful")),
);

  } catch (e) {
    debugPrint("❌ VERIFY OTP ERROR: $e");

    String message = "OTP verification failed";

    if (e.toString().contains("SocketException")) {
      message = "No internet connection";
    } else if (e.toString().contains("TimeoutException")) {
      message = "Request timed out. Try again";
    } else if (e.toString().contains("Server error")) {
      message = "Server error. Try again later";
    } else if (e.toString().contains("Invalid OTP")) {
      message = "Incorrect OTP. Please try again";
    } else if (e.toString().contains("expired")) {
      message = "OTP expired. Request a new one";
    } else {
      message = e.toString().replaceAll("Exception: ", "");
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
  Future<void> _handleGuestLogin() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      User? user = _auth.currentUser;

      // Sign in anonymously if not logged in
      if (user == null) {
        final result = await _auth.signInAnonymously();
        user = result.user;
      }

      if (user == null) {
        throw Exception("Guest login failed: user is null");
      }

      // Save user (non-blocking safe)
      await _saveUserToFirestore(user);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Continuing as Guest")));

      // DO NOT navigate
      // GoRouter will auto-redirect after auth state updates
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = "Guest login failed";

      switch (e.code) {
        case 'operation-not-allowed':
          message = "Guest login is disabled";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Try later";
          break;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint("Guest login error: $e");

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Guest login failed")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //============================ UI BUILD METHOD WITH MODERN DESIGN ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F9),
      body: SafeArea(
        child: Stack(
          children: [
            /// 🌿 MAIN CONTENT
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  /// --- BRAND ---
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/gladskin.png', width: 120),
                      const SizedBox(height: 12),
                      const SizedBox(height: 8),
                      Container(
                        width: 30,
                        height: 1,
                        color: const Color(0xFFB70B68).withOpacity(0.3),
                      ),
                    ],
                  ),

                  const SizedBox(height: 60),

                  /// --- HEADER ---
                  Text(
                    _isOtpSent ? "Verification" : "Welcome",
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  /// ANIMATED SECTION
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Column(
                      key: ValueKey(_isOtpSent),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),

                        /// Subtitle animation
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 600),
                          tween: Tween(begin: 20.0, end: 0.0),
                          builder: (context, value, child) {
                            return Transform.translate(
                              offset: Offset(0, value),
                              child: Opacity(
                                opacity: 1 - (value / 20),
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            _isOtpSent
                                ? "Enter the code sent to +91 ${_phoneController.text}"
                                : "LET'S GET STARTED",
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: 2,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),

                        const SizedBox(height: 50),

                        /// INPUT / OTP SWITCH
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: !_isOtpSent
                              ? Column(
                                  key: const ValueKey("phone"),
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "MOBILE NUMBER",
                                      style: TextStyle(
                                        fontSize: 11,
                                        letterSpacing: 2,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: "+91 98765 43210",
                                        border: const UnderlineInputBorder(),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder:
                                            const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Color(0xFF6F0562),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ],
                                )
                              : Center(
                                  key: const ValueKey("otp"),
                                  child: TweenAnimationBuilder(
                                    duration: const Duration(milliseconds: 500),
                                    tween: Tween(begin: 0.8, end: 1.0),
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: child,
                                      );
                                    },
                                    child: Pinput(
                                      length: 4,
                                      controller: _otpController,
                                      onCompleted: (pin) => _verifyOtp(),
                                    ),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 40),

                        /// BUTTON
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : TweenAnimationBuilder(
                                  duration: const Duration(milliseconds: 500),
                                  tween: Tween(begin: 0.95, end: 1.0),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: SizedBox(
                                    width: double.infinity,
                                    height: 58,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
    ? null
    : () {
        if (_isOtpSent) {
          _verifyOtp();
        } else {
          _sendOtp();
        }
      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            40,
                                          ),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Ink(
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF6F0562),
                                              Color(0xFF8C277B),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(40),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _isOtpSent ? "VERIFY" : "SEND OTP",
                                            style: const TextStyle(
                                              letterSpacing: 2,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),

                        if (!_isOtpSent) ...[
                          const SizedBox(height: 30),

                          Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  "OR",
                                  style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),

                          /// Guest button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : _handleGuestLogin,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                              ),
                              child: const Text(
                                "CONTINUE AS GUEST",
                                style: TextStyle(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],

                        if (_isOtpSent) ...[
                          const SizedBox(height: 20),
                          Center(
                            child: TextButton(
                              onPressed: () =>
                                  setState(() => _isOtpSent = false),
                              child: const Text("Edit Phone Number"),
                            ),
                          ),
                        ],

                        const SizedBox(height: 100), // space for footer
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// FOOTER (FIXED)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: const [
                  Text(
                    "made with in Mangalore",
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      color: Color(0xFF85727D),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Glad Innovations",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: Color(0xFF6F0562),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
