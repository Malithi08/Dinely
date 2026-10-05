import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ManagerAnalyticsScreen extends StatelessWidget {
  const ManagerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
