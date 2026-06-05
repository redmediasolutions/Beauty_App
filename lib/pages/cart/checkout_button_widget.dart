import 'package:flutter/material.dart';

class CheckoutButtonWidget
    extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback onTap;

  const CheckoutButtonWidget({
    super.key,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed:
            isProcessing ? null : onTap,

        style:
            ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              40,
            ),
          ),
        ),

        child: Ink(
          decoration:
              const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6F0562),
                Color(0xFF8C277B),
              ],
            ),
            borderRadius:
                BorderRadius.all(
              Radius.circular(40),
            ),
          ),

          child: const Center(
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .center,
              children: [
                Text(
                  "CHECKOUT",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),

                SizedBox(width: 8),

                Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}