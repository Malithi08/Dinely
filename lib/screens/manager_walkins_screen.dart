import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/restaurant_service.dart';

class ManagerWalkinsScreen extends StatefulWidget {
  final String restaurantId;
  final VoidCallback onAddWalkin;

  const ManagerWalkinsScreen({
    super.key,
    required this.restaurantId,
    required this.onAddWalkin,
  });

  @override
  State<ManagerWalkinsScreen> createState() => _ManagerWalkinsScreenState();
}

class _ManagerWalkinsScreenState extends State<ManagerWalkinsScreen> {
  final RestaurantService _restaurantService = RestaurantService();
  String _selectedFilter = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _getStatusBgColor(String status) {
    final st = status.toUpperCase();
    if (st == 'CONFIRMED') return const Color(0xFFF7EBE1);
    if (st == 'ARRIVED' || st == 'SEATED') return const Color(0xFFE2F0D9);
    if (st == 'PENDING' || st == 'WAITING') return const Color(0xFFFFF3CD);
    if (st.contains('NO SHOW') || st == 'CANCELLED') return const Color(0xFFF8D7DA);
    return const Color(0xFFF7EBE1);
  }

  Color _getStatusTextColor(String status) {
    final st = status.toUpperCase();
    if (st == 'CONFIRMED') return const Color(0xFF8C532B);
    if (st == 'ARRIVED' || st == 'SEATED') return const Color(0xFF2E6F40);
    if (st == 'PENDING' || st == 'WAITING') return const Color(0xFF856404);
    if (st.contains('NO SHOW') || st == 'CANCELLED') return const Color(0xFF721C24);
    return const Color(0xFF8C532B);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F5),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _restaurantService.streamWalkins(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brownDeep));
          }

          final allWalkins = snapshot.data ?? [];
          final confirmedCount = allWalkins.where((r) => (r['status'] ?? 'CONFIRMED').toString().toUpperCase() == 'CONFIRMED').length;
          final seatedCount = allWalkins.where((r) => ['ARRIVED', 'SEATED'].contains((r['status'] ?? '').toString().toUpperCase())).length;
          final waitingCount = allWalkins.where((r) => ['PENDING', 'WAITING'].contains((r['status'] ?? '').toString().toUpperCase())).length;

          final filteredWalkins = allWalkins.where((res) {
            final st = (res['status'] ?? 'CONFIRMED').toString().toUpperCase();
            if (_selectedFilter == 'CONFIRMED' && st != 'CONFIRMED') return false;
            if (_selectedFilter == 'SEATED' && (st != 'ARRIVED' && st != 'SEATED')) return false;
            if (_selectedFilter == 'WAITING' && (st != 'PENDING' && st != 'WAITING')) return false;

            if (_searchQuery.isNotEmpty) {
              final name = (res['name'] ?? '').toString().toLowerCase();
              final phone = (res['phone'] ?? '').toString().toLowerCase();
              final walkinCode = (res['walkinCode'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery) || phone.contains(_searchQuery) || walkinCode.contains(_searchQuery);
            }
            return true;
          }).toList();

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Walk-Ins',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDeep,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brownDeep,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: widget.onAddWalkin,
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: Text('Add Walk-in', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip('ALL', allWalkins.length),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('CONFIRMED', confirmedCount),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('SEATED', seatedCount),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('WAITING', waitingCount),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Cards List
                if (filteredWalkins.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'No walk-ins match criteria',
                        style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...filteredWalkins.map((res) => _buildWalkinCardItem(res)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBF1E8) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFD6BEAA) : const Color(0xFFEFE8E1),
          ),
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isSelected ? const Color(0xFF5A3214) : const Color(0xFF9E7A5A),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  void _showWalkinDetailsModal(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'CONFIRMED').toString().toUpperCase();
    final name = item['name'] ?? 'Unknown Guest';
    final party = item['party'] ?? 2;
    final preference = item['seatingPreference'] ?? 'None';
    final time = item['time'] ?? 'N/A';
    final email = item['email'] ?? 'N/A';
    final phone = item['phone'] ?? 'N/A';
    final rawTable = item['table']?.toString() ?? 'Unassigned';
    final table = (rawTable.toLowerCase() == 'auto') 
        ? ((preference == 'None' || preference == '') ? 'Unassigned' : preference) 
        : rawTable;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
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
                  decoration: BoxDecoration(color: const Color(0xFFD6BEAA), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brownDeep),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Divider(color: Color(0xFFEFE8E1)),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF7A4A28)),
                  const SizedBox(width: 12),
                  Text(phone, style: GoogleFonts.poppins(color: const Color(0xFF4A2A18), fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 18, color: Color(0xFF7A4A28)),
                  const SizedBox(width: 12),
                  Text(email, style: GoogleFonts.poppins(color: const Color(0xFF4A2A18), fontSize: 14)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFEFE8E1)),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Party Size', style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('$party Guests', style: GoogleFonts.poppins(color: const Color(0xFF4A2A18), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Table', style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(table.toString(), style: GoogleFonts.poppins(color: const Color(0xFF4A2A18), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Time', style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 11, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(time, style: GoogleFonts.poppins(color: const Color(0xFF4A2A18), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              
              if (preference != 'None' && preference != '') ...[
                const SizedBox(height: 20),
                Text('Seating Preference', style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF9F5F0), borderRadius: BorderRadius.circular(8)),
                  child: Text(preference, style: GoogleFonts.poppins(color: const Color(0xFF4A2A18), fontSize: 13, fontStyle: FontStyle.italic)),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brownDeep,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Close Details', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWalkinCardItem(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'CONFIRMED').toString().toUpperCase();
    final name = item['name'] ?? 'Unknown Guest';
    final party = item['party'] ?? 2;
    final time = item['time'] ?? 'N/A';
    final preference = item['seatingPreference'] ?? 'None';
    final rawTable = item['table']?.toString() ?? 'Unassigned';
    final tableDisplay = (rawTable.toLowerCase() == 'auto') 
        ? ((preference == 'None' || preference == '') ? 'Unassigned' : preference) 
        : rawTable;
    
    return GestureDetector(
      onTap: () => _showWalkinDetailsModal(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE8E1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Accent Border line
              Container(
                width: 5,
                color: const Color(0xFF7A4A28),
              ),
              Expanded(
                child: Column(
                  children: [
                    // Distinct Top Header Strip for Walk-ins
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F5F0),
                border: Border(bottom: BorderSide(color: Color(0xFFEFE8E1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_walk_rounded, size: 16, color: Color(0xFF8C532B)),
                      const SizedBox(width: 6),
                      Text(
                        'WALK-IN',
                        style: GoogleFonts.poppins(color: const Color(0xFF8C532B), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled, size: 14, color: Color(0xFF9E7A5A)),
                      const SizedBox(width: 4),
                      Text(time, style: GoogleFonts.poppins(color: const Color(0xFF7A4A28), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            // Info Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(color: const Color(0xFF3B2314), fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusBgColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getStatusTextColor(status),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3EFEA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt, size: 16, color: Color(0xFF7A4A28)),
                            const SizedBox(width: 6),
                            Text('$party Guests', style: GoogleFonts.poppins(color: const Color(0xFF4A2A18), fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (tableDisplay != 'Unassigned')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EFEA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD6BEAA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.table_restaurant_rounded, size: 16, color: Color(0xFF7A4A28)),
                              const SizedBox(width: 6),
                              Text(tableDisplay, style: GoogleFonts.poppins(color: const Color(0xFF4A2A18), fontSize: 13, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}





