import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../table_availability_screen.dart';
import '../queue_tab_screen.dart';
import '../customer_login.dart';

class CustomerDashboardScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const CustomerDashboardScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  int _navIndex = 0;

  Future<void> _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
      (_) => false,
    );
  }

  void _onNavTap(int i) {
    if (i == _navIndex) return;
    setState(() => _navIndex = i);
    switch (i) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TableAvailabilityScreen(
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
            ),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => QueueTabScreen(
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cream,
        elevation: 0,
        title: Text(widget.restaurantName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              _showProfileSheet(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // Hero image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(
                'assets/images/restaurant_hero.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3A1F10), Color(0xFF7E553B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.restaurantName,
            style: AppTextStyles.heading.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          Text('What would you like to do?',
              style: AppTextStyles.subtitle),
          const SizedBox(height: 24),

          // Reserve a Table
          _actionTile(
            icon: Icons.table_restaurant,
            title: 'Reserve a Table',
            subtitle: 'Pick your table and reserve',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TableAvailabilityScreen(
                    restaurantId: widget.restaurantId,
                    restaurantName: widget.restaurantName,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Join the Queue
          _actionTile(
            icon: Icons.people_alt,
            title: 'Join the Queue',
            subtitle: 'Walk-in? Get in line from your phone',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QueueTabScreen(
                    restaurantId: widget.restaurantId,
                    restaurantName: widget.restaurantName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: _onNavTap,
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_restaurant_outlined),
            selectedIcon:
                Icon(Icons.table_restaurant, color: AppColors.primary),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Queue',
          ),
        ],
      ),
    );
  }

  // ─── Profile bottom sheet with logout ────────
  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inputBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary,
                      child: Icon(
                        Icons.person,
                        color: AppColors.cream,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Profile',
                            style: AppTextStyles.roleTitle
                                .copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage your account',
                            style: AppTextStyles.smallMuted,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    icon: const Icon(Icons.logout,
                        color: Colors.redAccent, size: 18),
                    label: Text(
                      'Log Out',
                      style: AppTextStyles.outlinedButton
                          .copyWith(color: Colors.redAccent),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                            AppTextStyles.roleTitle.copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTextStyles.smallMuted
                            .copyWith(fontSize: 11.5)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.brownMuted),
            ],
          ),
        ),
      ),
    );
  }
}