import 'package:flutter/material.dart';

class PaymentTileWidget
    extends StatelessWidget {
  final String value;
  final String title;
  final IconData icon;
  final bool selected;

  final VoidCallback onTap;

  const PaymentTileWidget({
    super.key,
    required this.value,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F3F4),
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? const Color(0xFF6F0562)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(
                0xFF6F0562,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(child: Text(title)),

            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(
                  0xFF6F0562,
                ),
              ),
          ],
        ),
      ),
    );
  }
}