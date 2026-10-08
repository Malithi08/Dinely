import 'package:flutter/material.dart';
import '../models/restaurant.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback onTap;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                restaurant.imageUrl,
                height: 140,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 140,
                  color: AppColors.tan.withOpacity(0.3),
                  child: const Icon(Icons.restaurant,
                      size: 50, color: AppColors.primary),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(restaurant.name,
                            style: AppTextStyles.roleTitle.copyWith(
                              fontSize: 16,
                            )),
                      ),
                      const Icon(Icons.star,
                          size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(restaurant.rating.toStringAsFixed(1),
                          style: AppTextStyles.roleTitle),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${restaurant.cuisine} • ${restaurant.openHours}',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.brownMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(restaurant.address,
                            style: AppTextStyles.smallMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}