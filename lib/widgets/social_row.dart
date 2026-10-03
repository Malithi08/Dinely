import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SocialRow extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onFacebook;

  const SocialRow({
    super.key,
    this.onGoogle,
    this.onFacebook,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(
          onTap: onGoogle,
          child: Image.asset(
            'assets/images/google.png',
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.g_mobiledata,
              size: 30,
              color: Color(0xFF4285F4),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _socialButton(
          onTap: onFacebook,
          child: const FaIcon(
            FontAwesomeIcons.facebookF,
            size: 24,
            color: AppColors.facebookBlue,
          ),
        ),
      ],
    );
  }

  Widget _socialButton({required Widget child, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.inputBorder),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class OrDivider extends StatelessWidget {
  final String text;
  const OrDivider({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: AppTextStyles.smallMuted),
        ),
        const Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}