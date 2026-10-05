import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AvailabilityBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AvailabilityBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(
      icon: Icons.table_restaurant_outlined,
      activeIcon: Icons.table_restaurant,
      label: 'Table',
    ),
    _NavItem(
      icon: Icons.event_available_outlined,
      activeIcon: Icons.event_available,
      label: 'Reservation',
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Queue',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final active = i == currentIndex;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active ? item.activeIcon : item.icon,
                          size: 22,
                          color: active
                              ? AppColors.primary
                              : AppColors.brownMuted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: AppTextStyles.smallMuted.copyWith(
                            fontSize: 10,
                            color: active
                                ? AppColors.primary
                                : AppColors.brownMuted,
                            fontWeight: active
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}