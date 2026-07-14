import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glowfit/services/gorouter.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _shimmerController;

  late Animation<double> _bgFade;
  late Animation<double> _contentFade;
  late Animation<double> _contentScale;

  @override
  void initState() {
    super.initState();

    /// 🎬 Main controller
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    /// 💫 Shimmer
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    /// 🎨 Background fade (purple → UI)
    _bgFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    /// 🌿 Content fade in
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1, curve: Curves.easeOut),
      ),
    );

    /// 🌿 Content scale (subtle zoom)
    _contentScale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 1, curve: Curves.easeOutExpo),
      ),
    );

    _mainController.forward();

    /// 🚀 Navigate
    Future.delayed(const Duration(seconds: 3), () {
      // TODO: Navigate to home
    });

      Future.delayed(const Duration(seconds: 3), () {
    final auth = AppRouter.authStateNotifier;

    /// Safety check (in case auth still loading)
    if (!auth.isInitialized) return;

    if (auth.user != null) {
      context.go('/');
    } else {
      context.go('/login');
    }
  });
  }

  

  @override
  void dispose() {
    _mainController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌸 FINAL UI BACKGROUND
          Container(
            color: const Color(0xFFFCF9F9),
          ),

          /// 🌸 Soft gradients
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [
                  Color(0x33FFD9E3),
                  Color(0xFFFCF9F9),
                ],
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomLeft,
                radius: 1.2,
                colors: [
                  Color(0x33FFD7F0),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          /// 🌿 MAIN CONTENT (fades in)
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _contentScale.value,
                  child: Opacity(
                    opacity: _contentFade.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        /// 🌺 Glow + Logo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF8C277B)
                                    .withValues(alpha: 0.08),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8C277B)
                                        .withValues(alpha: 0.2),
                                    blurRadius: 80,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            SvgPicture.asset(
                              'assets/images/splashscreen/onlylogo.svg',
                              width: 180,
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        /// ✨ Title
                        SvgPicture.asset(
                          'assets/images/splashscreen/onlytext.svg',
                          width: 220,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          "PURE BEAUTY PURE SKIN",
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            letterSpacing: 4,
                            color: Color(0xFF85727D),
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// 💫 Shimmer line
                        SizedBox(
                          width: 150,
                          height: 1,
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              return ShaderMask(
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    begin: Alignment(
                                        -1 + _shimmerController.value * 2, 0),
                                    end: Alignment(
                                        1 + _shimmerController.value * 2, 0),
                                    colors: const [
                                      Colors.transparent,
                                      Color(0xFF8C277B),
                                      Colors.transparent,
                                    ],
                                  ).createShader(bounds);
                                },
                                child: Container(
                                  color: Colors.grey.shade300,
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          "INITIALIZING APP",
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            letterSpacing: 2,
                            color: Color(0xFF52424C),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          /// 🎬 PURPLE INTRO SCREEN (fades out)
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              return Opacity(
                opacity: _bgFade.value,
                child: Container(
                  color: const Color(0xFF8C277B),
                ),
              );
            },
          ),

          /// 🌐 Footer (fade in with content)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                return Opacity(
                  opacity: _contentFade.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 30,
                        child: Divider(
                            color: Color(0xFFD7C0CD), thickness: 1),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "GLAD INNOVATIONS",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          letterSpacing: 1,
                          color: Color(0xFF85727D),
                        ),
                      ),
                      SizedBox(width: 10),
                      SizedBox(
                        width: 30,
                        child: Divider(
                            color: Color(0xFFD7C0CD), thickness: 1),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}