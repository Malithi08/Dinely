import 'package:flutter/material.dart';
import '../../models/reservation.dart';
import '../../services/auth_service.dart';
import '../../services/reservation_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/reservation_card.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() =>
      _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final _service = ReservationService();
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('My Reservations',
              style: AppTextStyles.heading.copyWith(fontSize: 22)),
        ),
      ),
      body: StreamBuilder<List<Reservation>>(
        stream: _service.streamUserReservations(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary),
            );
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy_outlined,
                      size: 70, color: AppColors.brownMuted),
                  const SizedBox(height: 16),
                  Text('No reservations yet',
                      style: AppTextStyles.heading
                          .copyWith(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('Book a table from the Home tab',
                      style: AppTextStyles.subtitle),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snap.data!.length,
            itemBuilder: (context, i) {
              final r = snap.data![i];
              return ReservationCard(
                reservation: r,
                onCancel: () => _confirmCancel(r),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(Reservation r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Reservation?'),
        content: Text(
            'Cancel your booking at ${r.restaurantName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Booking',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _service.updateStatus(r.id, 'cancelled');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation cancelled')),
      );
    }
  }
}