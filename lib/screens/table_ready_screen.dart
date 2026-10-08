import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dining_table.dart';
import '../services/dining_table_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/availability_bottom_nav.dart';
import 'placeholders/availability_home_placeholder.dart';
import 'placeholders/availability_profile_placeholder.dart';
import 'placeholders/availability_queue_placeholder.dart';
import 'placeholders/availability_reservation_placeholder.dart';
import 'table_availability_screen.dart';

class TableReadyScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final DiningTable table;

  const TableReadyScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.table,
  });

  @override
  State<TableReadyScreen> createState() => _TableReadyScreenState();
}

class _TableReadyScreenState extends State<TableReadyScreen> {
  int _navIndex = 1;
  bool _cancelling = false;

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _onNavTap(int i) {
    if (i == _navIndex) return;
    setState(() => _navIndex = i);
    switch (i) {
      case 0:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AvailabilityHomePlaceholderScreen(),
          ),
          (_) => false,
        );
        break;
      case 1:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AvailabilityReservationPlaceholderScreen(),
          ),
          (_) => false,
        );
        break;
      case 2:
        break;
      case 3:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AvailabilityQueuePlaceholderScreen(),
          ),
          (_) => false,
        );
        break;
      case 4:
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AvailabilityProfilePlaceholderScreen(),
          ),
          (_) => false,
        );
        break;
    }
  }

  // ─── Confirm + Cancel ─────────────────────
  Future<void> _confirmCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Cancel reservation?',
            style: AppTextStyles.roleTitle.copyWith(fontSize: 16),
          ),
          content: Text(
            'Your reservation for table ${widget.table.tableNumber} will be cancelled. This cannot be undone.',
            style: AppTextStyles.subtitle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Keep it',
                style: AppTextStyles.link.copyWith(
                  color: AppColors.brownMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB00020),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Cancel reservation',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await _doCancel();
  }

  Future<void> _doCancel() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again')),
      );
      return;
    }

    setState(() => _cancelling = true);

    final error = await DiningTableService().cancelReservation(
      restaurantId: widget.restaurantId,
      tableId: widget.table.id,
      customerId: uid,
    );

    if (!mounted) return;
    setState(() => _cancelling = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservation cancelled')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => TableAvailabilityScreen(
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
        ),
      ),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.table;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cream,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.table_restaurant, size: 18),
            SizedBox(width: 8),
            Text('Table Selection'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => TableAvailabilityScreen(
                  restaurantId: widget.restaurantId,
                  restaurantName: widget.restaurantName,
                ),
              ),
              (route) => route.isFirst,
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Hero image with bottom-pinned badge ───
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.asset(
                      'assets/images/table_ready.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF3A1F10),
                              Color(0xFF7E553B),
                              Color(0xFF3A1F10),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.restaurant,
                          size: 60,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.15),
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle,
                                color: AppColors.cream, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'READY NOW',
                              style: TextStyle(
                                color: AppColors.cream,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Title ─────────────────────────────
            Text(
              'Your Table is Ready!',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'Please proceed to the dining area.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 24),

            // ─── Info card ─────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Column(
                children: [
                  _infoRow(
                    icon: Icons.table_restaurant_outlined,
                    label: 'TABLE',
                    value: t.tableNumber,
                  ),
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                      indent: 20,
                      endIndent: 20),
                  _infoRow(
                    icon: Icons.people_outline,
                    label: 'GUESTS',
                    value: '${t.seats}',
                  ),
                  const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider,
                      indent: 20,
                      endIndent: 20),
                  _infoRow(
                    icon: Icons.chair_outlined,
                    label: 'SEATING AREA',
                    value: _capitalize(t.area),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Make Reservation button ───────────
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reservation confirmed!'),
                    ),
                  );
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TableAvailabilityScreen(
                        restaurantId: widget.restaurantId,
                        restaurantName: widget.restaurantName,
                      ),
                    ),
                    (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.cream,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Make Reservation',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ─── Cancel Reservation button ─────────
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _cancelling ? null : _confirmCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB00020),
                  side: const BorderSide(color: Color(0xFFB00020)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  backgroundColor: Colors.transparent,
                ),
                icon: _cancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFB00020),
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: Text(
                  _cancelling ? 'Cancelling...' : 'Cancel Reservation',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ─── Enjoy your meal! ──────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Enjoy your meal! ',
                  style: AppTextStyles.subtitle.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Icon(Icons.restaurant,
                    size: 16, color: AppColors.brownMuted),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: AvailabilityBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brownMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.smallMuted.copyWith(
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTextStyles.roleTitle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}