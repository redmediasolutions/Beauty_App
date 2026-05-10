import 'package:flutter/material.dart';
import 'package:glowfit/components/Floating_Navbar.dart';

class ShellPage extends StatelessWidget {
  final Widget child;
  final int cartCount; // 👈 add this

  const ShellPage({
    super.key,
    required this.child,
    required this.cartCount, // 👈 required
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F9), // match your app theme
      body: Stack(
        children: [
          /// 🌿 Page Content
          Positioned.fill(child: child),

          /// 🛒 Floating Navbar
          Align(
            alignment: Alignment.bottomCenter,
            child: FloatingNavBar(
              cartCount: 2,)
          ),
        ],
      ),
    );
  }
}