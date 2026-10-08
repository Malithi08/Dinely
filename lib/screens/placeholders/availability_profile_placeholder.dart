import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../customer_login.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const CustomerLoginScreen(),
                ),
                (_) => false,
              );
            },
          ),
        ],
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