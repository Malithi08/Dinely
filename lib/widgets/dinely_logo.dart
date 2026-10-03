import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DinelyLogo extends StatelessWidget {
  const DinelyLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/login_logo.jpg',
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.restaurant_menu,
          size: 80,
          color: AppColors.primary,
        ),
      ),
    );
  }
}