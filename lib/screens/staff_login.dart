import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'login_scaffold.dart';
import 'customer_login.dart';
import 'manager_login.dart';

class StaffLoginScreen extends StatelessWidget {
  const StaffLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScaffold(
      title: 'Staff Login',
      subtitle: 'Access your staff account',
      emailHint: 'Staff ID / Email',
      emailIcon: Icons.person_outline,
      footnote: 'Authorized staff only',
      hideOr: true,
      showSignUp: false,
      expectedRole: 'staff', // 👈 THIS is what was missing
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
                Text('Manager?', style: AppTextStyles.roleTitle),
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
                  MaterialPageRoute(
                    builder: (_) => const ManagerLoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      backButton: OutlinedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
          );
        },
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.brownMuted),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          backgroundColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.arrow_back_ios_new,
                size: 12, color: AppColors.brownDeep),
            const SizedBox(width: 6),
            Text('Back to Customer Login',
                style: AppTextStyles.outlinedButton),
          ],
        ),
      ),
    );
  }
}