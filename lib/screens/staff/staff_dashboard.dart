import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/queue_entry.dart';
import '../../models/reservation.dart';
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
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  // ─── TOP BAR ──────────────────────────────────
  Widget _buildTopBar() {
    final now = DateTime.now();
    final dateFmt = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      color: AppColors.brownDeep,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Text(
            'Dinely',
            style: AppTextStyles.heading.copyWith(
              color: AppColors.cream,
              fontSize: 22,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cream.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'STAFF PORTAL',
              style: AppTextStyles.smallMuted.copyWith(
                color: AppColors.cream,
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Spacer(),
          Text(
            dateFmt.format(now),
            style: AppTextStyles.smallMuted.copyWith(
              color: AppColors.cream.withOpacity(0.85),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 16, color: AppColors.cream),
            label: Text(
              'Logout',
              style: AppTextStyles.smallMuted.copyWith(
                color: AppColors.cream,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.cream.withOpacity(0.12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── TAB BAR ──────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['Reservations', 'Queue', 'Tables', 'Reports'];
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _tabIndex == i;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  color: selected ? AppColors.brownDeep : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tabs[i],
                  style: AppTextStyles.roleTitle.copyWith(
                    color: selected
                        ? AppColors.cream
                        : AppColors.brownMuted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabIndex) {
      case 0:
        return _buildReservationsTab();
      case 1:
        return _buildQueueTab();
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
        final todayReservations = reservations.where((r) =>
            r.dateTime.year == now.year &&
            r.dateTime.month == now.month &&
            r.dateTime.day == now.day);

        return StreamBuilder<List<QueueEntry>>(
          stream: _queueService.activeQueueStream(_restaurantId),
          builder: (context, queueSnap) {
            final queue = queueSnap.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("TODAY'S OVERVIEW",
                      style: AppTextStyles.roleTitle.copyWith(
                        fontSize: 13,
                        letterSpacing: 1.2,
                      )),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _overviewCard(
                          label: 'Reservations',
                          value: '${todayReservations.length}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _overviewCard(
                          label: 'In Queue',
                          value: '${queue.length}',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 26),

                  Text('CURRENT QUEUE',
                      style: AppTextStyles.roleTitle.copyWith(
                        fontSize: 13,
                        letterSpacing: 1.2,
                      )),
                  const SizedBox(height: 12),

                  if (queue.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.people_outline,
                              size: 40, color: AppColors.brownMuted),
                          const SizedBox(height: 8),
                          Text('No one in queue',
                              style: AppTextStyles.subtitle),
                        ],
                      ),
                    )
                  else
                    ...queue.map((q) => QueueTile(
                          entry: q,
                          onRemove: () => _queueService.leaveQueue(
                            restaurantId: _restaurantId,
                            queueId: q.id,
                          ),
                        )),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _overviewCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(value,
              style: AppTextStyles.heading.copyWith(
                fontSize: 30,
                color: AppColors.brownDeep,
              )),
        ],
      ),
    );
  }

  // ─── TAB 2: QUEUE ─────────────────────────────
  Widget _buildQueueTab() {
    return StreamBuilder<List<QueueEntry>>(
      stream: _queueService.activeQueueStream(_restaurantId),
      builder: (context, snap) {
        final queue = snap.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Walk-in Queue',
                  style: AppTextStyles.heading.copyWith(fontSize: 20)),
              const SizedBox(height: 4),
              Text('${queue.length} waiting',
                  style: AppTextStyles.subtitle),
              const SizedBox(height: 20),
              if (queue.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 60),
                    child: Column(
                      children: [
                        Icon(Icons.hourglass_empty,
                            size: 60, color: AppColors.brownMuted),
                        const SizedBox(height: 12),
                        Text('Queue is empty',
                            style: AppTextStyles.subtitle),
                      ],
                    ),
                  ),
                )
              else
                ...queue.map((q) => QueueTile(
                      entry: q,
                      onRemove: () => _queueService.leaveQueue(
                        restaurantId: _restaurantId,
                        queueId: q.id,
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 3: TABLES ────────────────────────────
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TABLE STATUS',
              style: AppTextStyles.roleTitle.copyWith(
                fontSize: 13,
                letterSpacing: 1.2,
              )),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tables.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
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

  void _showTableActions(TableStatus table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${table.id} — ${table.seats} seats',
                style: AppTextStyles.heading.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text('Current: ${table.status}',
                style: AppTextStyles.subtitle),
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
    );
  }

  Widget _tableAction(
      String label, String status, Color color, TableStatus table) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () async {
          await _tableService.updateStatus(table.id, status);
          if (mounted) Navigator.pop(context);
        },
        leading: Icon(Icons.circle, color: color, size: 14),
        title: Text(label, style: AppTextStyles.roleTitle),
        tileColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reports',
                  style: AppTextStyles.heading.copyWith(fontSize: 20)),
              const SizedBox(height: 4),
              Text('All-time reservation statistics',
                  style: AppTextStyles.subtitle),
              const SizedBox(height: 20),

              _reportRow('Total Reservations', '${all.length}'),
              _reportRow('Confirmed', '$confirmed',
                  color: Colors.green),
              _reportRow('Pending', '$pending', color: Colors.orange),
              _reportRow('Completed', '$completed', color: Colors.blue),
              _reportRow('Cancelled', '$cancelled',
                  color: Colors.redAccent),
            ],
          ),
        );
      },
    );
  }

  Widget _reportRow(String label, String value, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppTextStyles.roleTitle),
          ),
          Text(value,
              style: AppTextStyles.heading.copyWith(
                fontSize: 20,
                color: color ?? AppColors.brownDeep,
              )),
        ],
      ),
    );
  }
}