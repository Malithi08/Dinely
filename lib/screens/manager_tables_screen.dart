import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/restaurant_service.dart';

class ManagerTablesScreen extends StatefulWidget {
  final String restaurantId;
  final Function(Map<String, dynamic>) onShowDetails;
  final Function() onAddTable;

  const ManagerTablesScreen({
    super.key,
    required this.restaurantId,
    required this.onShowDetails,
    required this.onAddTable,
  });

  @override
  State<ManagerTablesScreen> createState() => _ManagerTablesScreenState();
}

class _ManagerTablesScreenState extends State<ManagerTablesScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  String _selectedZoneFilter = 'All';

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
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildActionButtonByStatus(String status, Map<String, dynamic> table, String zone) {
    switch (status) {
      case 'Available':
        return _buildCardButton(
          label: 'Seat Walk-in',
          icon: Icons.person_add_alt_1_outlined,
          isDark: true,
          onPressed: () => widget.onShowDetails(table),
        );
      case 'Occupied':
        return _buildCardButton(
          label: 'View Order',
          icon: Icons.receipt_long_outlined,
          isDark: false,
          onPressed: () => widget.onShowDetails(table),
        );
      case 'Reserved':
        return _buildCardButton(
          label: 'Check In',
          icon: Icons.meeting_room_outlined,
          isDark: false,
          onPressed: () => widget.onShowDetails(table),
        );
      case 'Cleaning':
      default:
        return _buildCardButton(
          label: 'Mark Ready',
          icon: Icons.cleaning_services_outlined,
          isDark: false,
          onPressed: () => widget.onShowDetails(table),
        );
    }
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
        onTap: () => widget.onShowDetails(table),
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
              // Top Section: Image Banner
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

              // Bottom Section
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _restaurantService.streamTables(widget.restaurantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final allTables = snapshot.data ?? [];
        final filteredTables = _selectedZoneFilter == 'All'
            ? allTables
            : allTables.where((t) => (t['zone'] as String? ?? '').toLowerCase().contains(_selectedZoneFilter.toLowerCase())).toList();

        final zones = ['All', 'Main Hall', 'Patio', 'VIP Lounge'];

        return Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Floor Layout', style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF2A1810))),
                      Text('${allTables.length} total tables across zones', style: GoogleFonts.poppins(color: const Color(0xFF8C7A6B), fontSize: 12)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: widget.onAddTable,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A2810),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: Text('Add Table', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            // Zone Selector Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: zones.map((zn) {
                  final isSel = _selectedZoneFilter == zn;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(zn),
                      selected: isSel,
                      selectedColor: const Color(0xFFFBF0D2),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSel ? const Color(0xFF8C5A2B) : Colors.transparent),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedZoneFilter = zn);
                      },
                      labelStyle: GoogleFonts.poppins(
                        color: isSel ? const Color(0xFF2A1810) : const Color(0xFF8C7A6B),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  );
                }).toList(),
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
}
