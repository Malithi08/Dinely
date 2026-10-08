import 'package:flutter/material.dart';
import '../../models/reservation.dart';
import '../../services/auth_service.dart';
import '../../services/reservation_service.dart';
import '../../services/restaurant_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/restaurant_card.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/section_header.dart';
import '../customer_login.dart';
<<<<<<< Updated upstream
=======
import 'my_reservations.dart';
>>>>>>> Stashed changes
import 'restaurant_detail.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _restaurantService = RestaurantService();
  final _reservationService = ReservationService();
  final _auth = AuthService();

  String _userName = 'Guest';
  String _userId = '';
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final profile = await _auth.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _userName = profile['name'] ?? 'Guest';
        _userId = profile['uid'] ?? '';
      });
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const CustomerLoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDiscover(),
<<<<<<< Updated upstream
=======
      const MyReservationsScreen(),
>>>>>>> Stashed changes
      _buildProfile(),
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(child: pages[_navIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppColors.primary),
              label: 'Home'),
          NavigationDestination(
<<<<<<< Updated upstream
=======
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon:
                  Icon(Icons.calendar_month, color: AppColors.primary),
              label: 'Bookings'),
          NavigationDestination(
>>>>>>> Stashed changes
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.primary),
              label: 'Profile'),
        ],
      ),
    );
  }

  // ─── DISCOVER TAB ─────────────────────────
  Widget _buildDiscover() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 210,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=1200&q=80',
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: AppColors.tan,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.15),
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Food',
                                style: AppTextStyles.heading.copyWith(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                'Great Moments',
                                style: AppTextStyles.heading.copyWith(
                                  color: Colors.white,
                                  fontSize: 30,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Enjoy delicious food, beautiful ambiance and unforgettable moments.',
                                style: AppTextStyles.subtitle.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search restaurants or cuisine',
                    hintStyle: AppTextStyles.inputHint,
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.brownMuted),
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: const BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Upcoming reservation
                if (_userId.isNotEmpty)
                  StreamBuilder<List<Reservation>>(
                    stream: _reservationService
                        .streamUserReservations(_userId),
                    builder: (context, snap) {
                      if (!snap.hasData || snap.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final upcoming = snap.data!.firstWhere(
                        (r) =>
                            r.status != 'cancelled' &&
                            r.status != 'completed' &&
                            r.dateTime.isAfter(DateTime.now()),
                        orElse: () => snap.data!.first,
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Upcoming'),
                          const SizedBox(height: 12),
                          ReservationCard(reservation: upcoming),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),

                const SectionHeader(title: 'Popular Restaurants'),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: StreamBuilder(
            stream: _restaurantService.streamRestaurants(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  ),
                );
              }

              if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
                // Show placeholder data if Firestore is empty
                return SliverList(
                  delegate: SliverChildListDelegate([
                    _buildPlaceholderCard(
                      'The Spice Garden',
                      'Sri Lankan • 10am - 10pm',
                      4.8,
                    ),
                    _buildPlaceholderCard(
                      'Ocean Pearl',
                      'Seafood • 11am - 11pm',
                      4.6,
                    ),
                    _buildPlaceholderCard(
                      'Urban Bites',
                      'Fusion • 9am - 10pm',
                      4.4,
                    ),
                  ]),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final r = snap.data![i];
                    return RestaurantCard(
                      restaurant: r,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RestaurantDetailScreen(restaurant: r),
                        ),
                      ),
                    );
                  },
                  childCount: snap.data!.length,
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );
  }

  Widget _buildPlaceholderCard(
      String name, String info, double rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.tan.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.restaurant,
                color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.roleTitle),
                const SizedBox(height: 4),
                Text(info, style: AppTextStyles.subtitle),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(rating.toStringAsFixed(1),
                        style: AppTextStyles.smallMuted),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PROFILE TAB ──────────────────────────
  Widget _buildProfile() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _auth.getUserProfile(),
      builder: (context, snap) {
        final p = snap.data;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Text(
                  (_userName.isNotEmpty ? _userName[0] : 'G')
                      .toUpperCase(),
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.cream,
                    fontSize: 36,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(_userName,
                  style: AppTextStyles.heading.copyWith(fontSize: 22)),
              const SizedBox(height: 4),
              Text(p?['email'] ?? '', style: AppTextStyles.subtitle),
              const SizedBox(height: 30),

              _infoTile(Icons.phone_outlined, 'Phone',
                  p?['phone'] ?? '—'),
              _infoTile(Icons.badge_outlined, 'Role',
                  p?['role'] ?? 'customer'),
              _infoTile(Icons.calendar_today_outlined, 'Member since',
                  '2026'),

              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout,
                      color: Colors.redAccent),
                  label: Text('Log Out',
                      style: AppTextStyles.outlinedButton
                          .copyWith(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 14),
          Text(label, style: AppTextStyles.subtitle),
          const Spacer(),
          Text(value, style: AppTextStyles.roleTitle),
        ],
      ),
    );
  }
}