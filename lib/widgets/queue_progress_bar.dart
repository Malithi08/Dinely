import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class QueueProgressBar extends StatelessWidget {
  final String status;

  const QueueProgressBar({super.key, required this.status});

  static const _steps = ['Waiting', 'Preparing', 'Ready', 'Seated'];

  int get _activeIndex {
    switch (status) {
      case 'waiting':
        return 0;
      case 'preparing':
        return 1;
      case 'ready':
        return 2;
      case 'seated':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final beforeActive = (i ~/ 2) < _activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: beforeActive
                  ? AppColors.primary
                  : AppColors.inputBorder,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isActive = stepIndex <= _activeIndex;
        final isCurrent = stepIndex == _activeIndex;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.inputBorder,
                  width: 2,
                ),
              ),
              child: isActive
                  ? const Icon(Icons.check,
                      size: 12, color: AppColors.cream)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              _steps[stepIndex],
              style: AppTextStyles.smallMuted.copyWith(
                fontSize: 9.5,
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w500,
                color: isCurrent
                    ? AppColors.primary
                    : AppColors.brownMuted,
              ),
            ),
          ],
        );
      }),
    );
  }
}