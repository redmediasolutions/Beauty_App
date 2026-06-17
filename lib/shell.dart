import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:glowfit/components/Floating_Navbar.dart';

class ShellPage extends StatelessWidget {
  final Widget child;

  const ShellPage({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F9),
      body: Stack(
        children: [
          Positioned.fill(
            child: child,
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: user == null
                ? const FloatingNavBar(cartCount: 0)
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('carts')
                        .doc(user.uid)
                        .collection('items')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int cartCount = 0;

                      if (snapshot.hasData) {
                        for (final doc in snapshot.data!.docs) {
                          final data =
                              doc.data() as Map<String, dynamic>;

                          cartCount +=
                              (data['quantity'] as num?)
                                      ?.toInt() ??
                                  0;
                        }
                      }

                      return FloatingNavBar(
                        cartCount: cartCount,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}