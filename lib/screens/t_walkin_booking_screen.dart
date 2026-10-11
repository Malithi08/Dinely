import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/restaurant.dart';
import '../services/t_walkin_service.dart';
import 't_walkin_confirmation_screen.dart';

class WalkinBookingScreen extends StatefulWidget {
  final Restaurant restaurant;

  const WalkinBookingScreen({
    Key? key,
    required this.restaurant,
  }) : super(key: key);

  @override
  State<WalkinBookingScreen> createState() => _WalkinBookingScreenState();
}

class _WalkinBookingScreenState extends State<WalkinBookingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _guests = 2;
  String _seating = 'Indoor';

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);

  bool _isLoading = false;

  final List<String> _seatingOptions = ['Indoor', 'Outdoor', 'Window'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Name is required';
    if (v.length < 3) return 'Name must be at least 3 characters';
    if (!RegExp(r'^[a-zA-Z\s\.\-]+$').hasMatch(v)) {
      return 'Name can only contain letters, spaces, dots and hyphens';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Phone number is required';
    final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 9) {
      return 'Phone number must have at least 9 digits';
    }
    if (digitsOnly.length > 15) {
      return 'Phone number is too long';
    }
    if (!RegExp(r'^[0-9\+\-\s]+$').hasMatch(v)) {
      return 'Phone can only contain digits, +, - and spaces';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    final emailRegex = RegExp(
      r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$',
    );
    if (!emailRegex.hasMatch(v)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validateDate(DateTime date) {
    final today = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final t = DateTime(today.year, today.month, today.day);
    if (d.isBefore(t)) return 'Date cannot be in the past';
    return null;
  }

  String? _validateTime(DateTime date, TimeOfDay time) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    if (isToday) {
      final selectedMinutes = time.hour * 60 + time.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      if (selectedMinutes <= nowMinutes) {
        return 'Time must be in the future';
      }
    }
    return null;
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

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _confirmWalkin() async {
    if (!_formKey.currentState!.validate()) return;

    final dateError = _validateDate(_selectedDate);
    if (dateError != null) {
      _showError(dateError);
      return;
    }

    final timeError = _validateTime(_selectedDate, _selectedTime);
    if (timeError != null) {
      _showError(timeError);
      return;
    }

    if (_guests < 1 || _guests > 6) {
      _showError('Guests must be between 1 and 6');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final service = WalkinService();
      final walkinId = await service.createWalkin(
        customerName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        date: _formatDate(_selectedDate),
        time: _formatTime(_selectedTime),
        guests: _guests,
        tableId: 'auto',
        seatingPreference: _seating,
        restaurantId: widget.restaurant.id,
        restaurantName: widget.restaurant.name,
        restaurantImage: widget.restaurant.imageUrl,
      );

      final walkin = await service.getWalkinById(walkinId);

      if (!mounted || walkin == null) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WalkinConfirmationScreen(walkin: walkin),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brownDarkest),
        title: const Text(
          'New Walk-in',
          style: TextStyle(
            color: AppColors.brownDarkest,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Reservation',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brownDarkest,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Quickly create a walk-in reservation.',
                style: TextStyle(fontSize: 12, color: AppColors.brownMuted),
              ),
              const SizedBox(height: 20),

              _buildSection(
                icon: Icons.person_outline,
                title: 'Customer Details',
                subtitle: 'Enter the customer\'s information.',
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'FULL NAME',
                      hint: 'Enter customer name',
                      validator: _validateName,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'PHONE NUMBER',
                      hint: 'Enter phone number',
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _emailController,
                      label: 'EMAIL (OPTIONAL)',
                      hint: 'Enter email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildSection(
                icon: Icons.event_seat_outlined,
                title: 'Reservation Details',
                subtitle: 'Select seating and timing details.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTappableInfo(
                            icon: Icons.calendar_today,
                            label: 'Date',
                            value: _formatDate(_selectedDate),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTappableInfo(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: _formatTime(_selectedTime),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'NUMBER OF GUESTS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(6, (index) {
                        final count = index + 1;
                        final isSelected = count == _guests;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _guests = count),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.cream,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.brownDarkest,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'SEATING PREFERENCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _seatingOptions.map((s) {
                        final isSelected = s == _seating;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _seating = s),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.cream,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.divider,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.brownDarkest,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmWalkin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Confirm Walk-in',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_outlined, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Edit',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brownDarkest,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.brownMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.brownMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.brownDarkest,
          ),
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.brownMuted,
            ),
            filled: true,
            fillColor: AppColors.cream,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTappableInfo({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.tan),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 9,
                      color: AppColors.brownMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brownDarkest,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: AppColors.brownMuted,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}