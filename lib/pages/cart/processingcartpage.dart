import 'package:flutter/material.dart';

class ProcessingOrderScreen extends StatefulWidget {
  const ProcessingOrderScreen({super.key});

  @override
  State<ProcessingOrderScreen> createState() =>
      _ProcessingOrderScreenState();
}

class _ProcessingOrderScreenState
    extends State<ProcessingOrderScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F9),

      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            RotationTransition(
              turns: controller,

              child: Container(
                width: 90,
                height: 90,

                decoration: BoxDecoration(
                  color: const Color(
                    0xFF6F0562,
<<<<<<< Updated upstream
                  ).withOpacity(.08),
=======
                  ).withValues(alpha: .08),
>>>>>>> Stashed changes

                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 42,
                  color: Color(0xFF6F0562),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Processing Your Order",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Please wait while we prepare your order",
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            const CircularProgressIndicator(
              color: Color(0xFF6F0562),
            ),
          ],
        ),
      ),
    );
  }
}