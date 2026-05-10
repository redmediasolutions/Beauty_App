import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProcessingPaymentPage extends StatelessWidget {
  const ProcessingPaymentPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            const SizedBox(
              width: 70,
              height: 70,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: Color(0xFF6F0562),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              "Processing Payment",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Please wait while we confirm your order",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}