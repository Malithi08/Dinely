import 'package:flutter/material.dart';
import '../models/queue_entry.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class QueuePositionCard extends StatelessWidget {
  final QueueEntry entry;

  const QueuePositionCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final position = entry.position;
    final displayPosition = position > 0 ? position : 1;
    final groupsAhead = displayPosition > 1 ? displayPosition - 1 : 0;
    final waitMinutes = entry.estimatedWaitMinutes;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C2E17), Color(0xFF3E2415)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cream.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_alt,
                        size: 10, color: AppColors.cream),
                    const SizedBox(width: 4),
                    Text(
                      "YOU'RE IN THE QUEUE",
                      style: AppTextStyles.smallMuted.copyWith(
                        color: AppColors.cream.withOpacity(0.9),
                        fontSize: 8,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Icon(Icons.more_horiz,
                  size: 16, color: AppColors.cream.withOpacity(0.6)),
            ],
          ),
          const SizedBox(height: 12),

          // Position + groups ahead (stacked) on the left, wait chip on the right
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: position above, groups ahead below
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#${displayPosition.toString().padLeft(2, '0')}',
                    style: AppTextStyles.heading.copyWith(
                      color: AppColors.cream,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$groupsAhead ${groupsAhead == 1 ? "group" : "groups"} ahead',
                    style: AppTextStyles.smallMuted.copyWith(
                      color: AppColors.cream.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Right: estimated wait chip
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cream.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Estimated wait',
                      style: AppTextStyles.smallMuted.copyWith(
                        color: AppColors.cream.withOpacity(0.7),
                        fontSize: 8.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 11, color: AppColors.cream),
                        const SizedBox(width: 3),
                        Text(
                          waitMinutes <= 0
                              ? "You're next"
                              : '$waitMinutes min',
                          style: AppTextStyles.roleTitle.copyWith(
                            color: AppColors.cream,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}