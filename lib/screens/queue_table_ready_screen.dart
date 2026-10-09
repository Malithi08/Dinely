import 'package:flutter/material.dart';
import '../models/queue_entry.dart';
import '../services/queue_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/availability_bottom_nav.dart';
import '../widgets/queue_progress_bar.dart';

class QueueTableReadyScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final QueueEntry entry;

  const QueueTableReadyScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.entry,
  });

  @override
  State<QueueTableReadyScreen> createState() => _QueueTableReadyScreenState();
}

class _QueueTableReadyScreenState extends State<QueueTableReadyScreen> {
  final _service = QueueService();
  int _navIndex = 3;
  bool _checkingIn = false;

  Future<void> _onCheckIn() async {
    final tableId = widget.entry.tableId;
    if (tableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No table assigned yet')),
      );
      return;
    }

    setState(() => _checkingIn = true);

    final error = await _service.checkIn(
      restaurantId: widget.restaurantId,
      queueId: widget.entry.id,
      tableId: tableId,
    );

    if (!mounted) return;
    setState(() => _checkingIn = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Checked in — enjoy your meal!')),
    );
 
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
            Text('Queue Status'),
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
          
          Container(
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.check_circle,
                                size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'READY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.more_horiz,
                          size: 16,
                          color: AppColors.cream.withOpacity(0.6)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Table is Ready!',
                        style: AppTextStyles.heading.copyWith(
                          color: AppColors.cream,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please proceed to the dining area.',
                        style: AppTextStyles.smallMuted.copyWith(
                          color: AppColors.cream.withOpacity(0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Image.asset(
                      'assets/images/queue_indoor.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.5),
                              AppColors.primary.withOpacity(0.25),
                            ],
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.restaurant,
                          size: 32,
                          color: Colors.white38,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Queue Progress ───
          Text(
            'Queue Progress',
            style: AppTextStyles.roleTitle.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.circle,
                              size: 8, color: Color(0xFF2E7D32)),
                          SizedBox(width: 6),
                          Text(
                            'Ready for Seating',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                QueueProgressBar(status: 'ready'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Info card ───
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              children: [
                _infoRow(
                  icon: Icons.table_restaurant_outlined,
                  label: 'Table',
                  value: entry.tableId ?? 'T--',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Reserved',
                      style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                    indent: 20,
                    endIndent: 20),
                _infoRow(
                  icon: Icons.people_outline,
                  label: 'Guests',
                  value: '${entry.guests}',
                  trailing: Text(
                    'Party Size',
                    style: AppTextStyles.smallMuted.copyWith(fontSize: 11),
                  ),
                ),
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.divider,
                    indent: 20,
                    endIndent: 20),
                _infoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Seating Area',
                  value: 'Indoor',
                  trailing: Text(
                    'Main Hall ›',
                    style: AppTextStyles.link.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Info hint ───
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Need an extra minute? Tap \"I'm Here\" when you enter or notify the front desk to prevent automatic release.",
                    style: AppTextStyles.smallMuted.copyWith(
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── View Reservation ───
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {},
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
                    'View Reservation',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios, size: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ─── I'm Here • Check In ───
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _checkingIn ? null : _onCheckIn,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              icon: _checkingIn
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(Icons.login, size: 18),
              label: Text(
                _checkingIn ? 'Checking in...' : "I'm Here • Check In",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Enjoy your dining experience ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enjoy your dining experience ',
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
      bottomNavigationBar: AvailabilityBottomNav(
        currentIndex: _navIndex,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        onTap: (i) {
          if (i == _navIndex) return;
          setState(() => _navIndex = i);
        },
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.brownMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppTextStyles.smallMuted.copyWith(fontSize: 12.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.roleTitle.copyWith(fontSize: 14),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}