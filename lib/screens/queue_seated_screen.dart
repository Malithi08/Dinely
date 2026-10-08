import 'package:flutter/material.dart';
import '../models/queue_entry.dart';
import '../services/queue_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/availability_bottom_nav.dart';
import 'placeholders/availability_home_placeholder.dart';
import 'placeholders/availability_profile_placeholder.dart';
import 'placeholders/availability_reservation_placeholder.dart';

class QueueSeatedScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final QueueEntry entry;

  const QueueSeatedScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.entry,
  });

  @override
  State<QueueSeatedScreen> createState() => _QueueSeatedScreenState();
}

class _QueueSeatedScreenState extends State<QueueSeatedScreen> {
  final _service = QueueService();
  int _navIndex = 3;
  bool _finishing = false;

  Future<void> _onFinish() async {
    final tableId = widget.entry.tableId;
    if (tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No table assigned')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Done with your meal?',
            style: AppTextStyles.roleTitle.copyWith(fontSize: 16),
          ),
          content: Text(
            'This will free your table so the next customer in the queue can be seated.',
            style: AppTextStyles.subtitle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Not yet',
                style: AppTextStyles.link.copyWith(
                  color: AppColors.brownMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.cream,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Yes, finish',
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

    setState(() => _finishing = true);

    final error = await _service.finishMeal(
      restaurantId: widget.restaurantId,
      queueId: widget.entry.id,
      tableId: tableId,
    );

    if (!mounted) return;
    setState(() => _finishing = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thanks for dining with us!')),
    );
    // No Navigator.pop — the stream swaps back to Join Queue.
  }

  void _onNavTap(int i) {
    if (i == _navIndex) return;
    setState(() => _navIndex = i);
    switch (i) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AvailabilityHomePlaceholderScreen(),
          ),
        );
        break;
      case 1:
        Navigator.pop(context);
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const AvailabilityReservationPlaceholderScreen(),
          ),
        );
        break;
      case 3:
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AvailabilityProfilePlaceholderScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

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
            Icon(Icons.people_alt, size: 18),
            SizedBox(width: 8),
            Text('Seated'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // Hero image with SEATED badge
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.asset(
                    'assets/images/queue_indoor.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3A1F10), Color(0xFF7E553B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
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
                        color: const Color(0xFF2E7D32),
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
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'SEATED',
                            style: TextStyle(
                              color: Colors.white,
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

          Text(
            'Enjoy your meal!',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'You are seated at Table ${entry.tableId ?? "T--"}.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 24),

          Container(
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
                  value: entry.tableId ?? 'T--',
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
                  value: '${entry.guests}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _finishing ? null : _onFinish,
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
                children: [
                  if (_finishing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cream,
                      ),
                    )
                  else
                    const Icon(Icons.check, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _finishing ? 'Finishing...' : "I'm Done",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tap "I\'m Done" when you leave to free the table for the next customer.',
            textAlign: TextAlign.center,
            style: AppTextStyles.smallMuted.copyWith(fontSize: 11.5),
          ),
        ],
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