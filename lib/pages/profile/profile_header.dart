import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final String fullDate = user?.metadata.creationTime != null
        ? "${_getMonth(user!.metadata.creationTime!.month)} ${user.metadata.creationTime!.year}"
        : "March 2026";

    return StreamBuilder<QuerySnapshot>(

  stream: user?.uid != null

      ? FirebaseFirestore.instance

          .collection('Users')

          .doc(user!.uid)

          .collection('walletTransactions')

          .snapshots()

      : const Stream.empty(),

  builder: (context, snapshot) {

    String displayName =

        user?.displayName ?? "Guest User";

    double loyaltyPoints = 0;

    // Fetch display name separately

    if (user != null) {

      displayName =

          user.displayName ?? "Guest User";

    }

    if (snapshot.hasData) {

      for (final doc in snapshot.data!.docs) {

        final data =

            doc.data() as Map<String, dynamic>;

        final amount =

            ((data['amount'] ?? 0) as num)

                .toDouble();

        final status =

            data['status'] ?? '';

        final type =

            data['type'] ?? 'credit';

        /// AVAILABLE REWARDS

        if (status == 'credited') {

          if (type == 'credit') {

            loyaltyPoints += amount;

          }

          if (type == 'debit') {

            loyaltyPoints -= amount;

          }

        }

        /// Approved withdrawals

        if (status == 'approved' &&

            type == 'debit') {

          loyaltyPoints -= amount;

        }

      }

    }

    return Container(

      margin: const EdgeInsets.symmetric(horizontal: 0),

      padding: const EdgeInsets.all(10),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withValues(alpha: 0.04),

            blurRadius: 20,

            offset: const Offset(0, 8),

          ),

        ],

      ),

      child: Row(

        children: [
              /// PROFILE IMAGE
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6F0562),
                      Color(0xFFC06A83),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.network(
                      user?.photoURL ??
                          'https://cdn-icons-png.flaticon.com/512/3135/3135715.png',
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.person,
                        size: 34,
                        color: Color(0xFF6F0562),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              /// USER DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lora(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1D212C),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Member since $fullDate",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8EEF7),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                          "${loyaltyPoints.toStringAsFixed(2)} Loyalty Points",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6F0562),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// CHEVRON
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonth(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}