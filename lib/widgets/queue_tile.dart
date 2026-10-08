import 'package:flutter/material.dart';
import '../models/queue_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class QueueTile extends StatelessWidget {
  final QueueEntry entry;
  final VoidCallback? onRemove;

  const QueueTile({super.key, required this.entry, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              color: AppColors.tan.withOpacity(0.35),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#${entry.position}',
              style: AppTextStyles.roleTitle.copyWith(fontSize: 15),
            ),
          ),
          const SizedBox(width: 14),

          // Name + phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name,
                    style: AppTextStyles.roleTitle.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(entry.phone, style: AppTextStyles.subtitle),
              ],
            ),
          ),

          // Party + wait time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Party: ${entry.partySize}',
                  style: AppTextStyles.roleTitle.copyWith(fontSize: 13)),
              const SizedBox(height: 2),
              Text('Waiting: ${entry.waitingMinutes} min',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 12)),
            ],
          ),

          if (onRemove != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
              onPressed: onRemove,
              tooltip: 'Remove from queue',
            ),
          ],
        ],
      ),
    );
  }
}
