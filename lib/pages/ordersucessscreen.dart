import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SuccessSplashScreen extends StatefulWidget {
  final String? orderId;

  const SuccessSplashScreen({super.key, this.orderId});

  @override
  State<SuccessSplashScreen> createState() => _SuccessSplashScreenState();
}

class _SuccessSplashScreenState extends State<SuccessSplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && widget.orderId != null) {
        context.go('/order/${widget.orderId}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    print(widget.orderId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_jbrw3hcz.json',
              width: 220,
              height: 220,
              repeat: false,
              frameBuilder: (context, child, composition) {
                if (composition == null) {
                  return const SizedBox(
                    height: 220,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return child;
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.check_circle,
                  size: 100,
                  color: Colors.green,
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              "Order Placed!",
              textAlign: TextAlign.center,
              style: GoogleFonts.tenorSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              "Your skincare treats are on the way",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, color: Colors.black54),
            ),

            if (widget.orderId != null) ...[
              const SizedBox(height: 12),
              Text(
                "Order ID: ${widget.orderId}",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.black45),
              ),
            ],

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: () {
                if (widget.orderId != null) {
                  context.goNamed(
                    'orderDetail',
                    pathParameters: {'id': widget.orderId!},
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text(
                "Order Details",
                style: TextStyle(color: Colors.white),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text(
                "Continue Shopping",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
