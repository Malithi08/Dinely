import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/manager_restaurant_service.dart';

class ManagerAllocateTableScreen extends StatefulWidget {
  final String restaurantId;
  final String? initialCustomerId;

  const ManagerAllocateTableScreen({super.key, required this.restaurantId, this.initialCustomerId});

  @override
  State<ManagerAllocateTableScreen> createState() => _ManagerAllocateTableScreenState();
}

class _ManagerAllocateTableScreenState extends State<ManagerAllocateTableScreen> {
  final ManagerRestaurantService _restaurantService = ManagerRestaurantService();
  String? _selectedCustomerId;
  Map<String, dynamic>? _selectedCustomerData;
  String? _selectedTableId;
  String _tableFilter = 'All Areas';

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.initialCustomerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F0), 
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWaitingCustomersSection(),
                    const SizedBox(height: 24),
                    _buildAvailableTablesSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildAllocateButton(),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF7A4A28),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Allocate Table',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Row(
            children: [
              Icon(Icons.notifications_none, color: Colors.white),
              SizedBox(width: 16),
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 16, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingCustomersSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _restaurantService.streamWalkins(widget.restaurantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final customers = snapshot.data!.where((c) {
          final st = (c['status'] ?? '').toString().toUpperCase();
          return !['ARRIVED', 'SEATED'].contains(st) && !st.contains('CANCEL') && !st.contains('NO SHOW');
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Waiting Customers', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3B2314))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF3EFEA), borderRadius: BorderRadius.circular(12)),
                      child: Text('${customers.length} waiting', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9E7A5A))),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...customers.map((c) => _buildCustomerCard(c)),
          ],
        );
      },
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    bool isSelected = _selectedCustomerId == customer['docId'];
    
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCustomerId = customer['docId'];
        _selectedCustomerData = customer;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF5A3214) : const Color(0xFFEFE8E1), width: isSelected ? 2 : 1),
          boxShadow: [
            if (isSelected) BoxShadow(color: const Color(0xFF5A3214).withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1)
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(customer['name'] ?? 'Unknown', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF3B2314))),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFFFBF1E8), borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          'Walk-in',
                          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF8C532B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_alt, size: 14, color: Color(0xFF7A4A28)),
                      const SizedBox(width: 4),
                      Text('${customer['party'] ?? 2} Guests', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF4A2A18))),
                      const SizedBox(width: 8),
                      const CircleAvatar(radius: 2, backgroundColor: Color(0xFFD6BEAA)),
                      const SizedBox(width: 8),
                      Text((customer['seatingPreference'] == null || customer['seatingPreference'] == 'None' || customer['seatingPreference'] == '') ? 'Any seating' : customer['seatingPreference'], style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9E7A5A))),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 12, color: Color(0xFF9E7A5A)),
                    const SizedBox(width: 4),
                    Text(customer['time'] ?? 'Now', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9E7A5A))),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF5A3214) : const Color(0xFF8C532B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSelected ? 'Selected ✓' : 'Choose Table',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableTablesSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _restaurantService.streamTables(widget.restaurantId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final tables = snapshot.data!.where((t) => t['status']?.toString().toLowerCase() == 'available').toList();
        final filteredTables = _tableFilter == 'All Areas' ? tables : tables.where((t) => (t['area']?.toString().toLowerCase() ?? '') == _tableFilter.toLowerCase()).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Available Tables', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3B2314))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF3EFEA), borderRadius: BorderRadius.circular(12)),
                  child: Text('${tables.length} ready', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9E7A5A))),
                ),
              ],
            ),
            const SizedBox(height: 12),
             SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All Areas', 'Indoor', 'Patio', 'Rooftop']
                    .map((area) => GestureDetector(
                          onTap: () => setState(() => _tableFilter = area),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _tableFilter == area ? const Color(0xFFFBF1E8) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              area,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: _tableFilter == area ? FontWeight.bold : FontWeight.normal,
                                color: _tableFilter == area ? const Color(0xFF8C532B) : const Color(0xFF9E7A5A),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredTables.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemBuilder: (context, index) {
                final table = filteredTables[index];
                return _buildTableCard(table);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    bool isSelected = _selectedTableId == table['id'];
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTableId = table['id']),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBF1E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF5A3214) : const Color(0xFFEFE8E1), width: isSelected ? 2 : 1),
          boxShadow: [
            if (isSelected) BoxShadow(color: const Color(0xFF5A3214).withValues(alpha: 0.1), blurRadius: 4, spreadRadius: 0)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(table['area'] == 'Patio' ? Icons.beach_access : Icons.table_bar, size: 16, color: const Color(0xFF7A4A28)),
                    const SizedBox(width: 4),
                    Text(table['tableNumber'] ?? 'T', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3B2314))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                  child: Text('${table['seats'] ?? 2} Seats', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF9E7A5A))),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${table['area']} • ${table['seats']} Seats', style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9E7A5A))),
                if (isSelected)
                  const Icon(Icons.check_circle, size: 14, color: Color(0xFF5A3214))
                else
                  const CircleAvatar(radius: 4, backgroundColor: Color(0xFFD6BEAA)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A3214),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: (_selectedCustomerId != null && _selectedTableId != null) ? () async {
            await _restaurantService.updateWalkinStatus(
              _selectedCustomerId!, 'Seated',
              tableId: _selectedTableId,
              walkinData: _selectedCustomerData,
              managerId: 'Manager', // Provide a fallback if manager ID is not available globally here
            );
            await _restaurantService.updateTableStatus(widget.restaurantId, _selectedTableId!, 'Occupied');
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Table Allocated successfully')));
            Navigator.pop(context);
          } : null,
          icon: const Icon(Icons.chair_alt, color: Colors.white, size: 18),
          label: Text('Allocate Selected Table', style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
