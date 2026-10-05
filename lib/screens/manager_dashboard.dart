import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/restaurant_service.dart';
import 'manager_overview_screen.dart';
import 'manager_tables_screen.dart';
import 'manager_queue_screen.dart';
import 'manager_reservations_screen.dart';
import 'manager_analytics_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _currentIndex = 0;
  final RestaurantService _restaurantService = RestaurantService();

  String _managerName = 'Manager';
  String _restaurantName = 'Dinely Restaurant';
  String _restaurantId = 'rest_001';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadManagerProfile();
  }

  Future<void> _loadManagerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _restaurantService.getManagerProfile(user.uid);
      if (profile != null && mounted) {
        setState(() {
          _managerName = profile['name'] ?? 'Manager';
          _restaurantName = profile['restaurantName'] ?? 'Dinely Restaurant';
          _restaurantId = profile['restaurantId'] ?? 'rest_001';
          _isLoading = false;
        });
        return;
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
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

  void _showAddTableModal(int existingCount) {
    int nextTableNum = existingCount + 1;
    int capacity = 4;
    String selectedZone = 'Main Hall';
    final serverController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(stCtx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Add New Table', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(stCtx)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text('Table Number:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '$nextTableNum',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        if (parsed != null) nextTableNum = parsed;
                      },
                    ),
                    const SizedBox(height: 12),

                    Text('Seating Capacity:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    Row(
                      children: [2, 4, 6, 8].map((cap) {
                        final isSel = capacity == cap;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$cap seats'),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.brownDeep, fontWeight: FontWeight.bold),
                            onSelected: (val) {
                              if (val) setModalState(() => capacity = cap);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    Text('Dining Zone:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedZone,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['Main Hall', 'Patio', 'VIP Lounge'].map((zn) {
                        return DropdownMenuItem(value: zn, child: Text(zn));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedZone = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    Text('Assigned Server (Optional):', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: serverController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Marco D.',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await _restaurantService.addTable(
                            restaurantId: _restaurantId,
                            tableNumber: nextTableNum,
                            capacity: capacity,
                            zone: selectedZone,
                            assignedServer: serverController.text.trim().isNotEmpty ? serverController.text.trim() : null,
                          );

                          if (!mounted) return;
                          Navigator.pop(stCtx);
                          setState(() => _currentIndex = 1);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Table T-0$nextTableNum added to $selectedZone!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text('Save & Create Table', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickActionModal(String title) {
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
            Text(title, style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
            const SizedBox(height: 8),
            Text('Feature form ready for operation setup.', style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 13)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  '$_restaurantId',
                  style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () => _showQuickActionModal('Notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : IndexedStack(
              index: _currentIndex,
              children: [
                ManagerOverviewScreen(
                  managerName: _managerName,
                  restaurantId: _restaurantId,
                  onNavigateToTab: (idx) => setState(() => _currentIndex = idx),
                  onQuickAction: (action) {
                    if (action == 'Add Table') {
                      _showAddTableModal(16);
                    } else {
                      _showQuickActionModal(action);
                    }
                  },
                ),
                ManagerTablesScreen(
                  restaurantId: _restaurantId,
                  onShowDetails: _showTableDetailsModal,
                  onAddTable: () => _showAddTableModal(16),
                ),
                ManagerQueueScreen(
                  restaurantId: _restaurantId,
                  onAddGuest: _showQuickActionModal,
                ),
                ManagerReservationsScreen(
                  restaurantId: _restaurantId,
                ),
                const ManagerAnalyticsScreen(),
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
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Reservations',
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
}
