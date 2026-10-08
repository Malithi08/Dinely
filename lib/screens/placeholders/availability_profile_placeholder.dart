import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AvailabilityProfilePlaceholderScreen extends StatelessWidget {
  const AvailabilityProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cream,
        title: const Text('Profile'),
      ),
      body: Center(
        child: Text(
          'Profile Screen\n(another team member)',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
      ),
    );
  }
}