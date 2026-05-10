import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class OrderFailedScreen extends StatelessWidget {
  final String? message;

  const OrderFailedScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F9),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// ❌ Animation
            Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_qp1q7mct.json',
              width: 220,
              height: 220,
              repeat: false,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.error_outline,
                size: 100,
                color: Colors.red,
              ),
            ),

            const SizedBox(height: 24),

            /// ❌ Title
            Text(
              "Order Failed",
              style: GoogleFonts.tenorSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            /// ❌ Message
            Text(
              message ?? "Something went wrong while placing your order.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 30),

            /// 🔁 Retry Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.pop(); // go back to cart
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.black,
                ),
                child: const Text(
                  "Try Again",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 10),

            /// 🏠 Home Button
            TextButton(
              onPressed: () {
                context.go('/');
              },
              child: const Text("Go to Home"),
            ),
          ],
        ),
      ),
    );
  }
}