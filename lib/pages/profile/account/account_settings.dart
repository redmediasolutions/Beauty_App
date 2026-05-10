import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return  Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 20),
          child: Text(
            "Account Settings",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontSize: 28,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1D212C),
            )
          ),
        ),
        _settingsTile(
          icon: Icons.person_outline,
          title: "Create Profile",
          isActive: false,
          onTap: () {
           context.push('/editprofile');
          },
        ),
        _settingsTile(
          icon: Icons.location_on_outlined,
          title: "Shipping Addresses",
          isActive: false,
          onTap: () {
            context.push('/address');
          },
        ),
        _settingsTile(
          icon: Icons.notifications_none_outlined,
          title: "Orders",
          isActive: false,
          onTap: () {
            context.push('/orders');
          },
        ),
        _settingsTile(
          icon: Icons.card_membership_outlined,
          title: "Loyalty Points",
          isActive: false,
           onTap: () {
            context.push('/points');
          },
        ),
      ],
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap, // 1. Added this required parameter
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF5F5F5) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap, // 2. Connected the function here
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Icon(icon, color: const Color(0xFF5E2A66), size: 26),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: const Color(0xFF1D212C),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: isActive ? const Color(0xFF5E2A66) : Colors.black12,
          size: 16,
        ),
      ),
    );
  
  }
}