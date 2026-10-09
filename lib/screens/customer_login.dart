import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'login_scaffold.dart';
import 'staff_login.dart';
import 'customer_signup.dart';

class CustomerLoginScreen extends StatelessWidget {
  const CustomerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScaffold(
      title: 'Welcome Back',
      subtitle: 'Sign in to your account to continue',
      emailHint: 'Email address',
      emailIcon: Icons.mail_outline,
      expectedRole: 'customer', 
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