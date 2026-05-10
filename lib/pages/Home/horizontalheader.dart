import 'package:flutter/material.dart';
import 'package:glowfit/models/product_model.dart';
import 'package:glowfit/pages/Home/home_productcard.dart';
import 'package:glowfit/services/api.dart';

class HorizontalCollection extends StatelessWidget {
  final String categoryId;

  const HorizontalCollection({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final palette = [
      const Color(0xFFF5F3F0),
      const Color(0xFFF5F3F0),
      const Color(0xFFF5F3F0),
      const Color(0xFFF5F3F0),
    ];

    return SizedBox(
      height: 320,
      child: FutureBuilder<List<Productsmodel>>(
        future: APIService.fetchProductsByCategory(categoryId: categoryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingList();
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Failed to load products',
                style: TextStyle(color: Color(0xFF8A7F7A)),
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'No products found',
                style: TextStyle(color: Color(0xFF8A7F7A)),
              ),
            );
          }

          return ListView.separated(
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              final product = products[index];
              final accent = palette[index % palette.length];
              return HomeFeaturedProductCard(
                product: product,
                accentColor: accent,
              );
            },
          );
        },
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      scrollDirection: Axis.horizontal,
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(width: 18),
      itemBuilder: (_, _) {
        return Container(
          width: 210,
          decoration: BoxDecoration(
            color: const Color(0xFFE8DEDA),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
  }
}
