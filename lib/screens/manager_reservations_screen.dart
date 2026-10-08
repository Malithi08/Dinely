import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/manager_restaurant_service.dart';

class ManagerReservationsScreen extends StatefulWidget {
  final String restaurantId;

  const ManagerReservationsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<ManagerReservationsScreen> createState() => _ManagerReservationsScreenState();
}

class _ManagerReservationsScreenState extends State<ManagerReservationsScreen> {
  final ManagerRestaurantService _restaurantService = ManagerRestaurantService();
  String _selectedFilter = 'ALL';
  String _selectedDateFilter = 'TODAY, 14 SEP';
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
    if (st == 'PENDING') return const Color(0xFFFFF3CD);
    if (st.contains('NO SHOW')) return const Color(0xFFF8D7DA);
    return const Color(0xFFF7EBE1);
  }

  Color _getStatusTextColor(String status) {
    final st = status.toUpperCase();
    if (st == 'CONFIRMED') return const Color(0xFF8C532B);
    if (st == 'ARRIVED' || st == 'SEATED') return const Color(0xFF2E6F40);
    if (st == 'PENDING') return const Color(0xFF856404);
    if (st.contains('NO SHOW')) return const Color(0xFF721C24);
    return const Color(0xFF8C532B);
  }

  void _showNewBookingModal() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    int partySize = 4;
    String selectedTime = '7:30 PM';
    String selectedZone = 'Indoor';
    String preference = 'Window banquet table';

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
                        Text('Create New Booking', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(stCtx)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Guest Name:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Sophia Montgomery',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Phone Number:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+1 555-0192',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Party Size:', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.brownDeep)),
                    const SizedBox(height: 4),
                    Row(
                      children: [2, 4, 6, 8].map((sz) {
                        final isSel = partySize == sz;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$sz guests'),
                            selected: isSel,
                            selectedColor: AppColors.brownDeep,
                            labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.brownDeep, fontWeight: FontWeight.bold),
                            onSelected: (val) {
                              if (val) setModalState(() => partySize = sz);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brownDeep,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) return;
                          await _restaurantService.addReservation(
                            restaurantId: widget.restaurantId,
                            name: nameCtrl.text.trim(),
                            partySize: partySize,
                            phone: phoneCtrl.text.trim(),
                            time: selectedTime,
                            date: '14 SEP',
                          );
                          if (!mounted) return;
                          Navigator.pop(stCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('New booking created successfully!'),
                              backgroundColor: AppColors.brownDeep,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Text('+ CONFIRM BOOKING', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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

  void _showReassignModal(Map<String, dynamic> reservation) {
    String currentTable = reservation['table'] ?? 'T-04 (Indoor)';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reassign Table', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
              const SizedBox(height: 6),
              Text('Select a new table for ${reservation['name'] ?? 'Guest'}', style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 13)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['T-01 (Indoor)', 'T-04 (Indoor)', 'T-08 (Patio)', 'T-12 (Rooftop)'].map((tb) {
                  final isSel = currentTable == tb;
                  return ChoiceChip(
                    label: Text(tb),
                    selected: isSel,
                    selectedColor: AppColors.brownDeep,
                    labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.brownDeep, fontWeight: FontWeight.bold),
                    onSelected: (selected) async {
                      if (selected) {
                        await _restaurantService.updateReservationStatus(widget.restaurantId, reservation['docId'], reservation['status'] ?? 'CONFIRMED');
                        if (!mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Table reassigned to $tb!'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F5),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _restaurantService.streamReservations(widget.restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brownDeep));
          }

          final allReservations = snapshot.data ?? [];
          final confirmedCount = allReservations.where((r) => (r['status'] ?? 'CONFIRMED').toString().toUpperCase() == 'CONFIRMED').length;
          final arrivedCount = allReservations.where((r) => ['ARRIVED', 'SEATED'].contains((r['status'] ?? '').toString().toUpperCase())).length;
          final pendingCount = allReservations.where((r) => (r['status'] ?? '').toString().toUpperCase() == 'PENDING').length;

          final filteredReservations = allReservations.where((res) {
            final st = (res['status'] ?? 'CONFIRMED').toString().toUpperCase();
            if (_selectedFilter == 'CONFIRMED' && st != 'CONFIRMED') return false;
            if (_selectedFilter == 'ARRIVED' && (st != 'ARRIVED' && st != 'SEATED')) return false;
            if (_selectedFilter == 'PENDING' && st != 'PENDING') return false;

            if (_searchQuery.isNotEmpty) {
              final name = (res['name'] ?? '').toString().toLowerCase();
              final phone = (res['phone'] ?? '').toString().toLowerCase();
              final table = (res['table'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery) || phone.contains(_searchQuery) || table.contains(_searchQuery);
            }
            return true;
          }).toList();

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                // Header Row
                Text(
                  'Reservations',
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brownDeep,
                  ),
                ),



                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilterChip('ALL', allReservations.length),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('CONFIRMED', confirmedCount),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('ARRIVED', arrivedCount),
                      const SizedBox(width: 8),
                      _buildStatusFilterChip('PENDING', pendingCount),
                    ],
                  ),
                ),

                const SizedBox(height: 18),



                // Cards List
                if (filteredReservations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Text(
                        'No reservations match criteria',
                        style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...filteredReservations.map((res) => _buildReservationCardItem(res)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTab(String title, {IconData? icon}) {
    final isSelected = _selectedDateFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedDateFilter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A3214) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: const Color(0xFFEFE8E1)),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : const Color(0xFF5A3214)),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : const Color(0xFF5A3214),
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
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

  Widget _buildReservationCardItem(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'CONFIRMED').toString().toUpperCase();
    final name = item['name'] ?? 'Unknown Guest';
    final time = item['time'] ?? '7:30 PM';
    final party = item['party'] ?? 4;
    final table = item['table'] ?? 'T-04 (Indoor)';
    final preference = item['preference'] ?? item['notes'] ?? 'No special preferences noted';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('CUSTOMERNAME:', style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['name']?.toString() ?? 'N/A',
                              style: GoogleFonts.poppins(color: const Color(0xFF4A2A18), fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('RESTAURANT:', style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['restaurantId']?.toString() ?? 'N/A',
                              style: GoogleFonts.poppins(color: const Color(0xFF7A4A28), fontSize: 11, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF5F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text('STATUS:', style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: _getStatusTextColor(status),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Text('TABLE:', style: GoogleFonts.poppins(color: const Color(0xFF9E7A5A), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item['tableId']?.toString() ?? 'N/A',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3B2314),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
