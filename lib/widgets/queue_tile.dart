import 'package:flutter/material.dart';
import '../models/queue_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class QueueTile extends StatelessWidget {
  final QueueEntry entry;
  final VoidCallback? onRemove;

  const QueueTile({
    super.key,
    required this.entry,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          // Position badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#${entry.position.toString().padLeft(2, '0')}',
              style: AppTextStyles.roleTitle.copyWith(
                color: AppColors.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.customerName,
                  style: AppTextStyles.roleTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Party: ${entry.guests}',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 2),
                Text(
                  'Waiting: ${entry.estimatedWaitMinutes} min',
                  style: AppTextStyles.smallMuted,
                ),
              ],
            ),
          ),

          // Remove button
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: Colors.redAccent,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}