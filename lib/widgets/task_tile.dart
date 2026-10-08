import 'package:flutter/material.dart';
import '../models/staff_task.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TaskTile extends StatelessWidget {
  final StaffTask task;
  final ValueChanged<bool?> onToggle;
  final VoidCallback? onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    this.onDelete,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case 'high':
        return Colors.redAccent;
      case 'low':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Checkbox(
            value: task.completed,
            onChanged: onToggle,
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTextStyles.roleTitle.copyWith(
                    decoration: task.completed
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.completed
                        ? AppColors.brownMuted
                        : AppColors.brownDeep,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(task.description,
                      style: AppTextStyles.smallMuted,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(task.priority.toUpperCase(),
                        style: AppTextStyles.smallMuted.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 10),
                    Text('• ${task.assignedTo}',
                        style: AppTextStyles.smallMuted),
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: Colors.redAccent),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}