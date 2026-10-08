import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/queue_entry.dart';
import '../services/queue_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/availability_bottom_nav.dart';
import '../widgets/leave_queue_dialog.dart';
import '../widgets/queue_position_card.dart';
import '../widgets/queue_progress_bar.dart';
import 'placeholders/availability_home_placeholder.dart';
import 'placeholders/availability_profile_placeholder.dart';
import 'placeholders/availability_reservation_placeholder.dart';

class QueueStatusScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final QueueEntry entry;

  const QueueStatusScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.entry,
  });

  @override
  State<QueueStatusScreen> createState() => _QueueStatusScreenState();
}

class _QueueStatusScreenState extends State<QueueStatusScreen> {
  final _service = QueueService();
  int _navIndex = 3;
  bool _leaving = false;
  Timer? _promotionTimer;

  @override
  void initState() {
    super.initState();
    // Try time-based promotion every 30 seconds
    _promotionTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _service.tryTimeBasedPromote(widget.restaurantId),
    );
    // Also try immediately
    _service.tryTimeBasedPromote(widget.restaurantId);
  }

  @override
  void dispose() {
    _promotionTimer?.cancel();
    super.dispose();
  }

  Future<void> _onLeave() async {
    final confirmed = await showLeaveQueueDialog(
      context,
      position: widget.entry.position > 0 ? widget.entry.position : 1,
    );
    if (!confirmed) return;

    setState(() => _leaving = true);

    final error = await _service.leaveQueue(
      restaurantId: widget.restaurantId,
      queueId: widget.entry.id,
    );

    if (!mounted) return;
    setState(() => _leaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Left the queue')),
    );

    Navigator.pop(context);
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
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QueueEntry?>(
      stream: uid == null
          ? const Stream.empty()
          : _service.myQueueStream(
              restaurantId: widget.restaurantId,
              customerId: uid,
            ),
      builder: (context, snapshot) {
        final entry = snapshot.data ?? widget.entry;

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
              QueuePositionCard(entry: entry),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: QueueProgressBar(status: entry.status),
              ),
              const SizedBox(height: 24),

              Text(
                'Your Queue',
                style: AppTextStyles.heading.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 12),
              _buildTimeline(entry),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_outlined,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "We'll notify you when your table is ready.",
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.brownDeep,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _leaving ? null : _onLeave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB00020),
                    side: const BorderSide(color: Color(0xFFB00020)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  icon: _leaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFB00020),
                          ),
                        )
                      : const Icon(Icons.logout, size: 18),
                  label: Text(
                    _leaving ? 'Leaving...' : 'Leave Queue',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 8,
                      child: Image.asset(
                        'assets/images/queue_indoor.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF3A1F10),
                                Color(0xFF7E553B)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.restaurant,
                            size: 40,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.65),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      bottom: 12,
                      right: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'The Dining Room',
                            style: AppTextStyles.roleTitle.copyWith(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Wait in comfort while we prepare your table.',
                            style: AppTextStyles.smallMuted.copyWith(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: AvailabilityBottomNav(
            currentIndex: _navIndex,
            onTap: _onNavTap,
          ),
        );
      },
    );
  }

  Widget _buildTimeline(QueueEntry entry) {
    final items = <_TimelineItem>[];

    items.add(_TimelineItem(
      icon: Icons.check_circle,
      iconColor: const Color(0xFF2E7D32),
      title: 'Joined Queue',
      subtitle: _formatTime(entry.joinedAt),
      trailing: null,
      trailingColor: null,
      highlighted: false,
    ));

    final position = entry.position > 0 ? entry.position : 1;
    final groupsAhead = position > 1 ? position - 1 : 0;
    items.add(_TimelineItem(
      icon: Icons.people_alt,
      iconColor: AppColors.primary,
      title: '#${position.toString().padLeft(2, '0')}',
      subtitle:
          '$groupsAhead ${groupsAhead == 1 ? "group" : "groups"} ahead · ${entry.estimatedWaitMinutes <= 0 ? "You're next" : "${entry.estimatedWaitMinutes} min"}',
      trailing: 'Waiting',
      trailingColor: AppColors.primary,
      highlighted: true,
    ));

    items.add(_TimelineItem(
      icon: Icons.restaurant_menu,
      iconColor: AppColors.brownMuted,
      title: 'Table Being Prepared',
      subtitle: '',
      trailing: null,
      trailingColor: null,
      highlighted: false,
    ));

    items.add(_TimelineItem(
      icon: Icons.check,
      iconColor: AppColors.brownMuted,
      title: 'Table Ready',
      subtitle: '',
      trailing: null,
      trailingColor: null,
      highlighted: false,
    ));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: item.highlighted
                            ? AppColors.primary
                            : AppColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.highlighted
                              ? AppColors.primary
                              : AppColors.inputBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        size: 15,
                        color: item.highlighted
                            ? AppColors.cream
                            : item.iconColor,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 1.5,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppColors.inputBorder,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTextStyles.roleTitle.copyWith(
                                  fontSize: 13,
                                  color: item.highlighted
                                      ? AppColors.primary
                                      : AppColors.brownDeep,
                                ),
                              ),
                              if (item.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  style: AppTextStyles.smallMuted
                                      .copyWith(fontSize: 11.5),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (item.trailing != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (item.trailingColor ??
                                      AppColors.primary)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.trailing!,
                              style: AppTextStyles.smallMuted.copyWith(
                                color: item.trailingColor ??
                                    AppColors.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

class _TimelineItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? trailing;
  final Color? trailingColor;
  final bool highlighted;

  _TimelineItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    required this.highlighted,
  });
}