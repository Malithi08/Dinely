import 'package:flutter/material.dart';
import '../models/dining_table.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DiningTableCard extends StatelessWidget {
  final DiningTable table;
  final bool selected;
  final VoidCallback? onTap;

  const DiningTableCard({
    super.key,
    required this.table,
    this.selected = false,
    this.onTap,
  });

  Color get _statusColor {
    switch (table.status) {
      case 'available':
        return const Color(0xFF2E7D32);
      case 'reserved':
        return const Color(0xFFB8860B);
      case 'occupied':
        return const Color(0xFFB00020);
      default:
        return AppColors.brownMuted;
    }
  }

  String get _statusLabel {
    switch (table.status) {
      case 'available':
        return 'Available';
      case 'reserved':
        return 'Reserved';
      case 'occupied':
        return 'Occupied';
      default:
        return 'Unknown';
    }
  }

  IconData get _areaIcon {
    switch (table.area) {
      case 'indoor':
        return Icons.chair_outlined;
      case 'patio':
        return Icons.deck_outlined;
      case 'rooftop':
        return Icons.roofing_outlined;
      default:
        return Icons.table_restaurant_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = table.isAvailable;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.inputBorder,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Icon row ─────────────────────
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _areaIcon,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.primary,
                    ),
                ],
              ),

              // space between icon and table number
              const SizedBox(height: 12),

              // ─── Table number ─────────────────
              Text(
                table.tableNumber,
                style: AppTextStyles.roleTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),

              // space between number and seats
              const SizedBox(height: 6),

              // ─── Seats ────────────────────────
              Text(
                '${table.seats} Seats',
                style: AppTextStyles.smallMuted.copyWith(
                  fontSize: 10.5,
                  height: 1.1,
                ),
              ),

              // space between seats and badge
              const SizedBox(height: 12),

              // ─── Status badge ─────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _statusLabel,
                  style: AppTextStyles.smallMuted.copyWith(
                    color: _statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 9.5,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}