import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
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
  String _verificationId = "";
  bool _isOtpSent = false;
  bool _isLoading = false;
  final Color primaryColor = const Color(0xFF6366F1); // Modern Indigo
  final Color secondaryColor = const Color(0xFFF1F5F9); // Light Slate

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
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

  final phone = _phoneController.text.trim();

  if (phone.length < 10) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter a valid mobile number")),
    );
    return;
  }

  setState(() => _isLoading = true);

  final String fullPhoneNumber = "+91$phone";

  try {
    await _auth.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,

      /// 🔥 AUTO VERIFICATION (ANDROID)
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final userCredential =
              await _auth.signInWithCredential(credential);

          final user = userCredential.user;

          if (user != null) {
            await _saveUserToFirestore(user);
          }

          // 🚫 DO NOT NAVIGATE HERE
          // GoRouter will handle redirect

        } catch (e) {
          debugPrint("Auto-verification error: $e");
        }
      },

      /// ❌ FAILED
      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;

        String message = e.message ?? "Verification failed";

        if (e.code == 'invalid-phone-number') {
          message = "Invalid phone number";
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));

        setState(() => _isLoading = false);
      },

      /// 📩 OTP SENT
      codeSent: (String verificationId, int? resendToken) {
        if (!mounted) return;

        setState(() {
          _verificationId = verificationId;
          _isOtpSent = true;
          _isLoading = false;
        });
      },

      /// ⏳ AUTO TIMEOUT
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },

      timeout: const Duration(seconds: 120),
    );
  } catch (e) {
    debugPrint("Error sending OTP: $e");

    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Failed to send OTP. Try again.")),
    );
  }
}

  //===============================OTP VERIFICATION LOGIC - FIXED FOR iOS ===============================
  Future<void> _verifyOtp() async {
  if (!mounted) return;

  final otp = _otpController.text.trim();

  if (otp.length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter a valid 6-digit OTP")),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId,
      smsCode: otp,
    );

    final userCredential =
        await _auth.signInWithCredential(credential);

    final user = userCredential.user;

    if (user != null) {
      await _saveUserToFirestore(user);
    }

    // ✅ IMPORTANT:
    // DO NOT navigate here
    // GoRouter will automatically redirect once auth state updates

  } on FirebaseAuthException catch (e) {
    if (!mounted) return;

    String errorMsg = "Invalid OTP. Try again.";

    switch (e.code) {
      case 'invalid-verification-code':
        errorMsg = "The code you entered is incorrect.";
        break;
      case 'session-expired':
        errorMsg = "OTP expired. Please request a new one.";
        break;
      case 'too-many-requests':
        errorMsg = "Too many attempts. Try again later.";
        break;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(errorMsg)));

  } catch (e) {
    debugPrint("OTP verification error: $e");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification failed. Try again.")),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _handleGuestLogin() async {
  if (!mounted) return;

  setState(() => _isLoading = true);

  try {
    User? user = _auth.currentUser;

    // 🔐 Sign in anonymously if not logged in
    if (user == null) {
      final result = await _auth.signInAnonymously();
      user = result.user;
    }

    if (user == null) {
      throw Exception("Guest login failed: user is null");
    }

    // 💾 Save user (non-blocking safe)
    await _saveUserToFirestore(user);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Continuing as Guest")),
    );

    // 🚫 DO NOT navigate
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

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

  } catch (e) {
    debugPrint("Guest login error: $e");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guest login failed")),
      );
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
                    Image.asset(
                      'assets/images/gladskin.png',
                      width: 120,
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 8),
                    Container(
                      width: 30,
                      height: 1,
                      color:
                          const Color(0xFFB70B68).withOpacity(0.3),
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

                /// 🔥 ANIMATED SECTION
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
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                    keyboardType:
                                        TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: "+91 98765 43210",
                                      border:
                                          const UnderlineInputBorder(),
                                      enabledBorder:
                                          UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Colors.grey.shade300),
                                      ),
                                      focusedBorder:
                                          const UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color:
                                                Color(0xFF6F0562)),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                key: const ValueKey("otp"),
                                child: TweenAnimationBuilder(
                                  duration: const Duration(
                                      milliseconds: 500),
                                  tween:
                                      Tween(begin: 0.8, end: 1.0),
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: child,
                                    );
                                  },
                                  child: Pinput(
                                    length: 6,
                                    controller: _otpController,
                                    onCompleted: (pin) =>
                                        _verifyOtp(),
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 40),

                      /// BUTTON
                      AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 300),
                        child: _isLoading
                            ? const Center(
                                child:
                                    CircularProgressIndicator(),
                              )
                            : TweenAnimationBuilder(
                                duration: const Duration(
                                    milliseconds: 500),
                                tween:
                                    Tween(begin: 0.95, end: 1.0),
                                builder:
                                    (context, scale, child) {
                                  return Transform.scale(
                                      scale: scale,
                                      child: child);
                                },
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: ElevatedButton(
                                    onPressed: _isOtpSent
                                        ? _verifyOtp
                                        : _sendOtp,
                                    style:
                                        ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                40),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Ink(
                                      decoration:
                                          const BoxDecoration(
                                        gradient:
                                            LinearGradient(
                                          colors: [
                                            Color(0xFF6F0562),
                                            Color(0xFF8C277B),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.all(
                                                Radius.circular(
                                                    40)),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _isOtpSent
                                              ? "VERIFY"
                                              : "SEND OTP",
                                          style:
                                              const TextStyle(
                                            letterSpacing: 2,
                                            fontWeight:
                                                FontWeight.bold,
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
                                child: Divider(
                                    color:
                                        Colors.grey.shade300)),
                            const Padding(
                              padding:
                                  EdgeInsets.symmetric(
                                      horizontal: 10),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 2),
                              ),
                            ),
                            Expanded(
                                child: Divider(
                                    color:
                                        Colors.grey.shade300)),
                          ],
                        ),

                        const SizedBox(height: 30),

                        /// Guest button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _isLoading
                                ? null
                                : _handleGuestLogin,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color:
                                      Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        40),
                              ),
                            ),
                            child: const Text(
                              "CONTINUE AS GUEST",
                              style: TextStyle(
                                letterSpacing: 2,
                                fontWeight:
                                    FontWeight.w600,
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
                            onPressed: () => setState(
                                () => _isOtpSent = false),
                            child:
                                const Text("Edit Phone Number"),
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

          /// ❤️ FOOTER (FIXED)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Text(
                  "made with ❤️ in Mangalore",
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