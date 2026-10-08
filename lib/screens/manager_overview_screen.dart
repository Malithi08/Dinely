import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/manager_restaurant_service.dart';

class ManagerOverviewScreen extends StatelessWidget {
  final String managerName;
  final String restaurantId;
  final Function(int) onNavigateToTab;
  final Function(String) onQuickAction;

  const ManagerOverviewScreen({
    super.key,
    required this.managerName,
    required this.restaurantId,
    required this.onNavigateToTab,
    required this.onQuickAction,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available':
        return const Color(0xFF2E6F40);
      case 'Occupied':
        return AppColors.primary;
      case 'Reserved':
        return const Color(0xFFC86D22);
      case 'Cleaning':
        return const Color(0xFF8C7A6B);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantService = ManagerRestaurantService();
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: restaurantService.streamTables(restaurantId),
      builder: (context, tablesSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: restaurantService.streamWalkins(restaurantId),
          builder: (context, walkinsSnapshot) {
            final tables = tablesSnapshot.data ?? [];
            final walkins = walkinsSnapshot.data ?? [];
                
                final totalTables = tables.length;
                final walkinsWaitCount = walkins.where((w) {
                  final st = (w['status'] ?? '').toString().toUpperCase();
                  return !['SEATED', 'CANCELLED'].contains(st) && !st.contains('NO SHOW') && !st.contains('CANCEL');
                }).length;

                final availCount = tables.where((t) => t['status'] == 'Available').length;
            final occCount = tables.where((t) => t['status'] == 'Occupied').length;
            final rsrvCount = tables.where((t) => t['status'] == 'Reserved').length;
            final cleanCount = tables.where((t) => t['status'] == 'Cleaning').length;

            final occupancyPct = totalTables > 0 ? (((occCount + rsrvCount) / totalTables) * 100).round() : 0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.brownWarm],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()}, $managerName',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Quick Action Bar
                  Text('Quick Actions', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.table_restaurant_rounded,
                        label: '+ Add Table',
                        color: AppColors.primary,
                        onTap: () => onQuickAction('Add Table'),
                      ),

                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'Add Walk-in',
                        color: const Color(0xFF059669),
                        onTap: () => onQuickAction('Add Walk-in Guest'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Performance Metrics
                  Text("Today's Performance", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.calendar_month_outlined,
                          badgeText: 'Live',
                          badgeColor: const Color(0xFFDCFCE7),
                          badgeTextColor: const Color(0xFF15803D),
                          value: '$rsrvCount',
                          title: 'Reservations',
                          subtitle: '$rsrvCount reserved table${rsrvCount == 1 ? '' : 's'}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.table_bar_outlined,
                          badgeText: 'Live',
                          badgeColor: const Color(0xFFDCFCE7),
                          badgeTextColor: const Color(0xFF15803D),
                          value: '$availCount',
                          title: 'Available',
                          subtitle: 'Ready to seat',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.pie_chart_outline_rounded,
                          badgeText: '$occupancyPct%',
                          badgeColor: const Color(0xFFDBEAFE),
                          badgeTextColor: const Color(0xFF1D4ED8),
                          value: '${occCount + rsrvCount}/$totalTables',
                          title: 'Occupancy',
                          subtitle: 'Tables in use',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.directions_walk_rounded,
                          badgeText: 'Live',
                          badgeColor: const Color(0xFFE0E7FF),
                          badgeTextColor: const Color(0xFF4338CA),
                          value: '$walkinsWaitCount',
                          title: 'Walk-ins',
                          subtitle: 'Waiting for table',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Table Summary Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Table Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                      GestureDetector(
                        onTap: () => onNavigateToTab(1),
                        child: Text('View Grid →', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brownWarm)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 12,
                            child: Row(
                              children: [
                                Expanded(flex: availCount > 0 ? availCount : 1, child: Container(color: _getStatusColor('Available'))),
                                const SizedBox(width: 2),
                                Expanded(flex: occCount > 0 ? occCount : 1, child: Container(color: _getStatusColor('Occupied'))),
                                const SizedBox(width: 2),
                                Expanded(flex: rsrvCount > 0 ? rsrvCount : 1, child: Container(color: _getStatusColor('Reserved'))),
                                const SizedBox(width: 2),
                                Expanded(flex: cleanCount > 0 ? cleanCount : 1, child: Container(color: _getStatusColor('Cleaning'))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _buildPillSummary('Available', '$availCount', _getStatusColor('Available')),
                            _buildPillSummary('Occupied', '$occCount', _getStatusColor('Occupied')),
                            _buildPillSummary('Reserved', '$rsrvCount', _getStatusColor('Reserved')),
                            _buildPillSummary('Cleaning', '$cleanCount', _getStatusColor('Cleaning')),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Operations Log
                  Text('Recent Operations', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8)],
                    ),
                    child: Column(
                      children: [
                        _buildActivityTile(
                          icon: Icons.table_bar_outlined,
                          title: 'Table Status Synced',
                          subtitle: '$occCount occupied tables right now',
                          time: 'Live',
                          color: AppColors.brownWarm,
                          showDivider: true,
                        ),

                        _buildActivityTile(
                          icon: Icons.cleaning_services_outlined,
                          title: 'Available Tables',
                          subtitle: '$availCount tables open',
                          time: 'Live',
                          color: const Color(0xFF2E7D32),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
              },
            );
          },
        );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.brownDeep),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                child: Text(badgeText, style: GoogleFonts.poppins(color: badgeTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.brownDeep)),
          Text(title, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
          Text(subtitle, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.brownMuted)),
        ],
      ),
    );
  }

  Widget _buildPillSummary(String label, String count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(count, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.brownMuted, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
    required bool showDivider,
  }) {
    return Column(
      children: [
        ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brownDeep)),
          subtitle: Text(subtitle, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.brownMuted)),
          trailing: Text(time, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.brownMuted)),
        ),
        if (showDivider) const Divider(height: 1, indent: 64),
      ],
    );
  }
}
