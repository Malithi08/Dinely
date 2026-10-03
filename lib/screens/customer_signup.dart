import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/dinely_text_field.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';

class CustomerSignupScreen extends StatefulWidget {
  const CustomerSignupScreen({super.key});

  @override
  State<CustomerSignupScreen> createState() => _CustomerSignupScreenState();
}

class _CustomerSignupScreenState extends State<CustomerSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _agree = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_agree) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the terms')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final auth = AuthService();
    final error = await auth.signUp(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _pwdCtrl.text,
      role: 'customer',
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHero(context),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Your details',
                          style: AppTextStyles.roleTitle.copyWith(
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'All fields are required',
                          style: AppTextStyles.smallMuted,
                        ),
                        const SizedBox(height: 20),

                        DinelyTextField(
                          hint: 'Full name',
                          icon: Icons.person_outline,
                          controller: _nameCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your name'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        DinelyTextField(
                          hint: 'Email address',
                          icon: Icons.mail_outline,
                          controller: _emailCtrl,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!v.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        DinelyTextField(
                          hint: 'Phone number',
                          icon: Icons.phone_outlined,
                          controller: _phoneCtrl,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Please enter your phone number'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        DinelyTextField(
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          obscure: true,
                          controller: _pwdCtrl,
                          validator: (v) => (v == null || v.length < 6)
                              ? 'Password must be at least 6 characters'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        DinelyTextField(
                          hint: 'Confirm password',
                          icon: Icons.lock_outline,
                          obscure: true,
                          controller: _confirmCtrl,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (v != _pwdCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _agree,
                                onChanged: (v) =>
                                    setState(() => _agree = v ?? false),
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                side: const BorderSide(
                                    color: AppColors.brownMuted),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(
                                  'I agree to the Terms & Privacy Policy',
                                  style: AppTextStyles.link,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        PrimaryButton(
                          text: 'Create Account',
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already a member? ',
                      style: AppTextStyles.subtitle),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Sign In',
                      style: AppTextStyles.link.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 80),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 28),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/images/login_logo.jpg',
              height: 55,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.restaurant_menu,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Create your\naccount',
            style: GoogleFonts.playfairDisplay(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.cream,
              height: 1.15,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Join Dinely and reserve your table in seconds.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.cream.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}