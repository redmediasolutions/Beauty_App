import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glowfit/components/primarheader.dart';
import 'package:glowfit/models/herosectionmodel.dart';
import 'package:glowfit/pages/Home/HeroSection.dart';
import 'package:glowfit/pages/Home/collectionheader.dart';
import 'package:glowfit/pages/Home/home_categories_section.dart';
import 'package:glowfit/pages/Home/horizontalheader.dart';
import 'package:glowfit/pages/Home/recommended_section.dart';
import 'package:glowfit/pages/Home/value.dart';
import 'package:glowfit/services/firestoreservice.dart';

class Homepage extends StatefulWidget {
  final String categoryId;

  const Homepage({
    super.key,
    required this.categoryId,
  });

  @override
  State<Homepage> createState() =>
      _HomepageState();
}

class _HomepageState
    extends State<Homepage> {
  final FirestoreService
  _firestoreService =
      FirestoreService();

  final PageController
  _pageController =
      PageController();

  HeroSettings? _hero;

  bool _loadingHero = true;

  int _currentPage = 0;

  Timer? _sliderTimer;

  @override
  void initState() {
    super.initState();
    _loadHero();
  }

  Future<void> _loadHero() async {
    try {
      final hero =
          await _firestoreService
              .getHeroSettings();

      if (!mounted) return;

      setState(() {
        _hero = hero;
        _loadingHero = false;
      });

      if (hero != null &&
          hero.enabled &&
          hero.items.isNotEmpty) {
        _startAutoSlider(
          hero.autoSlideSeconds,
        );
      }
    } catch (e) {
      debugPrint(
        "Hero load error: $e",
      );

      if (!mounted) return;

      setState(() {
        _loadingHero = false;
      });
    }
  }

  void _startAutoSlider(
    int seconds,
  ) {
    _sliderTimer?.cancel();

    _sliderTimer = Timer.periodic(
      Duration(seconds: seconds),
      (_) {
        if (!mounted) return;

        if (!_pageController.hasClients ||
            _hero == null ||
            _hero!.items.isEmpty) {
          return;
        }

        int next =
            _currentPage + 1;

        if (next >=
            _hero!.items.length) {
          next = 0;
        }

        _pageController.animateToPage(
          next,
          duration:
              const Duration(
                milliseconds: 500,
              ),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildHeroSection() {
    if (_loadingHero) {
      return Container(
        height: 420,
        margin:
            const EdgeInsets.symmetric(
              horizontal: 20,
            ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(28),
        ),
        child: const Center(
          child:
              CircularProgressIndicator(
                color: Color(
                  0xFF6F0562,
                ),
              ),
        ),
      );
    }

    if (_hero != null &&
        _hero!.enabled &&
        _hero!.items.isNotEmpty) {
      return HeroSection(
        pageController:
            _pageController,
        currentPage:
            _currentPage,
        items: _hero!.items,
        onPageChanged: (index) {
          if (!mounted) return;

          setState(() {
            _currentPage = index;
          });
        },
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryHeader(
      background:
          const Color(0xFFF6F1EE),
      body: SafeArea(
        bottom: true,
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.only(
                bottom: 240,
              ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              const SizedBox(
                height: 18,
              ),

              _buildHeroSection(),

              const SizedBox(
                height: 24,
              ),

              const HomeCategoriesSection(),

              const SizedBox(
                height: 24,
              ),

              const Collectionheader(),

              const SizedBox(
                height: 16,
              ),

              HorizontalCollection(
                categoryId:
                    widget.categoryId,
              ),

              const SizedBox(
                height: 32,
              ),

              RecommendedSection(
                categoryId:
                    widget.categoryId,
              ),

              const SizedBox(
                height: 36,
              ),

              const ValueBadges(),

              const SizedBox(
                height: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}