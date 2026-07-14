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
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: SvgPicture.asset('assets/images/app-header.svg', height: 24),
        actions: [
          /// 👤 PROFILE BUTTON
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: IconButton(
              onPressed: () {
                context.go('/profile'); // using go_router (recommended)
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
