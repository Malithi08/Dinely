import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/restaurant.dart';
import '../../models/reservation.dart';
import '../../services/auth_service.dart';
import '../../services/reservation_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class ReservationFormScreen extends StatefulWidget {
  final Restaurant restaurant;
  const ReservationFormScreen({super.key, required this.restaurant});

  @override
  State<ReservationFormScreen> createState() =>
      _ReservationFormScreenState();
}

class _ReservationFormScreenState extends State<ReservationFormScreen> {
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  int _guests = 2;
  final _requestCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    setState(() => _loading = true);

    final auth = AuthService();
    final profile = await auth.getUserProfile();
    if (!mounted) return;

    final uid = auth.currentUser?.uid;
    if (uid == null || profile == null) {
      setState(() => _loading = false);
      return;
    }

    final dateTime = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final reservation = Reservation(
      id: '',
      userId: uid,
      userName: profile['name'] ?? 'Guest',
      restaurantId: widget.restaurant.id,
      restaurantName: widget.restaurant.name,
      dateTime: dateTime,
      guests: _guests,
      status: 'pending',
      specialRequest: _requestCtrl.text.trim().isEmpty
          ? null
          : _requestCtrl.text.trim(),
    );

    try {
      await ReservationService().createReservation(reservation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation requested successfully!'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('EEEE, MMM d, yyyy');
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Reserve Table',
            style: AppTextStyles.heading.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.restaurant,
                      color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.restaurant.name,
                        style: AppTextStyles.roleTitle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Date', style: AppTextStyles.roleTitle),
            const SizedBox(height: 8),
            _pickerTile(
              icon: Icons.calendar_today_outlined,
              text: dateFmt.format(_date),
              onTap: _pickDate,
            ),

            const SizedBox(height: 18),
            Text('Time', style: AppTextStyles.roleTitle),
            const SizedBox(height: 8),
            _pickerTile(
              icon: Icons.access_time,
              text: _time.format(context),
              onTap: _pickTime,
            ),

            const SizedBox(height: 18),
            Text('Guests', style: AppTextStyles.roleTitle),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.people_outline,
                      color: AppColors.brownMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('$_guests guests',
                        style: AppTextStyles.roleTitle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.primary,
                    onPressed: _guests > 1
                        ? () => setState(() => _guests--)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.primary,
                    onPressed: _guests < 20
                        ? () => setState(() => _guests++)
                        : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Text('Special Request (optional)',
                style: AppTextStyles.roleTitle),
            const SizedBox(height: 8),
            TextField(
              controller: _requestCtrl,
              maxLines: 3,
              style: AppTextStyles.inputText,
              decoration: InputDecoration(
                hintText: 'Window seat, birthday cake, etc.',
                hintStyle: AppTextStyles.inputHint,
                filled: true,
                fillColor: AppColors.white,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: AppColors.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide:
                      const BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),

            const SizedBox(height: 30),
            PrimaryButton(
              text: _loading ? 'Booking...' : 'Confirm Reservation',
              onPressed: _loading ? null : _submit,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brownMuted, size: 20),
            const SizedBox(width: 12),
            Text(text, style: AppTextStyles.roleTitle),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                size: 12, color: AppColors.brownMuted),
          ],
        ),
      ),
    );
  }
}