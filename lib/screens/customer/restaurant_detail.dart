import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import 'reservation_form.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final Restaurant restaurant;
  const RestaurantDetailScreen({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.primary,
            iconTheme:
                const IconThemeData(color: AppColors.cream),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                restaurant.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.tan.withValues(alpha: 0.3),
                  child: const Icon(Icons.restaurant,
                      size: 80, color: AppColors.primary),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(restaurant.name,
                      style: AppTextStyles.heading
                          .copyWith(fontSize: 24)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          size: 18, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(restaurant.rating.toStringAsFixed(1),
                          style: AppTextStyles.roleTitle),
                      const SizedBox(width: 14),
                      Text(restaurant.cuisine,
                          style: AppTextStyles.subtitle),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _infoRow(Icons.location_on_outlined, 'Address',
                      restaurant.address),
                  _infoRow(Icons.access_time, 'Open Hours',
                      restaurant.openHours),
                  _infoRow(Icons.table_restaurant_outlined,
                      'Available Tables',
                      '${restaurant.availableTables} tables'),

                  const SizedBox(height: 24),
                  Text('About',
                      style: AppTextStyles.heading
                          .copyWith(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    'Experience the finest ${restaurant.cuisine} cuisine at '
                    '${restaurant.name}. Book your table now to enjoy an '
                    'unforgettable dining experience with your loved ones.',
                    style: AppTextStyles.subtitle.copyWith(
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 30),

                  PrimaryButton(
                    text: 'Reserve a Table',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReservationFormScreen(
                          restaurant: restaurant,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.smallMuted),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.roleTitle),
            ],
          ),
        ],
      ),
    );
  }
}