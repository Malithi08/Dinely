import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AreaChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AreaChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.inputBorder,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.link.copyWith(
              color: selected ? AppColors.cream : AppColors.brownDeep,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}