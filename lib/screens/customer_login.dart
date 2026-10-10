import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/auth_service.dart';
import 'login_scaffold.dart';
import 'staff_login.dart';
import 'customer_signup.dart';
import 'home_screen.dart';

class CustomerLoginScreen extends StatelessWidget {
  const CustomerLoginScreen({super.key});

  Future<void> _handleGoogleLogin(BuildContext context) async {
    // Show spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final error = await AuthService().signInWithGoogle();

    if (!context.mounted) return;
    Navigator.pop(context); // dismiss spinner

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Success — go to Home
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LoginScaffold(
      title: 'Welcome Back',
      subtitle: 'Sign in to your account to continue',
      emailHint: 'Email address',
      emailIcon: Icons.mail_outline,
      expectedRole: 'customer',
      onGoogleTap: () => _handleGoogleLogin(context), // Google wired
      onSignUp: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerSignupScreen()),
        );
      },
      roleBox: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.tan,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Staff or Manager?', style: AppTextStyles.roleTitle),
                const SizedBox(height: 2),
                Text('Login here', style: AppTextStyles.roleSubtitle),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.brownMuted),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}