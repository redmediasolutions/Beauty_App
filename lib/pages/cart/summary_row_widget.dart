import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SummaryRowWidget extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isSubtotal; // 1. Added subtotal flag
  

  const SummaryRowWidget({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.isSubtotal = false, // Initialize as false by default
  });

  @override
  Widget build(BuildContext context) {
    // Determine font size: 20 for absolute total, 15 for standard/subtotal items
    final double computedFontSize = isTotal ? 20 : 15;

    // Determine font weight for the label string
    final FontWeight labelWeight = (isTotal || isSubtotal) 
        ? FontWeight.w700  // Bold if it's a total or subtotal
        : FontWeight.w400; // Normal for standard rows

    // Determine font weight for the value string
    final FontWeight valueWeight = (isTotal || isSubtotal) 
        ? FontWeight.w700  // Bold if it's a total or subtotal
        : FontWeight.w600; // Medium-bold for normal item values

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: computedFontSize,
            fontWeight: labelWeight,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: computedFontSize,
            fontWeight: valueWeight,
          ),
        ),
      ],
    );
  }
}