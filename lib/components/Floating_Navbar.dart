import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class FloatingNavBar extends StatelessWidget {
  final int cartCount;

  const FloatingNavBar({super.key, required this.cartCount});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    int getSelectedIndex() {
      if (location == '/') return 0;
      if (location == '/AllProducts') return 1;
      if (location == '/search') return 2;
      return 0;
    }

    int selectedIndex = getSelectedIndex();

    const Color primaryColor = Color(0xFF8C277B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          /// LEFT PILL (Home, Products, Search)
          Expanded(
            child: Container(
              height: 65,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context,
                    Icons.home_outlined,
                    0,
                    '/',
                    selectedIndex,
                  ),
                  _buildNavItem(
                    context,
                    Icons.shopping_bag_outlined,
                    1,
                    '/AllProducts',
                    selectedIndex,
                  ),
                  _buildNavItem(
                    context,
                    Icons.search,
                    2,
                    '/search',
                    selectedIndex,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          
          /// 🛒 RIGHT PILL (Cart - Always visible)
          GestureDetector(
            onTap: (){
               HapticFeedback.lightImpact(); 
               context.go('/cart');

            },
          
            child: Container(
              height: 65,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  /// 🛒 Icon
                  const Center(
                    child: Icon(
                      Icons.shopping_cart_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  /// 🔴 Badge (only if items exist)
                  if (cartCount > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 300),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, scale, child) {
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              cartCount.toString(),
                              style: const TextStyle(
                                color: primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    int index,
    String route,
    int selectedIndex,
  ) {
    bool isSelected = selectedIndex == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () {
          HapticFeedback.lightImpact(); 
          context.go(route);
        },

        child: Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 250),
            tween: Tween(begin: 0, end: isSelected ? 1 : 0),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              final double size = 24 + (value * 6);
              final double opacity = 0.4 + (value * 0.6);

              return Icon(
                icon,
                size: size,
                color: Colors.white.withValues(alpha: opacity),
              );
            },
          ),
        ),
      ),
    );
  }
}
