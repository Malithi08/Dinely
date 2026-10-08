import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/manager_restaurant_service.dart';

class ManagerQueueScreen extends StatefulWidget {
  final String restaurantId;
  final Function(String) onAddGuest;

  const ManagerQueueScreen({
    super.key,
    required this.restaurantId,
    required this.onAddGuest,
  });

  @override
  State<ManagerQueueScreen> createState() => _ManagerQueueScreenState();
}

class _ManagerQueueScreenState extends State<ManagerQueueScreen> {
  final ManagerRestaurantService _restaurantService = ManagerRestaurantService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _restaurantService.streamQueue(widget.restaurantId),
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
                    Text('Waitlist Queue', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brownDeep)),
                    Text('${queueItems.length} groups currently waiting', style: GoogleFonts.poppins(color: AppColors.brownMuted, fontSize: 13)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => widget.onAddGuest('Add Waitlist Guest'),
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
                    await _restaurantService.updateQueueStatus(widget.restaurantId, item['docId'], 'Seated');
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
}
