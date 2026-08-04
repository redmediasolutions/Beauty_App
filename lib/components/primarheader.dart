import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class PrimaryHeader extends StatelessWidget {
  final Widget body;
  final Color background;

  const PrimaryHeader({
    super.key,
    required this.body,
    this.background = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // Pages that should always show a back button.
    final forceBackButton =
        location.startsWith('/products/') ||
        location.startsWith('/product/');

    final canPop = Navigator.of(context).canPop();
    final showBackButton = canPop || forceBackButton;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,

        leading: showBackButton
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                ),
                onPressed: () {
                  if (canPop) {
                    context.pop();
                  } else {
                    // Deep-link fallback
                    context.go('/');
                    // or context.go('/collection');
                  }
                },
              )
            : null,

        title: SvgPicture.asset(
          'assets/images/app-header.svg',
          height: 24,
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: () {
                context.go('/profile');
              },
              icon: const Icon(
                Icons.person_outline,
                color: Colors.black,
                size: 26,
              ),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}