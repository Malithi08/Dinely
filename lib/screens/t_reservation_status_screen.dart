import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/t_reservation.dart';
import '../services/t_reservation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/availability_bottom_nav.dart';

class TReservationStatusScreen extends StatefulWidget {
  const TReservationStatusScreen({super.key});

  @override
  State<TReservationStatusScreen> createState() =>
      _TReservationStatusScreenState();
}

class _TReservationStatusScreenState extends State<TReservationStatusScreen> {
  int _navIndex = 1;

  // ─── Format Date ───
  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  // ─── Reference Number ───
  String _reference(String id) {
    if (id.length < 8) return '#DIN${id.toUpperCase()}';
    return '#DIN${id.substring(0, 4).toUpperCase()}';
  }

  // ─── Is Past Reservation ───
  bool _isPast(TReservation r) {
    if (r.reservedDate == null) return false;
    final now = DateTime.now();
    final resDate = DateTime(
      r.reservedDate!.year,
      r.reservedDate!.month,
      r.reservedDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return resDate.isBefore(today);
  }

  // ─── Is Today ───
  bool _isToday(TReservation r) {
    if (r.reservedDate == null) return false;
    final now = DateTime.now();
    final resDate = DateTime(
      r.reservedDate!.year,
      r.reservedDate!.month,
      r.reservedDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return resDate == today;
  }

  // ─── Cancel Reservation ───
  Future<void> _cancelReservation(TReservation r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Cancel reservation?',
          style: AppTextStyles.roleTitle.copyWith(fontSize: 16),
        ),
        content: Text(
          'Your reservation for table ${r.tableNumber} will be cancelled. This cannot be undone.',
          style: AppTextStyles.subtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Keep it',
              style: AppTextStyles.link.copyWith(
                color: AppColors.brownMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB00020),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final error = await TReservationService().cancelReservation(
      reservationId: r.id,
      restaurantId: r.restaurantId,
      tableId: r.tableId,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reservation cancelled'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ─── Directions ───
  Future<void> _openDirections(String restaurant) async {
    final query = Uri.encodeComponent(restaurant);
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          foregroundColor: AppColors.brownDarkest,
          elevation: 0,
          title: const Text('Reservation Status'),
        ),
        body: const Center(child: Text('Please sign in')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,

      // ─── AppBar ───
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.brownDarkest,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reservation Status',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.brownDarkest,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.brownDarkest,
            ),
            onPressed: () {},
          ),
        ],
      ),

      body: StreamBuilder<List<TReservation>>(
        stream: TReservationService().userReservations(uid),
        builder: (context, snap) {
          // ─── Loading ───
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          // ─── Error ───
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading reservations',
                      style: AppTextStyles.roleTitle.copyWith(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snap.error}',
                      style: AppTextStyles.smallMuted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final list = snap.data ?? [];

          // ─── Empty ───
          if (list.isEmpty) {
            return _buildEmptyState();
          }

          // ─── Latest Reservation ───
          final reservation = list.first;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subtitle
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.brownMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Track the status of your reservation.',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Reservation Pass Card ───
                _buildReservationPass(reservation),

                const SizedBox(height: 14),

                // ─── Restaurant Image Hero ───
                _buildRestaurantHero(reservation),

                const SizedBox(height: 20),

                // ─── Timeline ───
                _buildTimeline(reservation),

                const SizedBox(height: 20),

                // ─── Info Banner ───
                _buildInfoBanner(),

                const SizedBox(height: 20),

                // ─── Back to Home Button ───
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.popUntil(
                        context,
                        (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.cream,
                      elevation: 4,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),

      bottomNavigationBar: AvailabilityBottomNav(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == _navIndex) return;
          setState(() => _navIndex = i);
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // EMPTY STATE
  // ══════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: 60,
                color: AppColors.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Reservations Yet',
              style: AppTextStyles.heading.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Book a table and it will\nappear here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle.copyWith(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // RESERVATION PASS CARD
  // ══════════════════════════════════════════
  Widget _buildReservationPass(TReservation r) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.inputBorder.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Label + Live Status Badge
          Row(
            children: [
              Text(
                'RESERVATION PASS',
                style: AppTextStyles.smallMuted.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.brownMuted,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.deepOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live Status',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reference Number + Copy
          Row(
            children: [
              Text(
                _reference(r.id),
                style: AppTextStyles.heading.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brownDarkest,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.content_copy_outlined,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Table + Area
          Row(
            children: [
              const Icon(
                Icons.table_restaurant,
                size: 14,
                color: AppColors.brownMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'Table ${r.tableNumber} • ${r.area}',
                style: AppTextStyles.smallMuted.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brownDarkest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // RESTAURANT HERO
  // ══════════════════════════════════════════
  Widget _buildRestaurantHero(TReservation r) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Decorative icon
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.restaurant,
                size: 180,
                color: Colors.white.withOpacity(0.06),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFD54F),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'DINELY PRIME SEATING',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Restaurant name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.restaurantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDate(r.reservedDate)} • ${r.reservedTime}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // TIMELINE
  // ══════════════════════════════════════════
  Widget _buildTimeline(TReservation r) {
    final isToday = _isToday(r);
    final isPast = _isPast(r);

    // Calculate step status
    final steps = [
      _TimelineStep(
        title: 'Reservation Created',
        subtitle: 'Party of ${r.seats} booked for dinner',
        time: _timeAgo(r.reservedAt),
        status: _StepStatus.completed,
      ),
      _TimelineStep(
        title: 'Table Selected',
        subtitle: 'Assigned to Table ${r.tableNumber} (${r.area})',
        time: _timeAgo(r.reservedAt.add(const Duration(minutes: 3))),
        status: _StepStatus.completed,
      ),
      _TimelineStep(
        title: 'Confirmed by Host',
        subtitle: 'Host confirmed table availability',
        time: _timeAgo(r.reservedAt.add(const Duration(minutes: 5))),
        status: _StepStatus.completed,
      ),
      _TimelineStep(
        title: 'Arriving at Restaurant',
        subtitle: isPast
            ? 'Completed visit'
            : 'Estimated arrival: ${r.reservedTime}',
        time: isToday && !isPast ? 'In progress' : null,
        status: isPast
            ? _StepStatus.completed
            : (isToday ? _StepStatus.active : _StepStatus.pending),
        showActions: isToday && !isPast,
      ),
      _TimelineStep(
        title: 'Seated & Welcomed',
        subtitle: 'Check-in at front desk with QR pass',
        time: null,
        status: _StepStatus.pending,
      ),
      _TimelineStep(
        title: 'Dining Completed',
        subtitle: 'Experience settlement & feedback',
        time: null,
        status: _StepStatus.pending,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.inputBorder.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Timeline',
                style: AppTextStyles.roleTitle.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brownDarkest,
                ),
              ),
              const Spacer(),
              Text(
                'Step ${isPast ? 6 : (isToday ? 4 : 3)} of 6',
                style: AppTextStyles.smallMuted.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Steps
          ...List.generate(steps.length, (i) {
            return _buildTimelineStep(
              steps[i],
              isLast: i == steps.length - 1,
              r: r,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    _TimelineStep step, {
    required bool isLast,
    required TReservation r,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Icon Column ───
          Column(
            children: [
              _buildStepIcon(step.status),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: step.status == _StepStatus.completed
                        ? AppColors.primary.withOpacity(0.4)
                        : AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // ─── Content Column ───
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          step.title,
                          style: AppTextStyles.roleTitle.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: step.status == _StepStatus.completed
                                ? AppColors.brownDarkest
                                : AppColors.brownMuted,
                          ),
                        ),
                      ),
                      if (step.time != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: step.status == _StepStatus.active
                                ? Colors.orange.shade50
                                : AppColors.cream,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            step.time!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: step.status == _StepStatus.active
                                  ? Colors.deepOrange.shade700
                                  : AppColors.brownMuted,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    step.subtitle,
                    style: AppTextStyles.smallMuted.copyWith(
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),

                  // Actions (Directions + Running Late)
                  if (step.showActions) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Directions
                        _actionChip(
                          icon: Icons.directions_outlined,
                          label: 'Directions',
                          onTap: () => _openDirections(r.restaurantName),
                        ),
                        const SizedBox(width: 8),
                        // Running Late
                        _actionChip(
                          icon: Icons.access_time,
                          label: 'Running Late?',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Restaurant has been notified',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIcon(_StepStatus status) {
    switch (status) {
      case _StepStatus.completed:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check,
            size: 14,
            color: Colors.white,
          ),
        );

      case _StepStatus.active:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.deepOrange,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.local_dining,
            size: 12,
            color: Colors.deepOrange.shade700,
          ),
        );

      case _StepStatus.pending:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.inputBorder,
              width: 1.5,
            ),
          ),
          child: Icon(
            Icons.circle_outlined,
            size: 10,
            color: AppColors.brownMuted.withOpacity(0.5),
          ),
        );
    }
  }

  Widget _actionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: AppColors.primary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Time Ago Helper ───
  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ══════════════════════════════════════════
  // INFO BANNER
  // ══════════════════════════════════════════
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFE082),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB300).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule,
              size: 14,
              color: Color(0xFFFFB300),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please arrive 10 minutes prior to your reservation time.',
                  style: AppTextStyles.smallMuted.copyWith(
                    fontSize: 11.5,
                    height: 1.4,
                    color: const Color(0xFF7A5C00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Need to modify? Call +94 112 234 5678',
                  style: AppTextStyles.smallMuted.copyWith(
                    fontSize: 10,
                    color: const Color(0xFF7A5C00),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════
enum _StepStatus { completed, active, pending }

class _TimelineStep {
  final String title;
  final String subtitle;
  final String? time;
  final _StepStatus status;
  final bool showActions;

  _TimelineStep({
    required this.title,
    required this.subtitle,
    this.time,
    required this.status,
    this.showActions = false,
  });
}