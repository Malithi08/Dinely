import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/restaurant_service.dart';

class ManagerReservationsScreen extends StatefulWidget {
  final String restaurantId;

  const ManagerReservationsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<ManagerReservationsScreen> createState() => _ManagerReservationsScreenState();
}

class _ManagerReservationsScreenState extends State<ManagerReservationsScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  String _selectedFilter = 'All';

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return const Color(0xFF2E6F40);
      case 'Seated':
        return AppColors.brownWarm;
      case 'No Show':
      case 'No Showup':
        return Colors.redAccent;
      case 'Cancelled':
        return const Color(0xFF8C7A6B);
      default:
        return AppColors.primary;
    }
  }

  void _showStatusDialog(Map<String, dynamic> reservation) {
    String currentStatus = reservation['status'] ?? 'Confirmed';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Update Status',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: AppColors.brownDeep),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reservation for ${reservation['name'] ?? 'Guest'}',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.brownMuted),
              ),
              const SizedBox(height: 16),
              ...['Confirmed', 'Seated', 'No Show', 'Cancelled'].map((st) {
                final isSelected = currentStatus == st;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? _getStatusColor(st) : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    tileColor: isSelected ? _getStatusColor(st).withValues(alpha: 0.08) : null,
                    leading: Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: _getStatusColor(st),
                    ),
                    title: Text(
                      st,
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: AppColors.brownDeep,
                      ),
                    ),
                    onTap: () async {
                      await _restaurantService.updateReservationStatus(
                        widget.restaurantId,
                        reservation['docId'],
                        st,
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reservation status updated to "$st"'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: _getStatusColor(st),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close', style: GoogleFonts.poppins(color: AppColors.brownMuted)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _restaurantService.streamReservations(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final allReservations = snapshot.data ?? [];
        final filteredReservations = _selectedFilter == 'All'
            ? allReservations
            : allReservations.where((r) => (r['status'] ?? 'Confirmed') == _selectedFilter).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservations',
                      style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brownDeep),
                    ),
                    Text(
                      'View & Update Guest Reservations',
                      style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 13),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${allReservations.length} Bookings',
                    style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Confirmed', 'Seated', 'No Show', 'Cancelled'].map((filter) {
                  final isSel = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSel,
                      selectedColor: AppColors.primary,
                      labelStyle: GoogleFonts.poppins(
                        color: isSel ? Colors.white : AppColors.brownDeep,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            if (filteredReservations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.event_seat_outlined, size: 48, color: AppColors.brownMuted),
                      const SizedBox(height: 12),
                      Text(
                        'No reservations found',
                        style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredReservations.map((res) => _buildReservationCard(res)),
          ],
        );
      },
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'Confirmed';
    final color = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? 'Guest',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.brownDeep),
                      ),
                      Text(
                        '${item['phone'] ?? 'No Phone'} • Party of ${item['party'] ?? 1}',
                        style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 16, color: AppColors.brownMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${item['date'] ?? 'Today'} at ${item['time'] ?? '7:00 PM'}',
                      style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _showStatusDialog(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text(
                    'Edit Status',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
