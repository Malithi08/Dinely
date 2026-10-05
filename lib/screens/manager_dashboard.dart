import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/restaurant_service.dart';
import 'manager_login.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _currentIndex = 0;
  String _managerName = 'Manager';
  String _restaurantName = 'Dinely Operations';
  String _restaurantId = 'dinely_default_res';
  bool _isLoading = true;

  final RestaurantService _restaurantService = RestaurantService();

  // Table filter state
  String _selectedTableFilter = 'All';
  String _selectedZoneFilter = 'All Zones';

  @override
  void initState() {
    super.initState();
    _loadManagerProfile();
  }

  Future<void> _loadManagerProfile() async {
    final profile = await AuthService().getUserProfile();
    if (mounted && profile != null) {
      final resId = profile['restaurantId'] ?? 'dinely_default_res';
      setState(() {
        _managerName = profile['name'] ?? 'Manager';
        _restaurantName = profile['restaurantName'] ?? resId;
        _restaurantId = resId;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out', style: GoogleFonts.playfairDisplay(color: AppColors.brownDeep, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to exit Manager Operations?', style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.brownMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerLoginScreen()),
      );
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return const Color(0xFF2E6F40); // Deep Warm Forest Green
      case 'Occupied': return AppColors.primary;       // Deep Espresso Primary
      case 'Reserved': return const Color(0xFFC86D22); // Warm Terracotta Amber
      case 'Cleaning': return const Color(0xFF8C7A6B); // Muted Warm Taupe
      default: return AppColors.primary;
    }
  }

  // Add Reservation or Waitlist Modal Bottom Sheet (Connected to Firestore)
  void _showQuickActionModal(String actionType) {
    final nameCtrl = TextEditingController();
    final partyCtrl = TextEditingController(text: '2');
    final phoneCtrl = TextEditingController();
    final quotedCtrl = TextEditingController(text: '15m');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(actionType, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Guest Name',
                hintText: 'Enter guest name',
                prefixIcon: const Icon(Icons.person_outline, color: AppColors.brownMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: partyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Party Size',
                      hintText: 'e.g. 4',
                      prefixIcon: const Icon(Icons.groups_outlined, color: AppColors.brownMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      hintText: 'e.g. +1 555 019',
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.brownMuted),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final party = int.tryParse(partyCtrl.text.trim()) ?? 2;
                  final phone = phoneCtrl.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter guest name')),
                    );
                    return;
                  }

                  if (actionType.contains('Reservation')) {
                    await _restaurantService.addReservation(
                      restaurantId: _restaurantId,
                      name: name,
                      partySize: party,
                      phone: phone,
                    );
                  } else {
                    await _restaurantService.addQueueGuest(
                      restaurantId: _restaurantId,
                      name: name,
                      partySize: party,
                      phone: phone,
                      quotedTime: quotedCtrl.text.trim(),
                    );
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$actionType saved to Database!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text('Save to Firestore', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add New Table Modal (Connected to Firestore)
  void _showAddTableModal(int nextTableNumber) {
    final tableNumCtrl = TextEditingController(text: '$nextTableNumber');
    final capacityCtrl = TextEditingController(text: '4');
    String selectedZone = 'Main Hall';
    final serverCtrl = TextEditingController(text: 'Marco D.');

    final dashboardContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add New Table',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tableNumCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Table Number',
                        hintText: 'e.g. 16',
                        prefixIcon: const Icon(Icons.table_restaurant_outlined, color: AppColors.brownMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Seating Capacity',
                        hintText: 'e.g. 4',
                        prefixIcon: const Icon(Icons.groups_outlined, color: AppColors.brownMuted),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedZone,
                decoration: InputDecoration(
                  labelText: 'Floor Zone',
                  prefixIcon: const Icon(Icons.map_outlined, color: AppColors.brownMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Main Hall', 'Patio', 'VIP Lounge'].map((zn) {
                  return DropdownMenuItem(value: zn, child: Text(zn, style: GoogleFonts.poppins()));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedZone = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: serverCtrl,
                decoration: InputDecoration(
                  labelText: 'Assigned Server (Optional)',
                  hintText: 'e.g. Marco D.',
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.brownMuted),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final tNum = int.tryParse(tableNumCtrl.text.trim());
                    final cap = int.tryParse(capacityCtrl.text.trim()) ?? 4;
                    final server = serverCtrl.text.trim();

                    if (tNum == null || tNum <= 0) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid table number')),
                      );
                      return;
                    }

                    try {
                      await _restaurantService.addTable(
                        restaurantId: _restaurantId,
                        tableNumber: tNum,
                        capacity: cap,
                        zone: selectedZone,
                        assignedServer: server.isNotEmpty ? server : 'Unassigned',
                      );

                      if (!sheetContext.mounted) return;
                      Navigator.pop(sheetContext);

                      if (!mounted) return;
                      setState(() => _currentIndex = 1);

                      ScaffoldMessenger.of(dashboardContext).showSnackBar(
                        SnackBar(
                          content: Text('Table T${tNum < 10 ? '0$tNum' : tNum} added successfully! Navigated to Tables view.'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      if (!sheetContext.mounted) return;
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        SnackBar(
                          content: Text('Error adding table: $e'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Text('Add Table', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Table Action Modal (Real-time update to Firestore)
  void _showTableDetailsModal(Map<String, dynamic> table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Table ${table['id']}', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                    Text('${table['zone']} • Cap: ${table['capacity']} guests', style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 13)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(table['status']).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    table['status'],
                    style: GoogleFonts.poppins(color: _getStatusColor(table['status']), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Update Table Status (Live DB):', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Available', 'Occupied', 'Reserved', 'Cleaning'].map((st) {
                final isCurrent = table['status'] == st;
                return ChoiceChip(
                  label: Text(st),
                  selected: isCurrent,
                  selectedColor: _getStatusColor(st),
                  labelStyle: TextStyle(color: isCurrent ? Colors.white : AppColors.brownDeep, fontWeight: FontWeight.w600),
                  onSelected: (selected) async {
                    if (selected) {
                      await _restaurantService.updateTableStatus(_restaurantId, table['id'], st);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Table ${table['id']} updated to $st in Database!'), behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text('Delete Table', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Delete Table', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                      content: Text('Are you sure you want to delete Table ${table['number']}?', style: GoogleFonts.poppins(fontSize: 13)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.brownMuted)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await _restaurantService.deleteTable(table['id']);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Table ${table['number']} deleted successfully'), backgroundColor: Colors.redAccent),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5EF),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/dinely_logo.png',
                height: 32,
                width: 32,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dinely',
                  style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _restaurantName,
                  style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 24),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Firestore live updates active'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
            onPressed: _handleSignOut,
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : IndexedStack(
              index: _currentIndex,
              children: [
                _buildOperationsTab(),
                _buildTablesTab(),
                _buildQueueTab(),
                _buildReportsTab(),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: const Color(0xFF9E8E81),
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Overview',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.table_bar_rounded),
              label: 'Tables',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.groups_rounded),
              label: 'Queue',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded),
              label: 'Analytics',
            ),
          ],
        ),
      ),
    );
  }

  // ─── 1. OVERVIEW & OPERATIONS TAB (REAL-TIME FIRESTORE STREAMS) ────────────
  Widget _buildOperationsTab() {
    final now = DateTime.now();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dateStr = '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _restaurantService.streamTables(_restaurantId),
      builder: (context, tablesSnapshot) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _restaurantService.streamQueue(_restaurantId),
          builder: (context, queueSnapshot) {
            final tables = tablesSnapshot.data ?? [];
            final queue = queueSnapshot.data ?? [];

            final totalTables = tables.length;
            final availCount = tables.where((t) => t['status'] == 'Available').length;
            final occCount = tables.where((t) => t['status'] == 'Occupied').length;
            final rsrvCount = tables.where((t) => t['status'] == 'Reserved').length;
            final cleanCount = tables.where((t) => t['status'] == 'Cleaning').length;

            final occupancyPct = totalTables > 0 ? ((occCount / totalTables) * 100).round() : 0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Welcome Card
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
                                '${_getGreeting()}, $_managerName',
                                style: GoogleFonts.playfairDisplay(
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Firestore Sync',
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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
                        onTap: () => _showAddTableModal(16),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Reservation',
                        color: const Color(0xFF2563EB),
                        onTap: () => _showQuickActionModal('Add New Reservation'),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickActionButton(
                        icon: Icons.person_add_alt_1_outlined,
                        label: 'Add Walk-in',
                        color: const Color(0xFF059669),
                        onTap: () => _showQuickActionModal('Add Walk-in Guest'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Live Metrics Cards
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Today's Performance", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                    ],
                  ),
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
                          title: 'Bookings',
                          subtitle: '$rsrvCount reserved table${rsrvCount == 1 ? '' : 's'}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.groups_outlined,
                          badgeText: 'Live',
                          badgeColor: const Color(0xFFFEF3C7),
                          badgeTextColor: const Color(0xFFB45309),
                          value: '${queue.length}',
                          title: 'In Queue',
                          subtitle: 'Waitlist active',
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
                          value: '$occCount/$totalTables',
                          title: 'Occupancy',
                          subtitle: 'Tables in use',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          icon: Icons.table_restaurant,
                          badgeText: 'Free',
                          badgeColor: const Color(0xFFDCFCE7),
                          badgeTextColor: const Color(0xFF15803D),
                          value: '$availCount',
                          title: 'Available',
                          subtitle: 'Ready to seat',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Interactive Table Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Table Summary', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                      GestureDetector(
                        onTap: () => setState(() => _currentIndex = 1),
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

                  // Recent Operations Log
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
                          icon: Icons.person_add_alt_outlined,
                          title: 'Waitlist Stream Active',
                          subtitle: '${queue.length} guests in Firestore queue',
                          time: 'Live',
                          color: const Color(0xFF2563EB),
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

  // ─── 2. TABLES MANAGEMENT TAB (REAL-TIME FIRESTORE STREAM) ─────────────────
  Widget _buildTablesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _restaurantService.streamTables(_restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final tables = snapshot.data ?? [];

        final allCount = tables.length;
        final availCount = tables.where((t) => t['status'] == 'Available').length;
        final occCount = tables.where((t) => t['status'] == 'Occupied').length;
        final rsrvCount = tables.where((t) => t['status'] == 'Reserved').length;

        final filteredTables = tables.where((t) {
          final matchesStatus = _selectedTableFilter == 'All' || t['status'] == _selectedTableFilter;
          final matchesZone = _selectedZoneFilter == 'All Zones' || t['zone'] == _selectedZoneFilter;
          return matchesStatus && matchesZone;
        }).toList();

        final statusFilters = [
          {'key': 'All', 'label': 'All ($allCount)'},
          {'key': 'Available', 'label': 'Available ($availCount)'},
          {'key': 'Occupied', 'label': 'Occupied ($occCount)'},
          {'key': 'Reserved', 'label': 'Reserved ($rsrvCount)'},
        ];

        final zoneFilters = ['All Zones', 'Main Hall', 'Patio', 'VIP Lounge'];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: const Color(0xFFFAF5EF),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Floor Layout',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2A1810),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTableModal(tables.length + 1),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A2810),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: Text(
                      'Add Table',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Status Filter Chips Row with Live Counts
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: const Color(0xFFFAF5EF),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: statusFilters.map((st) {
                    final isSel = _selectedTableFilter == st['key'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedTableFilter = st['key']!),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF4A2810) : const Color(0xFFF5EBE1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            st['label']!,
                            style: GoogleFonts.poppins(
                              color: isSel ? Colors.white : const Color(0xFF4A2810),
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // Zone Filter Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: const Color(0xFFFAF5EF),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: zoneFilters.map((zn) {
                    final isSel = _selectedZoneFilter == zn;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedZoneFilter = zn),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            zn,
                            style: GoogleFonts.poppins(
                              color: isSel ? const Color(0xFF2A1810) : const Color(0xFF8C7A6B),
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Grid View of Tables
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemCount: filteredTables.length,
                itemBuilder: (context, index) {
                  final table = filteredTables[index];
                  return _buildTableCard(table);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatServerName(String server) {
    if (server.isEmpty || server == 'Unassigned') return 'Marco D.';
    final parts = server.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1][0]}.';
    }
    return server;
  }

  String _getTableImagePath(String zone) {
    if (zone.contains('Patio')) {
      return 'assets/images/patio.jpg';
    } else if (zone.contains('VIP') || zone.contains('Wine')) {
      return 'assets/images/vip_lounge.jpg';
    } else {
      return 'assets/images/main_hall.jpg';
    }
  }

  Widget _buildStatusPillOverlay(String status, Map<String, dynamic> table) {
    Color bgColor;
    String text;

    switch (status) {
      case 'Available':
        bgColor = const Color(0xFF1E6838);
        text = 'Ready';
        break;
      case 'Occupied':
        bgColor = const Color(0xFFC84C32);
        text = table['specialTag'] ?? table['course'] ?? 'Occupied';
        break;
      case 'Reserved':
        bgColor = const Color(0xFFB87B2E);
        text = table['reservedTime'] ?? 'Reserved';
        break;
      case 'Cleaning':
      default:
        bgColor = const Color(0xFF555555);
        text = 'Cleaning';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    final status = table['status'] ?? 'Available';
    final tableNum = table['number'] as int? ?? 1;
    final formattedNum = tableNum < 10 ? 'T-0$tableNum' : 'T-$tableNum';
    final capacity = table['capacity'] as int? ?? 4;
    final zone = table['zone'] as String? ?? 'Main Hall';
    final server = (table['server'] != null && table['server'].toString().trim().isNotEmpty)
        ? _formatServerName(table['server'].toString())
        : 'Unassigned';

    String leftRole = 'Server';
    String rightValue = server;
    if (status == 'Reserved') {
      leftRole = 'Guest';
      rightValue = (table['guest'] != null && table['guest'].toString().trim().isNotEmpty)
          ? table['guest'].toString()
          : 'Reserved';
    }

    final imagePath = _getTableImagePath(zone);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTableDetailsModal(table),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Section: Image Banner with badges
              Stack(
                children: [
                  Image.asset(
                    imagePath,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      height: 110,
                      color: const Color(0xFF3E2723),
                      child: const Center(child: Icon(Icons.restaurant, color: Colors.white54, size: 30)),
                    ),
                  ),

                  // Top-Left Table ID & Seats Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$formattedNum  •  $capacity seats',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2A1810),
                        ),
                      ),
                    ),
                  ),

                  // Top-Right Status Badge Pill & Delete Icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusPillOverlay(status, table),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text('Delete Table', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                                content: Text('Are you sure you want to delete Table $tableNum?', style: GoogleFonts.poppins(fontSize: 13)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.brownMuted)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: Text('Delete', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _restaurantService.deleteTable(table['id']);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Table $tableNum deleted'), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delete_outline, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom-Left Overlay Zone Tag
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        zone.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Bottom Section: Server / Guest info & Action Button
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          leftRole,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF8C7A6B),
                          ),
                        ),
                        Text(
                          rightValue,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2A1810),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Action Button
                    _buildActionButtonByStatus(status, table, zone),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtonByStatus(String status, Map<String, dynamic> table, String zone) {
    switch (status) {
      case 'Available':
        return _buildCardButton(
          label: 'Seat Walk-in',
          icon: Icons.person_add_alt_1_outlined,
          isDark: true,
          onPressed: () => _showTableDetailsModal(table),
        );
      case 'Occupied':
        return _buildCardButton(
          label: 'View Order',
          icon: Icons.receipt_long_outlined,
          isDark: false,
          onPressed: () => _showTableDetailsModal(table),
        );
      case 'Reserved':
        return _buildCardButton(
          label: 'Check In',
          icon: Icons.meeting_room_outlined,
          isDark: false,
          onPressed: () => _showTableDetailsModal(table),
        );
      case 'Cleaning':
      default:
        return _buildCardButton(
          label: 'Mark Ready',
          icon: Icons.cleaning_services_outlined,
          isDark: false,
          onPressed: () => _showTableDetailsModal(table),
        );
    }
  }

  Widget _buildCardButton({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 34,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF4A2810) : const Color(0xFFF5EBE1),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: isDark ? Colors.white : const Color(0xFF4A2810)),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isDark ? Colors.white : const Color(0xFF4A2810),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 3. QUEUE MANAGEMENT TAB (REAL-TIME FIRESTORE STREAM) ─────────────────
  Widget _buildQueueTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _restaurantService.streamQueue(_restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final queueItems = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Waitlist Queue', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                    Text('${queueItems.length} groups currently waiting', style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showQuickActionModal('Add Waitlist Guest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: Text('Add Guest', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (queueItems.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('No guests currently in waitlist queue', style: GoogleFonts.poppins(color: AppColors.brownMuted)),
                ),
              )
            else
              ...queueItems.map((item) => _buildQueueCard(item)),
          ],
        );
      },
    );
  }

  Widget _buildQueueCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                item['qId'] ?? 'Q-00',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? 'Guest',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.brownDeep),
                  ),
                  Text(
                    'Party of ${item['party']} • Quoted: ${item['quoted']}',
                    style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _restaurantService.updateQueueStatus(_restaurantId, item['docId'], 'Seated');
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item['name']} seated and removed from waitlist!'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brownWarm,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  ),
                  child: Text('Seat Now', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text(
                  item['status'] ?? 'Waiting',
                  style: GoogleFonts.poppins(fontSize: 10, color: AppColors.brownMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. ANALYTICS & REPORTS TAB ─────────────────────────────────────────────
  Widget _buildReportsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      children: [
        Text('Daily Analytics & Performance', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
        Text('Real-time insights and revenue overview', style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 12)),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hourly Occupancy Rate (%)', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.brownDeep)),
              const SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    _BarItem('12 PM', 0.45),
                    _BarItem('2 PM', 0.65),
                    _BarItem('4 PM', 0.30),
                    _BarItem('6 PM', 0.85),
                    _BarItem('8 PM', 0.95),
                    _BarItem('10 PM', 0.50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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

class _BarItem extends StatelessWidget {
  final String label;
  final double heightPct;
  const _BarItem(this.label, this.heightPct);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 20,
          height: 110 * heightPct,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.brownMuted)),
      ],
    );
  }
}
