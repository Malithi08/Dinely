import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dining_table.dart';
import '../services/dining_table_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/area_chip.dart';
import '../widgets/availability_bottom_nav.dart';
import '../widgets/dining_table_card.dart';
import 'placeholders/availability_home_placeholder.dart';
import 'placeholders/availability_profile_placeholder.dart';
import 'placeholders/availability_queue_placeholder.dart';
import 'placeholders/availability_reservation_placeholder.dart';
import 'table_ready_screen.dart';

class TableSelectionScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final DiningTable? preselectedTable;

  const TableSelectionScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.preselectedTable,
  });

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  final _service = DiningTableService();
  String _selectedArea = 'All Areas';
  DiningTable? _selectedTable;
  int _navIndex = 1;
  bool _reserving = false;

  static const _areas = ['All Areas', 'Indoor', 'Patio', 'Rooftop'];

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.preselectedTable;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _areaImage(String area) {
    switch (area.toLowerCase()) {
      case 'indoor':
        return 'assets/images/restaurant_indoor.png';
      case 'patio':
        return 'assets/images/restaurant_patio.png';
      case 'rooftop':
        return 'assets/images/restaurant_rooftop.png';
      default:
        return 'assets/images/restaurant_hero.jpg';
    }
  }

  IconData _areaIcon(String area) {
    switch (area.toLowerCase()) {
      case 'indoor':
        return Icons.chair_outlined;
      case 'patio':
        return Icons.deck_outlined;
      case 'rooftop':
        return Icons.roofing_outlined;
      default:
        return Icons.table_restaurant_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<List<DiningTable>>(
        stream: _service.tablesStream(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
            );
          }

          final allTables = snapshot.data ?? [];

          if (_selectedTable != null) {
            final updated = allTables
                .where((t) => t.id == _selectedTable!.id)
                .cast<DiningTable?>()
                .firstWhere((_) => true, orElse: () => null);
            if (updated != null && updated.status != _selectedTable!.status) {
              _selectedTable = updated;
            }
          }

          // Only available tables
          final availableTables =
              allTables.where((t) => t.isAvailable).toList();

          final filtered = _selectedArea == 'All Areas'
              ? availableTables
              : availableTables
                  .where((t) =>
                      t.area.toLowerCase() == _selectedArea.toLowerCase())
                  .toList();

          return Column(
            children: [
              _buildTopBar(),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildFilters(),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No available tables in this area.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.subtitle,
                          ),
                        ),
                      )
                    : ListView(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        children: [
                          ..._buildAreaSections(filtered),
                          if (_selectedTable != null) ...[
                            const SizedBox(height: 8),
                            _buildSelectedBar(context),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: AvailabilityBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => _onNavTap(i),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.restaurantName.toUpperCase(),
            style: AppTextStyles.smallMuted.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick your table',
            style: AppTextStyles.heading.copyWith(fontSize: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _areas.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final area = _areas[i];
          return AreaChip(
            label: area,
            selected: _selectedArea == area,
            onTap: () => setState(() => _selectedArea = area),
          );
        },
      ),
    );
  }

  List<Widget> _buildAreaSections(List<DiningTable> tables) {
    const order = ['indoor', 'patio', 'rooftop'];

    final grouped = <String, List<DiningTable>>{};
    for (final t in tables) {
      grouped.putIfAbsent(t.area.toLowerCase(), () => []).add(t);
    }

    final sections = <Widget>[];
    for (final area in order) {
      if (grouped.containsKey(area)) {
        sections.add(_buildAreaSection(area, grouped[area]!));
      }
    }
    for (final entry in grouped.entries) {
      if (!order.contains(entry.key)) {
        sections.add(_buildAreaSection(entry.key, entry.value));
      }
    }
    return sections;
  }

  Widget _buildAreaSection(String area, List<DiningTable> tables) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _areaIcon(area),
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _capitalize(area),
                style: AppTextStyles.roleTitle.copyWith(fontSize: 15),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${tables.length} Tables',
                  style: AppTextStyles.smallMuted.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 16 / 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _areaImage(area),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.7),
                            AppColors.primary.withOpacity(0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Text(
                      '${_capitalize(area)} seating',
                      style: AppTextStyles.roleTitle.copyWith(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tables.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (_, i) {
              final t = tables[i];
              return DiningTableCard(
                table: t,
                selected: _selectedTable?.id == t.id,
                onTap: () => setState(() => _selectedTable = t),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBar(BuildContext context) {
    final t = _selectedTable!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.cream, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SELECTED TABLE',
                  style: AppTextStyles.smallMuted.copyWith(
                    color: AppColors.cream.withOpacity(0.7),
                    fontSize: 9.5,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.tableNumber} · ${t.seats} Seats · ${_capitalize(t.area)}',
                  style: AppTextStyles.roleTitle.copyWith(
                    color: AppColors.cream,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _reserving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.cream,
                  ),
                )
              : ElevatedButton(
                  onPressed: _reserve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cream,
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _reserve() async {
    final t = _selectedTable;
    if (t == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again')),
      );
      return;
    }

    setState(() => _reserving = true);

    final error = await _service.reserveTable(
      restaurantId: widget.restaurantId,
      tableId: t.id,
      customerId: uid,
    );

    if (!mounted) return;
    setState(() => _reserving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TableReadyScreen(
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
          table: t,
        ),
      ),
    );
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AvailabilityQueuePlaceholderScreen(),
          ),
        );
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
}