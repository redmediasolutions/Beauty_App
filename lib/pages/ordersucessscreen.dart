import 'package:flutter/material.dart';
import 'package:glowfit/pages/Home/home.dart';

import 'package:go_router/go_router.dart'; // Or your preferred navigation
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class SuccessSplashScreen extends StatefulWidget {
  const SuccessSplashScreen({super.key});

  @override
  State<SuccessSplashScreen> createState() => _SuccessSplashScreenState();
}

class _SuccessSplashScreenState extends State<SuccessSplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to Home after 3 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        // Use pushReplacement so the user can't "Go Back" to the success screen
    
       Navigator.push(context,MaterialPageRoute(builder: (context)=>Homepage(categoryId: '19',)));
          
           }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Your Lottie Animation ---
            // --- Your Network Lottie Animation ---
            Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_your_animation_url.json', // Replace with your actual URL
              width: 250,
              height: 250,
              repeat: false,
              // Optional: Shows a loading spinner while the JSON is fetching
              frameBuilder: (context, child, composition) {
                if (composition == null) {
                  return const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.black),
                    ),
                  );
                }
                return child;
              },
              // Optional: Handles errors (e.g., if the user is offline)
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.check_circle,
                  size: 100,
                  color: Colors.green,
                );
              },
            ),

            const SizedBox(height: 20),

            // --- Success Text ---
            Text(
              "Order Placed!",
              style: GoogleFonts.tenorSans(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Your skincare treats are on the way ✨",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
