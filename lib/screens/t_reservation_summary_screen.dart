import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dining_table.dart';
import '../services/t_reservation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/availability_bottom_nav.dart';
import 't_reservation_confirmation_screen.dart';

class TReservationSummaryScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final DiningTable table;
  final int guestCount;

  const TReservationSummaryScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    required this.table,
    this.guestCount = 2,
  });

  @override
  State<TReservationSummaryScreen> createState() =>
      _TReservationSummaryScreenState();
}

class _TReservationSummaryScreenState
    extends State<TReservationSummaryScreen> {
  String _customerName = '';
  String _customerPhone = '';
  String _customerEmail = '';
  bool _loadingUser = true;

  String _restaurantImageUrl = '';
  String _restaurantAddress = '';
  bool _loadingRestaurant = true;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 30);

  bool _submitting = false;
  int _navIndex = 1;
  bool _agreedToTerms = false;

  final _service = TReservationService();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserDetails(),
      _loadRestaurantDetails(),
    ]);
  }

  Future<void> _loadUserDetails() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      setState(() => _loadingUser = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _customerName = data['name'] ??
              data['fullName'] ??
              data['displayName'] ??
              FirebaseAuth.instance.currentUser?.displayName ??
              '';
          _customerPhone = data['phone'] ??
              data['mobile'] ??
              data['phoneNumber'] ??
              '';
          _customerEmail = data['email'] ??
              data['userEmail'] ??
              FirebaseAuth.instance.currentUser?.email ??
              '';
          _loadingUser = false;
        });
      } else {
        setState(() {
          _customerName =
              FirebaseAuth.instance.currentUser?.displayName ?? '';
          _customerEmail =
              FirebaseAuth.instance.currentUser?.email ?? '';
          _loadingUser = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingUser = false);
    }
  }

  Future<void> _loadRestaurantDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _restaurantImageUrl = data['imageUrl'] ??
              data['image'] ??
              data['imagePath'] ??
              '';
          _restaurantAddress = data['address'] ?? '';
          _loadingRestaurant = false;
        });
      } else {
        setState(() => _loadingRestaurant = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRestaurant = false);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.brownDarkest,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.brownDarkest,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _confirmReservation() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_customerName.isEmpty || _customerPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile incomplete. Please add name & phone.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final error = await _service.createReservation(
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      table: widget.table,
      customerName: _customerName,
      customerPhone: _customerPhone,
      customerEmail: _customerEmail,
      guestCount: widget.guestCount,
      reservedDate: _selectedDate,
      reservedTime: _formatTime(_selectedTime),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TReservationConfirmationScreen(
          restaurantId: widget.restaurantId,
          restaurantName: widget.restaurantName,
          table: widget.table,
          customerName: _customerName,
          customerPhone: _customerPhone,
          guestCount: widget.guestCount,
          reservedDate: _selectedDate,
          reservedTime: _formatTime(_selectedTime),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loadingUser || _loadingRestaurant;

    return Scaffold(
      backgroundColor: AppColors.cream,

      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.brownDarkest,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reservation Summary',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.brownDarkest,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.brownDarkest,
            ),
            onPressed: () {},
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Review your reservation details before confirming.',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: _buildRestaurantImage(),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.75),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.restaurantName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_restaurantAddress.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 13,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _restaurantAddress,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Table ${widget.table.tableNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _sectionCard(
                    icon: Icons.person_outline,
                    title: 'Customer Details',
                    children: [
                      _infoRow(
                        'Full Name',
                        _customerName.isEmpty ? '—' : _customerName,
                      ),
                      _infoRow(
                        'Phone Number',
                        _customerPhone.isEmpty ? '—' : _customerPhone,
                      ),
                      _infoRow(
                        'Email',
                        _customerEmail.isEmpty ? '—' : _customerEmail,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _sectionCard(
                    icon: Icons.event_seat_outlined,
                    title: 'Reservation Details',
                    children: [
                      _infoRow('Date', _formatDate(_selectedDate)),
                      _infoRow('Time', _formatTime(_selectedTime)),
                      _infoRow('Guests', '${widget.guestCount}'),
                      _infoRow('Seating Preference', widget.table.area),
                      _infoRow(
                        'Selected Table',
                        '${widget.table.tableNumber} (${widget.table.seats} seats)',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () => setState(
                      () => _agreedToTerms = !_agreedToTerms,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: _agreedToTerms
                            ? AppColors.primary.withOpacity(0.08)
                            : AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _agreedToTerms
                              ? AppColors.primary.withOpacity(0.4)
                              : AppColors.inputBorder,
                          width: _agreedToTerms ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _agreedToTerms
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: _agreedToTerms
                                    ? AppColors.primary
                                    : AppColors.brownMuted,
                                width: 1.8,
                              ),
                            ),
                            child: _agreedToTerms
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'I agree to the Terms & Conditions',
                              style: AppTextStyles.roleTitle.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.brownDarkest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting || !_agreedToTerms
                          ? null
                          : _confirmReservation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _agreedToTerms
                            ? AppColors.primary
                            : AppColors.divider,
                        foregroundColor: _agreedToTerms
                            ? AppColors.cream
                            : AppColors.brownMuted,
                        elevation: _agreedToTerms ? 4 : 0,
                        shadowColor:
                            AppColors.primary.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: const [
                                Text(
                                  'Confirm Booking',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.chevron_right, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        backgroundColor: AppColors.white,
                      ),
                      child: const Text(
                        'Edit Reservation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: AvailabilityBottomNav(
        currentIndex: _navIndex,
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        onTap: (i) {
          if (i == _navIndex) return;
          setState(() => _navIndex = i);
        },
      ),
    );
  }

  Widget _buildRestaurantImage() {
    if (_restaurantImageUrl.isEmpty) return _fallbackImage();

    if (_restaurantImageUrl.startsWith('http')) {
      return Image.network(
        _restaurantImageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.divider,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => _fallbackImage(),
      );
    }

    return Image.asset(
      _restaurantImageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallbackImage(),
    );
  }

  Widget _fallbackImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3A1F10),
            Color(0xFF7E553B),
            Color(0xFF3A1F10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.restaurant,
        size: 64,
        color: Colors.white24,
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.brownMuted),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.roleTitle.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: AppTextStyles.smallMuted),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.roleTitle.copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}