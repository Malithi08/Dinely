import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dining_table.dart';
import '../services/dining_table_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/area_chip.dart';
import '../widgets/availability_bottom_nav.dart';
import '../widgets/dining_table_card.dart';
import 'table_selection_screen.dart';

class TableAvailabilityScreen extends StatefulWidget {
  final String restaurantId;
  final String? restaurantName;

  const TableAvailabilityScreen({
    super.key,
    required this.restaurantId,
    this.restaurantName,
  });

  @override
  State<TableAvailabilityScreen> createState() =>
      _TableAvailabilityScreenState();
}

class _TableAvailabilityScreenState extends State<TableAvailabilityScreen> {
  final _service = DiningTableService();
  String _selectedArea = 'All Areas';
  int _navIndex = 1;

  // filters
  int _guests = 4;
  TimeOfDay _timeOfDay = const TimeOfDay(hour: 19, minute: 0);
  DateTime _selectedDate = DateTime.now();

  String _restaurantName = '';

  static const _areas = ['All Areas', 'Indoor', 'Patio', 'Rooftop'];

  @override
  void initState() {
    super.initState();
    _loadRestaurantName();
  }

  Future<void> _loadRestaurantName() async {
    if (widget.restaurantName != null && widget.restaurantName!.isNotEmpty) {
      setState(() => _restaurantName = widget.restaurantName!);
      return;
    }
    final name = await _service.getRestaurantName(widget.restaurantId);
    if (mounted) setState(() => _restaurantName = name);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String get _dateLabel => DateFormat('EEE, d MMM').format(_selectedDate);
  String get _timeLabel => _timeOfDay.format(context);

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

  String _areaBannerLabel(String area) {
    switch (area.toLowerCase()) {
      case 'indoor':
        return 'Dining Room Main Floor';
      case 'patio':
        return 'Garden Terrace & Pergola';
      case 'rooftop':
        return 'Skyline Lounge View';
      default:
        return _capitalize(area);
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
            Text('Table Availability'),
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

          // Filter: match area + enough seats for the party size
          final filtered = allTables.where((t) {
            final matchesArea = _selectedArea == 'All Areas' ||
                t.area.toLowerCase() == _selectedArea.toLowerCase();
            final fitsGuests = t.seats >= _guests;
            return matchesArea && fitsGuests;
          }).toList();

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildHero(),
              const SizedBox(height: 16),
              _buildFilterBar(),
              const SizedBox(height: 20),
              _buildAvailableHeader(filtered.length),
              const SizedBox(height: 12),
              _buildAreaChips(),
              const SizedBox(height: 12),
              if (allTables.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No tables added yet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No tables match your filters.\nTry a different area or fewer guests.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subtitle,
                  ),
                )
              else
                ..._buildAreaSections(filtered),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
      bottomNavigationBar: AvailabilityBottomNav(
        currentIndex: _navIndex,
        restaurantId: widget.restaurantId,
        restaurantName: _restaurantName,
        navigate: true,
        onTap: (i) {
          if (i == _navIndex) return;
          setState(() => _navIndex = i);
        },
      ),
    );
  }

  // ─── Hero ────────────────────────────────────
  Widget _buildHero() {
    return SizedBox(
      height: 190,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/restaurant_hero.jpg',
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.15),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _restaurantName,
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.cream,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find your perfect table.',
                  style: AppTextStyles.subtitle.copyWith(
                    color: AppColors.cream.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter bar ─────────────────────────────
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            _filterCell(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _dateLabel,
              onTap: _pickDate,
            ),
            const _VDivider(),
            _filterCell(
              icon: Icons.access_time,
              label: 'Time',
              value: _timeLabel,
              onTap: _pickTime,
            ),
            const _VDivider(),
            _filterCell(
              icon: Icons.person_outline,
              label: 'Guests',
              value: '$_guests',
              onTap: _pickGuests,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterCell({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTextStyles.smallMuted.copyWith(fontSize: 9.5),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTextStyles.roleTitle.copyWith(fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down,
                        size: 14, color: AppColors.brownMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.cream,
              onSurface: AppColors.brownDeep,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeOfDay,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.cream,
              onSurface: AppColors.brownDeep,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _timeOfDay = picked);
  }

  Future<void> _pickGuests() async {
    final picked = await showModalBottomSheet<int>(
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
              Text('Number of Guests',
                  style: AppTextStyles.roleTitle.copyWith(fontSize: 15)),
              const SizedBox(height: 8),
              ...List.generate(6, (i) {
                final n = i + 1;
                final selected = n == _guests;
                return ListTile(
                  title: Text(
                    '$n ${n == 1 ? "Guest" : "Guests"}',
                    style: AppTextStyles.inputText.copyWith(
                      color: selected
                          ? AppColors.primary
                          : AppColors.brownDeep,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, n),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) setState(() => _guests = picked);
  }

  // ─── "Available Tables" header ──────────────
  Widget _buildAvailableHeader(int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tables',
                style: AppTextStyles.heading.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 2),
              Text(
                'Choose from indoor, patio or rooftop seating',
                style: AppTextStyles.smallMuted,
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$total',
              style: AppTextStyles.roleTitle.copyWith(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaChips() {
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

  // ─── FIXED ORDER: indoor → patio → rooftop ───
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
    // Any unexpected areas at the end
    for (final entry in grouped.entries) {
      if (!order.contains(entry.key)) {
        sections.add(_buildAreaSection(entry.key, entry.value));
      }
    }
    return sections;
  }

  Widget _buildAreaSection(String area, List<DiningTable> tables) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_areaIcon(area), size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                _capitalize(area),
                style: AppTextStyles.roleTitle.copyWith(fontSize: 15),
              ),
              const Spacer(),
              Text(
                '${tables.length} Tables',
                style: AppTextStyles.smallMuted,
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                      alignment: Alignment.center,
                      child: Icon(
                        _areaIcon(area),
                        size: 32,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Text(
                      _areaBannerLabel(area),
                      style: AppTextStyles.roleTitle.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                onTap: () => _onSelectTable(t),
              );
            },
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  void _onSelectTable(DiningTable table) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TableSelectionScreen(
          restaurantId: widget.restaurantId,
          restaurantName: _restaurantName,
          preselectedTable: table,
        ),
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  const _VDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.divider,
    );
  }
}