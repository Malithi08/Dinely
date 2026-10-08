import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../services/manager_restaurant_service.dart';
import 'manager_overview_screen.dart';
import 'manager_tables_screen.dart';
import 'manager_queue_screen.dart';
import 'manager_reservations_screen.dart';
import 'manager_walkins_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  int _currentIndex = 0;
  final ManagerRestaurantService _restaurantService = ManagerRestaurantService();

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
      if (profile != null) {
        String tempRestId = profile['restaurantId'] ?? 'rest_001';
        String tempRestName = profile['restaurantName'] ?? 'Dinely Restaurant';
        
        try {
          final rDoc = await FirebaseFirestore.instance.collection('restaurants').doc(tempRestId).get();
          if (rDoc.exists && rDoc.data() != null) {
            final rData = rDoc.data()!;
            if (rData['name'] != null && rData['name'].toString().isNotEmpty) tempRestName = rData['name'].toString();
            else if (rData['restaurantName'] != null && rData['restaurantName'].toString().isNotEmpty) tempRestName = rData['restaurantName'].toString();
            else if (rData['restaurant_name'] != null && rData['restaurant_name'].toString().isNotEmpty) tempRestName = rData['restaurant_name'].toString();
            else if (rData['title'] != null && rData['title'].toString().isNotEmpty) tempRestName = rData['title'].toString();
          }
        } catch (_) {}

        if (mounted) {
          setState(() {
            _managerName = profile['name'] ?? 'Manager';
            _restaurantName = tempRestName;
            _restaurantId = tempRestId;
            _isLoading = false;
          });
        }
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
    String nextTableNum = 'T${(existingCount + 1).toString().padLeft(2, '0')}';
    int capacity = 4;
    String selectedZone = 'Indoor';

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
                        Text('Add New Table', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(stCtx)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text('Table Number:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: 'e.g. $nextTableNum',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) nextTableNum = val.trim();
                      },
                    ),
                    const SizedBox(height: 12),

                    Text('Seating Capacity:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [2, 4, 6, 8].map((cap) {
                        final isSel = capacity == cap;
                        return ChoiceChip(
                          label: Text('$cap seats'),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.brownDeep, fontWeight: FontWeight.bold),
                          onSelected: (val) {
                            if (val) setModalState(() => capacity = cap);
                          },
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
                      items: ['Indoor', 'Patio', 'Rooftop'].map((zn) {
                        return DropdownMenuItem(value: zn, child: Text(zn));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedZone = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    const SizedBox(height: 12),

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
                            seats: capacity,
                            area: selectedZone,
                          );

                          if (!mounted) return;
                          Navigator.pop(stCtx);
                          setState(() => _currentIndex = 1);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Table $nextTableNum added to $selectedZone!'),
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

  void _showAddWalkinModal() {
    String guestName = '';
    String phone = '';
    String email = '';
    int partySize = 2;
    String tableSelection = 'auto';
    String seatingPreference = 'Indoor';
    
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
                        Text('Add Walk-in', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(stCtx)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text('Guest Name:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    TextField(
                      onChanged: (val) => guestName = val.trim(),
                      decoration: InputDecoration(
                        hintText: 'e.g. John Doe',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text('Phone Number:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.phone,
                      onChanged: (val) => phone = val.trim(),
                      decoration: InputDecoration(
                        hintText: 'e.g. 0771234567',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text('Email Address:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (val) => email = val.trim(),
                      decoration: InputDecoration(
                        hintText: 'e.g. guest@example.com',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text('Party Size:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [2, 3, 4, 5, 6, 8, 10].map((cap) {
                        final isSel = partySize == cap;
                        return ChoiceChip(
                          label: Text('$cap'),
                          selected: isSel,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.brownDeep, fontWeight: FontWeight.bold),
                          onSelected: (val) {
                            if (val) setModalState(() => partySize = cap);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    Text('Seating Preference:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: seatingPreference,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['Indoor', 'Patio', 'Rooftop'].map((zn) {
                        return DropdownMenuItem(value: zn, child: Text(zn));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => seatingPreference = val);
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (guestName.isEmpty) return;
                          
                          final now = DateTime.now();
                          final minutes = now.minute.toString().padLeft(2, '0');
                          final hour12 = now.hour == 0 ? 12 : (now.hour > 12 ? now.hour - 12 : now.hour);
                          final amPm = now.hour >= 12 ? 'PM' : 'AM';
                          final formattedTime = "$hour12:$minutes $amPm";
                          final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          final formattedDate = "${now.day} ${months[now.month - 1]} ${now.year}";
                          
                          final randomNum = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
                          
                          await _restaurantService.addWalkin({
                            'customerName': guestName,
                            'phoneNumber': phone,
                            'email': email.isEmpty ? 'N/A' : email,
                            'guests': partySize,
                            'restaurantId': _restaurantId,
                            'restaurantName': _restaurantName,
                            'restaurantImage': '',
                            'seatingPreference': seatingPreference,
                            'status': 'confirmed',
                            'tableId': tableSelection,
                            'time': formattedTime,
                            'date': formattedDate,
                            'walkinCode': '#WLK$randomNum',
                          });

                          if (!mounted) return;
                          Navigator.pop(stCtx);
                          setState(() => _currentIndex = 4); // Navigate to walkins tab

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Walk-in Added Successfully!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text('Confirm Walk-in', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
            Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
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
    bool isEditing = false;
    String currentStatus = table['status'] ?? 'Available';
    if (!['Available', 'Occupied', 'Reserved', 'Cleaning'].contains(currentStatus)) {
      currentStatus = 'Available';
    }
    int currentCapacity = table['seats'] ?? 4;
    String currentZone = table['area'] ?? 'Indoor';
    if (!['Indoor', 'Patio', 'Rooftop'].any((z) => z.toLowerCase() == currentZone.toLowerCase())) {
      currentZone = 'Indoor';
    } else {
      currentZone = ['Indoor', 'Patio', 'Rooftop'].firstWhere((z) => z.toLowerCase() == currentZone.toLowerCase());
    }
    
    final String tableId = table['id'];
    String tableNumber = table['tableNumber'] ?? tableId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
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
              child: !isEditing
                  // DETAILS VIEW
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Table $tableNumber', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                                Text('$currentZone • Cap: $currentCapacity guests', style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 13)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(currentStatus).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                currentStatus,
                                style: GoogleFonts.poppins(color: _getStatusColor(currentStatus), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                            label: Text('Update Table', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            onPressed: () {
                              setModalState(() {
                                isEditing = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                context: stCtx,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  title: Text('Delete Table', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                                  content: Text('Are you sure you want to delete Table $tableNumber?', style: GoogleFonts.poppins(fontSize: 13)),
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
                                await _restaurantService.deleteTable(_restaurantId, tableId);
                                if (!mounted) return;
                                Navigator.pop(stCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Table $tableNumber deleted successfully'), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    )
                  // EDIT FORM VIEW
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Edit Table $tableNumber', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                            IconButton(
                              icon: const Icon(Icons.close), 
                              onPressed: () {
                                setModalState(() {
                                  isEditing = false; // Cancel edit and return to details
                                });
                              }
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Text('Status:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: currentStatus,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            prefixIcon: Icon(Icons.info_outline, color: _getStatusColor(currentStatus), size: 20),
                          ),
                          items: ['Available', 'Occupied', 'Reserved', 'Cleaning'].map((st) {
                            return DropdownMenuItem(
                              value: st, 
                              child: Text(st, style: GoogleFonts.poppins(color: _getStatusColor(st), fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => currentStatus = val);
                          },
                        ),
                        const SizedBox(height: 16),

                        Text('Seating Capacity:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [2, 4, 6, 8, 10, 12].map((cap) {
                            final isSel = currentCapacity == cap;
                            return ChoiceChip(
                              label: Text('$cap seats'),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.brownDeep, fontWeight: FontWeight.bold),
                              onSelected: (val) {
                                if (val) setModalState(() => currentCapacity = cap);
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),

                        Text('Dining Zone:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                        const SizedBox(height: 4),
                        DropdownButtonFormField<String>(
                          value: currentZone,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: ['Indoor', 'Patio', 'Rooftop'].map((zn) {
                            return DropdownMenuItem(value: zn, child: Text(zn));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => currentZone = val);
                          },
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              await _restaurantService.updateTable(
                                restaurantId: _restaurantId,
                                tableDocId: tableId,
                                seats: currentCapacity,
                                area: currentZone,
                                status: currentStatus,
                              );

                              if (!mounted) return;
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Table $tableNumber updated successfully'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              
                              setModalState(() {
                                isEditing = false;
                              });
                            },
                            child: Text('Save Changes', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
            ),
          );
        },
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
                  style: GoogleFonts.poppins(
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
                    } else if (action == 'Add Walk-in Guest') {
                      _showAddWalkinModal();
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
                ManagerWalkinsScreen(
                  restaurantId: _restaurantId,
                  onAddWalkin: _showAddWalkinModal,
                ),
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
              icon: Icon(Icons.directions_walk_rounded),
              label: 'Walk-Ins',
            ),
          ],
        ),
      ),
    );
  }
}
