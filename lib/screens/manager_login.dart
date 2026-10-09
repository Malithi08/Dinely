import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'login_scaffold.dart';
import 'staff_login.dart';

class ManagerLoginScreen extends StatelessWidget {
  const ManagerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LoginScaffold(
      title: 'Manager Login',
      subtitle: 'Access your restaurant management dashboard',
      emailHint: 'Manager ID / Email',
      emailIcon: Icons.person_outline,
      footnote: 'Authorized managers only',
      hideOr: true,
      showSignUp: false,
      expectedRole: 'manager', // 👈 added
      backButton: OutlinedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
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
            Text('Back to Staff Login',
                style: AppTextStyles.outlinedButton),
          ],
        ),
      ),
    );
  }
}