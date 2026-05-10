import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoyaltyPointsPage extends StatelessWidget {
  const LoyaltyPointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Defining the brand background color
   

    return Scaffold(
      backgroundColor: Colors.white, // Deep purple background
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Seamless with background
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
        title: Text(
          "Loyalty Rewards",
          style: Theme.of(context).textTheme.titleLarge
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            
            // --- COMPONENT 1: Gradient Balance Card ---
            _buildBalanceCard(),
            
            const SizedBox(height: 25),
            
            // --- COMPONENT 2: Redeem Button (Matching your image style) ---
            _buildRedeemButton(context),
            
            const SizedBox(height: 50),
            
            // --- COMPONENT 3: Points History (Empty placeholder for now) ---
            _buildHistoryHeader(),
            const SizedBox(height: 20),
            _buildEmptyHistory(),
            
            const SizedBox(height: 50), // Bottom padding
          ],
        ),
      ),
    );
  }

  // --- WIDGET 1: Dynamic Balance Card with Gradient ---
  Widget _buildBalanceCard() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    return StreamBuilder<DocumentSnapshot>(
      // Listening to the user's document for the 'points' field
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        // Fallback to 0 if loading or if points field is missing
        double points = 0.00;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          points = (userData['points'] ?? 0.00).toDouble();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            // Recreating the blue gradient from your image
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF130953), // Deep Navy
                Color(0xFF009CC6), // Bright Cyan
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // 1. White Wallet Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
              
              // 2. Points Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Available Points",
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "₹${points.toStringAsFixed(2)}", // Formatted to 2 decimal places
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET 2: Shadowed Redeem Button (Specific to image design) ---
  Widget _buildRedeemButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF0C198E), // Deep Navy from your image
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          // Subtly adding the blue-tinted glow/shadow from the image
          BoxShadow(
            color: const Color(0xFF0C198E).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // Logic to show a dialog or page to spend points
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, // Shadow comes from container
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          "Redeem Points",
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    );
  }

  // --- WIDGET 3: History Header ---
  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "POINTS HISTORY",
          style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        const Icon(Icons.filter_list_outlined, color: Colors.white60, size: 18),
      ],
    );
  }

  // --- WIDGET 4: Empty History Placeholder ---
  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05), // Subtle overlay
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.history, color: Colors.white30, size: 40),
          const SizedBox(height: 15),
          Text(
            "Your history is looking empty.",
            style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
          ),
          Text(
            "Make your first purchase to earn points.",
            style: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
          ),
        ],
      ),
    );
  }
}