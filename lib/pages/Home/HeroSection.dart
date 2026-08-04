import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HeroSection extends StatelessWidget {
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int>? onPageChanged;

  final List<dynamic> items;

  const HeroSection({
    super.key,
    required this.pageController,
    required this.currentPage,
    required this.items,
    this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: AspectRatio(
          aspectRatio: 0.98,
          child: Stack(
            children: [
              PageView.builder(
                controller: pageController,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(item.image, fit: BoxFit.cover)
                          .animate()
                          .fadeIn(duration: 1200.ms)
                          .scale(
                            begin: const Offset(1.02, 1.02),
                            end: const Offset(1, 1),
                          ),

                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Positioned(
                        left: 22,
                        right: 22,
                        bottom: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: GoogleFonts.tenorSans(
                                        fontSize: 28,
                                        height: 1.05,
                                        color: const Color(0xFF532178),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    Text(
                                      item.title2,
                                      style: GoogleFonts.tenorSans(
                                        fontSize: 28,
                                        height: 1.05,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Text(
                                      item.subtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        height: 1.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                                .animate()
                                .fadeIn(delay: 150.ms)
                                .moveY(begin: 15, end: 0),

                            const SizedBox(height: 18),

                            ElevatedButton(
                                  onPressed: () {
                                    final categoryId = int.tryParse(
                                      item.categoryId?.toString() ?? '',
                                    );

                                    // No category selected
                                    if (categoryId == null) {
                                      context.go(item.buttonRoute);
                                      return;
                                    }

                                    // Example:
                                    // buttonRoute = "/AllProducts"
                                    // categoryId = 36
                                    // Result => "/AllProducts/36"

                                    context.go(
                                      '${item.buttonRoute}/$categoryId',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6F0562),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    item.buttonText,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      letterSpacing: 1.4,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 400.ms)
                                .moveY(begin: 10, end: 0),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(items.length, (index) {
                    final active = index == currentPage;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
