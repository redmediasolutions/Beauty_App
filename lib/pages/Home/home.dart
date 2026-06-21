import 'package:flutter/material.dart';
import 'package:glowfit/components/primarheader.dart';
import 'package:glowfit/pages/Home/HeroSection.dart';
import 'package:glowfit/pages/Home/collectionheader.dart';
import 'package:glowfit/pages/Home/home_categories_section.dart';
import 'package:glowfit/pages/Home/horizontalheader.dart';
import 'package:glowfit/pages/Home/recommended_section.dart';
import 'package:glowfit/pages/Home/value.dart';

class Homepage extends StatefulWidget {
  final String categoryId; 
  const Homepage({super.key, required this.categoryId});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return PrimaryHeader(
      background: const Color(0xFFF6F1EE),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              const HeroSection(),
              const SizedBox(height: 24),
              const HomeCategoriesSection(),
              const SizedBox(height: 24),
              const Collectionheader(),
              const SizedBox(height: 16),
              HorizontalCollection(categoryId: "19"),
              const SizedBox(height: 32),
              const RecommendedSection(categoryId: "19"),
              const SizedBox(height: 36),
              const ValueBadges(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

