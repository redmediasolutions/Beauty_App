import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // Logic to get full date
    final String fullDate = user?.metadata.creationTime != null
        ? "${_getMonth(user!.metadata.creationTime!.month)} ${user.metadata.creationTime!.year}"
        : "March 2026";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // --- Profile Image with Glow ---
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8A206E).withOpacity(0.2),
                blurRadius: 50,
                spreadRadius: 20,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(60),
            child: Container(
              width: 120,
              height: 120,
              color: const Color(0xFF1A1A1A),
              child: Image.network(
                user?.photoURL ??
                    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.person, color: Colors.white, size: 50),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ---  Name Loader ---
        StreamBuilder<DocumentSnapshot>(
          
          stream: user?.uid != null 
              ? FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            String displayName = "Guest User";

            if (snapshot.hasData && snapshot.data!.exists) {
             
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              
              if (data != null && data.containsKey('name')) {
                displayName = data['name'];
              } else {
                displayName = user?.displayName ?? "Guest User";
              }
            } else {
              
              displayName = user?.displayName ?? "Guest User";
            }

            return Text(
              displayName,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Colors.black,
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        Text(
          "Member since $fullDate • 450 Points",
          style: GoogleFonts.inter(
            color: Colors.black54,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  String _getMonth(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
}