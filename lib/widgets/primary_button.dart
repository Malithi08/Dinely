import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool showArrow;

  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.cream,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: AppTextStyles.buttonText),
            if (showArrow) ...[
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_ios,
                  size: 12, color: AppColors.cream),
            ],
          ],
        ),
      ),
    );
  }
}