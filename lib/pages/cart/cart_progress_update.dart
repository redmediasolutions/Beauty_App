import 'package:flutter/material.dart';

String _formatAmount(double amount) => amount.toStringAsFixed(0);

Widget buildChargeProgressCard({
  required String title,
  required IconData icon,
  required double subtotal,
  required double threshold,
  required double chargeBelowThreshold,
  required String benefitLabel,
}) {
  const purple = Color(0xFF6F0562);

  final safeThreshold = threshold <= 0 ? 1.0 : threshold;
  final isUnlocked = subtotal >= safeThreshold;
  final remaining =
      (safeThreshold - subtotal).clamp(0.0, safeThreshold).toDouble();
  final progress = (subtotal / safeThreshold).clamp(0.0, 1.0).toDouble();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFF9F2F8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: purple.withOpacity(0.22)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: purple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: purple,
                ),
              ),
            ),
            if (isUnlocked)
              const Icon(Icons.check_circle, color: purple),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white,
            valueColor: const AlwaysStoppedAnimation<Color>(purple),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isUnlocked
              ? '$benefitLabel unlocked!'
              : 'Add items worth ₹${_formatAmount(remaining)} more to get $benefitLabel.',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: purple,
          ),
        ),
        if (!isUnlocked && chargeBelowThreshold > 0) ...[
          const SizedBox(height: 3),
          Text(
            'Otherwise, a ₹${_formatAmount(chargeBelowThreshold)} charge applies.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    ),
  );
}