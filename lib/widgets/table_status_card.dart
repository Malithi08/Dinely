import 'package:flutter/material.dart';
import '../models/table_status.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class TableStatusCard extends StatelessWidget {
  final TableStatus table;
  final VoidCallback? onTap;

  const TableStatusCard({super.key, required this.table, this.onTap});

  String get _normalizedStatus => table.status.trim().toLowerCase();

  Color get _statusColor {
    switch (_normalizedStatus) {
      case 'available':
        return Colors.green;
      case 'occupied':
        return Colors.redAccent;
      case 'reserved':
        return Colors.orange;
      default:
        return AppColors.brownMuted;
    }
  }

  String get _statusLabel {
    switch (_normalizedStatus) {
      case 'available':
        return 'Available';
      case 'occupied':
        return 'Occupied';
      case 'reserved':
        return 'Reserved';
      default:
        return _normalizedStatus.isEmpty ? 'Unknown' : _normalizedStatus;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Table ID badge (colored circle)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                table.id,
                style: AppTextStyles.roleTitle.copyWith(
                  color: _statusColor,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('${table.seats} seats',
                style: AppTextStyles.smallMuted.copyWith(fontSize: 11)),
            const SizedBox(height: 2),
            Text(_statusLabel,
                style: AppTextStyles.smallMuted.copyWith(
                  color: _statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                )),
          ],
        ),
      ),
    );
  }
}