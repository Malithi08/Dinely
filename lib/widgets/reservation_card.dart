import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/reservation.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  const ReservationCard({
    super.key,
    required this.reservation,
    this.onCancel,
    this.onTap,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.redAccent;
      case 'completed':
        return Colors.blueGrey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEE, MMM d • h:mm a');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(reservation.restaurantName,
                      style: AppTextStyles.roleTitle.copyWith(
                        fontSize: 15,
                      )),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(reservation.status)
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reservation.status.toUpperCase(),
                    style: AppTextStyles.smallMuted.copyWith(
                      color: _statusColor(reservation.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: AppColors.brownMuted),
                const SizedBox(width: 6),
                Text(dateFmt.format(reservation.dateTime),
                    style: AppTextStyles.subtitle),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 16, color: AppColors.brownMuted),
                const SizedBox(width: 6),
                Text('${reservation.guests} guests',
                    style: AppTextStyles.subtitle),
                if (reservation.tableNumber != null) ...[
                  const SizedBox(width: 14),
                  const Icon(Icons.table_restaurant_outlined,
                      size: 16, color: AppColors.brownMuted),
                  const SizedBox(width: 6),
                  Text('Table ${reservation.tableNumber}',
                      style: AppTextStyles.subtitle),
                ],
              ],
            ),
            if (onCancel != null &&
                reservation.status != 'cancelled' &&
                reservation.status != 'completed') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_outlined,
                      size: 16, color: Colors.redAccent),
                  label: Text('Cancel',
                      style: AppTextStyles.link
                          .copyWith(color: Colors.redAccent)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}