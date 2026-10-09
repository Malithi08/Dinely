import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/queue_entry.dart';
import '../../models/reservation.dart';
import '../../models/restaurant.dart';
import '../../models/table_status.dart';
import '../../services/auth_service.dart';
import '../../services/queue_service.dart';
import '../../services/reservation_service.dart';
import '../../services/table_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/queue_tile.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/table_status_card.dart';
import '../customer_login.dart';
import '../t_walkin_booking_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final _auth = AuthService();
  final _reservationService = ReservationService();
  final _queueService = QueueService();
  final _tableService = TableService();

  int _tabIndex = 0;
  String _staffName = 'Staff';

  static const String _restaurantId = 'rest_001';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final p = await _auth.getUserProfile();
    if (p != null && mounted) {
      setState(() => _staffName = p['name'] ?? 'Staff');
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ─── TOP BAR ──────────────────────────────────
  Widget _buildTopBar() {
    final now = DateTime.now();
    final dateFmt = DateFormat('MMM d • h:mm a');

    return Container(
      color: AppColors.brownDeep,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Brand
          Text(
            'Dinely',
            style: AppTextStyles.heading.copyWith(
              color: AppColors.cream,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 10),

          // STAFF PORTAL pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cream.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'STAFF',
              style: AppTextStyles.smallMuted.copyWith(
                color: AppColors.cream,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ),

          const Spacer(),

          // Date — flexible so it can shrink on narrow screens
          Flexible(
            child: Text(
              dateFmt.format(now),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.right,
              style: AppTextStyles.smallMuted.copyWith(
                color: AppColors.cream.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Logout — compact icon-only button
          InkWell(
            onTap: _logout,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cream.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                size: 16,
                color: AppColors.cream,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _tabIndex,
      onDestinationSelected: (index) {
        // Walk-Ins tab (index 1) → navigate to walk-in booking screen
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WalkinBookingScreen(
                restaurant: Restaurant(
                  id: _restaurantId,
                  name: 'Dinely Restaurant',
                  address: '',
                  phone: '',
                  imageUrl: '',
                  rating: 4.5,
                ),
              ),
            ),
          );
          return;
        }
        setState(() => _tabIndex = index);
      },
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.primary.withOpacity(0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.event_note_outlined),
          selectedIcon: Icon(Icons.event_note, color: AppColors.primary),
          label: 'Reservations',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_walk_outlined),
          selectedIcon: Icon(Icons.directions_walk, color: AppColors.primary),
          label: 'Walk-Ins',
        ),
        NavigationDestination(
          icon: Icon(Icons.table_restaurant_outlined),
          selectedIcon: Icon(Icons.table_restaurant, color: AppColors.primary),
          label: 'Tables',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
          label: 'Reports',
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        return _buildReservationsTab();
      case 2:
        return _buildTablesTab();
      case 3:
        return _buildReportsTab();
      default:
        return _buildReservationsTab();
    }
  }

  // ─── TAB 1: RESERVATIONS ──────────────────────
  Widget _buildReservationsTab() {
    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.streamAllReservations(),
      builder: (context, resSnap) {
        final reservations = resSnap.data ?? [];
        final now = DateTime.now();
        final todayReservations = reservations.where(
          (r) =>
              r.dateTime.year == now.year &&
              r.dateTime.month == now.month &&
              r.dateTime.day == now.day,
        );

        return StreamBuilder<List<QueueEntry>>(
          stream: _queueService.activeQueueStream(_restaurantId),
          builder: (context, queueSnap) {
            final queue = queueSnap.data ?? [];

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                setState(() {});
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                children: [
                  // Greeting
                  Text(
                    'Hi👋',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 22,
                      color: AppColors.brownDarkest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's what's happening today",
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 20),

                  // ─── OVERVIEW ───
                  _sectionLabel('TODAY\'S OVERVIEW'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.event_note,
                          label: 'Reservations',
                          value: '${todayReservations.length}',
                          accent: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          icon: Icons.people_alt,
                          label: 'In Queue',
                          value: '${queue.length}',
                          accent: Colors.orange,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  // ─── QUEUE ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionLabel('CURRENT QUEUE'),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${queue.length} waiting',
                          style: AppTextStyles.smallMuted.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (queue.isEmpty)
                    _emptyState(
                      icon: Icons.people_outline,
                      message: 'No one in queue',
                      hint: 'Walk-ins will appear here.',
                    )
                  else
                    ...queue.map(
                      (q) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: QueueTile(
                          entry: q,
                          onRemove: () => _queueService.leaveQueue(
                            restaurantId: _restaurantId,
                            queueId: q.id,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Reusable: Section label ─────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.roleTitle.copyWith(
        fontSize: 12,
        letterSpacing: 1.3,
        color: AppColors.brownMuted,
      ),
    );
  }

  // ─── Reusable: Stat card ─────────────────────
  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.heading.copyWith(
              fontSize: 28,
              color: AppColors.brownDarkest,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }

  // ─── Reusable: Empty state ───────────────────
  Widget _emptyState({
    required IconData icon,
    required String message,
    String? hint,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.brownMuted),
          const SizedBox(height: 10),
          Text(
            message,
            style: AppTextStyles.roleTitle.copyWith(
              color: AppColors.brownDarkest,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint, style: AppTextStyles.subtitle),
          ],
        ],
      ),
    );
  }

  // ─── TAB 2: TABLES ────────────────────────────
  Widget _buildTablesTab() {
    return StreamBuilder<List<TableStatus>>(
      stream: _tableService.streamTables(),
      builder: (context, snap) {
        final tables = snap.data ?? [];

        if (tables.isEmpty) {
          final placeholders = [
            TableStatus(id: 'T1', seats: 4, status: 'available'),
            TableStatus(id: 'T2', seats: 2, status: 'occupied'),
            TableStatus(id: 'T3', seats: 6, status: 'reserved'),
            TableStatus(id: 'T4', seats: 4, status: 'available'),
            TableStatus(id: 'T5', seats: 2, status: 'occupied'),
            TableStatus(id: 'T6', seats: 8, status: 'occupied'),
            TableStatus(id: 'T7', seats: 6, status: 'available'),
            TableStatus(id: 'T8', seats: 4, status: 'available'),
          ];
          return _tableGrid(placeholders);
        }
        return _tableGrid(tables);
      },
    );
  }

  Widget _tableGrid(List<TableStatus> tables) {
    final available = tables.where((t) => t.status == 'available').length;
    final occupied = tables.where((t) => t.status == 'occupied').length;
    final reserved = tables.where((t) => t.status == 'reserved').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tables',
            style: AppTextStyles.heading.copyWith(
              fontSize: 22,
              color: AppColors.brownDarkest,
            ),
          ),
          const SizedBox(height: 4),
          Text('Tap a table to change status',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 18),

          // Legend
          Row(
            children: [
              _legendDot(Colors.green, 'Available ($available)'),
              const SizedBox(width: 14),
              _legendDot(Colors.orange, 'Reserved ($reserved)'),
              const SizedBox(width: 14),
              _legendDot(Colors.redAccent, 'Occupied ($occupied)'),
            ],
          ),
          const SizedBox(height: 20),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tables.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.9,
            ),
            itemBuilder: (context, i) {
              return TableStatusCard(
                table: tables[i],
                onTap: () => _showTableActions(tables[i]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.smallMuted.copyWith(fontSize: 11),
        ),
      ],
    );
  }

  void _showTableActions(TableStatus table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.brownMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${table.id} — ${table.seats} seats',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 18,
                  color: AppColors.brownDarkest,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Current status: ${table.status}',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 20),
              _tableAction(
                  'Mark as Available', 'available', Colors.green, table),
              _tableAction(
                  'Mark as Reserved', 'reserved', Colors.orange, table),
              _tableAction(
                  'Mark as Occupied', 'occupied', Colors.redAccent, table),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tableAction(
    String label,
    String status,
    Color color,
    TableStatus table,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () async {
          await _tableService.updateStatus(table.id, status);
          if (mounted) Navigator.pop(context);
        },
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        title: Text(
          label,
          style: AppTextStyles.roleTitle.copyWith(
            color: AppColors.brownDarkest,
          ),
        ),
        tileColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ─── TAB 4: REPORTS ───────────────────────────
  Widget _buildReportsTab() {
    return StreamBuilder<List<Reservation>>(
      stream: _reservationService.streamAllReservations(),
      builder: (context, snap) {
        final all = snap.data ?? [];
        final confirmed = all.where((r) => r.status == 'confirmed').length;
        final pending = all.where((r) => r.status == 'pending').length;
        final cancelled = all.where((r) => r.status == 'cancelled').length;
        final completed = all.where((r) => r.status == 'completed').length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reports',
                style: AppTextStyles.heading.copyWith(
                  fontSize: 22,
                  color: AppColors.brownDarkest,
                ),
              ),
              const SizedBox(height: 4),
              Text('All-time reservation statistics',
                  style: AppTextStyles.subtitle),
              const SizedBox(height: 20),

              // Big total card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL RESERVATIONS',
                      style: AppTextStyles.smallMuted.copyWith(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${all.length}',
                      style: AppTextStyles.heading.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _sectionLabel('BREAKDOWN'),
              const SizedBox(height: 10),
              _reportRow('Confirmed', '$confirmed',
                  color: Colors.green, icon: Icons.check_circle_outline),
              _reportRow('Pending', '$pending',
                  color: Colors.orange, icon: Icons.schedule),
              _reportRow('Completed', '$completed',
                  color: Colors.blue, icon: Icons.verified_outlined),
              _reportRow('Cancelled', '$cancelled',
                  color: Colors.redAccent, icon: Icons.cancel_outlined),
            ],
          ),
        );
      },
    );
  }

  Widget _reportRow(
    String label,
    String value, {
    Color? color,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 16,
                color: color ?? AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.roleTitle.copyWith(
                color: AppColors.brownDarkest,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.heading.copyWith(
              fontSize: 20,
              color: color ?? AppColors.brownDeep,
            ),
          ),
        ],
      ),
    );
  }
}