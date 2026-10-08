import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/queue_entry.dart';
import '../services/queue_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/availability_bottom_nav.dart';
import 'placeholders/availability_home_placeholder.dart';
import 'placeholders/availability_profile_placeholder.dart';
import 'placeholders/availability_reservation_placeholder.dart';
import 'queue_seated_screen.dart';
import 'queue_status_screen.dart';
import 'queue_table_ready_screen.dart';

class QueueTabScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const QueueTabScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<QueueTabScreen> createState() => _QueueTabScreenState();
}

class _QueueTabScreenState extends State<QueueTabScreen> {
  final _service = QueueService();
  int _navIndex = 3;
  bool _joining = false;

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

  Future<void> _onJoin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final guests = await _pickGuests();
    if (guests == null) return;

    setState(() => _joining = true);

    final name = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@').first ??
        'Guest';

    final error = await _service.joinQueue(
      restaurantId: widget.restaurantId,
      customerId: uid,
      customerName: name,
      guests: guests,
    );

    if (!mounted) return;
    setState(() => _joining = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    _service.tryAutoPromote(widget.restaurantId);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You joined the queue')),
    );
  }

  Future<int?> _pickGuests() async {
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text('How many guests?',
                  style: AppTextStyles.roleTitle.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              ...List.generate(6, (i) {
                final n = i + 1;
                return ListTile(
                  title: Text(
                    '$n ${n == 1 ? "Guest" : "Guests"}',
                    style: AppTextStyles.inputText,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 12, color: AppColors.brownMuted),
                  onTap: () => Navigator.pop(context, n),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QueueEntry?>(
      stream: uid == null
          ? const Stream.empty()
          : _service.myAnyStatusStream(
              restaurantId: widget.restaurantId,
              customerId: uid,
            ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.cream,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final entry = snapshot.data;

        if (entry == null) {
          return _buildJoinScreen();
        }

        if (entry.isReady) {
          return QueueTableReadyScreen(
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            entry: entry,
          );
        }

        if (entry.isSeated) {
          return QueueSeatedScreen(
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            entry: entry,
          );
        }

        return QueueStatusScreen(
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
          entry: entry,
        );
      },
    );
  }

  Widget _buildJoinScreen() {
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
            Text('Queue'),
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          // ─── Brown hero box with queue_hero image ─
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C2E17), Color(0xFF3E2415)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people_alt,
                                size: 11, color: AppColors.cream),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE QUEUE',
                              style: AppTextStyles.smallMuted.copyWith(
                                color: AppColors.cream.withOpacity(0.9),
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
                          size: 18,
                          color: AppColors.cream.withOpacity(0.6)),
                    ],
                  ),
                ),
                // Image inside the brown box
                Container(
                  margin: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Image.asset(
                      'assets/images/queue_hero.png',
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
          const SizedBox(height: 24),

          Text(
            'Join the Queue',
            textAlign: TextAlign.center,
            style: AppTextStyles.heading.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            "All tables are currently full. Join the queue and we'll seat you as soon as a table is ready.",
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              children: [
                _joinInfoRow(
                  icon: Icons.schedule,
                  title: 'Real-time position',
                  subtitle: 'See your live position and estimated wait',
                ),
                const SizedBox(height: 12),
                _joinInfoRow(
                  icon: Icons.notifications_active_outlined,
                  title: 'Get notified',
                  subtitle:
                      "We'll let you know the moment your table is ready",
                ),
                const SizedBox(height: 12),
                _joinInfoRow(
                  icon: Icons.cancel_outlined,
                  title: 'Leave anytime',
                  subtitle: 'Change your mind? Just tap Leave Queue',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _joining ? null : _onJoin,
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
                  if (_joining)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.cream,
                      ),
                    )
                  else
                    const Icon(Icons.add, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _joining ? 'Joining...' : 'Join Queue',
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
        ],
      ),
      bottomNavigationBar: AvailabilityBottomNav(
        currentIndex: _navIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _joinInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.roleTitle.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.smallMuted.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}