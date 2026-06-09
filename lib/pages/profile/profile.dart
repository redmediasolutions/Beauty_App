import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glowfit/Auth/mobilelogin.dart';
import 'package:glowfit/components/primarheader.dart';
import 'package:glowfit/pages/profile/account/account_settings.dart';
import 'package:glowfit/pages/profile/active_routiencard.dart';
import 'package:glowfit/pages/profile/orderlist.dart';
import 'package:glowfit/pages/profile/profile_header.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryHeader(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Header ---
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.5,
                                color: Colors.black,
                              ),
                        ),

                const SizedBox(height: 20),
                ProfileHeader(),
                //================Active Routine====================
                const SizedBox(height: 35),
                ActiveRoutiencard(),
              //=================Order History======================
                const SizedBox(height: 30),
                //OrderList(),
                const SizedBox(height: 40),
                //=============Account=================================
                AccountSettings(),
                const SizedBox(height: 40),
                //=========== Sign Out Button ======================
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Sign Out"),
                          content: const Text(
                            "Are you sure you want to log out?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("CANCEL"),
                            ),
                            TextButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                if (context.mounted) {
                                  context.go('/login');
                                }
                              },
                              child: const Text(
                                "LOGOUT",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: const BorderSide(color: Color(0xFFEEEEEE)),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      "SIGN OUT",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                //==================Delete Account Button===================
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _deleteUserAccount(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MobileLogin()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      side: const BorderSide(color: Color(0xFFEEEEEE)),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: Text(
                      "DELETE ACCOUNT",
                      style: GoogleFonts.inter(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //===================Acount Deletion Logic===================
  Future<void> _deleteUserAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        String uid = user.uid;

        // 1. DELETE FROM BACKEND (Firestore Example)
        // Do this FIRST while the user is still authenticated
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();

        // 2. DELETE AUTHENTICATION
        await user.delete();

        // 3. NAVIGATE & CLEAN STACK
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MobileLogin()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _showReauthDialog(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  Future<void> _showReauthDialog(BuildContext context) async {
    // Show a snackbar or dialog explaining they need to log in again
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please log out and log back in to verify it's you."),
      ),
    );
  }
}
