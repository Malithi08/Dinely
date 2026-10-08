import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/dinely_logo.dart';
import '../widgets/dinely_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/social_row.dart';
import '../services/auth_service.dart';
import 'manager_dashboard.dart';
import 'home_screen.dart';
import 'staff/staff_dashboard.dart';

class LoginScaffold extends StatefulWidget {
  final String title;
  final String subtitle;
  final String emailHint;
  final IconData emailIcon;
  final String passwordHint;
  final String? footnote;
  final Widget? roleBox;
  final Widget? backButton;
  final bool hideOr;
  final VoidCallback? onSignUp;
  final bool showSignUp;

  const LoginScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emailHint,
    required this.emailIcon,
    this.passwordHint = 'Password',
    this.footnote,
    this.roleBox,
    this.backButton,
    this.hideOr = false,
    this.onSignUp,
    this.showSignUp = true,
  });

  @override
  State<LoginScaffold> createState() => _LoginScaffoldState();
}

class _LoginScaffoldState extends State<LoginScaffold> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _remember = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final auth = AuthService();
    final error = await auth.signIn(
      email: _emailCtrl.text.trim(),
      password: _pwdCtrl.text,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final role = await auth.getUserRole();

    if (!mounted) return;

    if (role == 'customer') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
        (route) => false,
      );
    } else if (role == 'staff') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StaffDashboardScreen()),
      );
    } else if (role == 'manager') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManagerDashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unknown role')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          Positioned(
            top: -20,
            left: -20,
            right: -20,
            child: SizedBox(
              height: 140,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _LeafPlaceholder(alignment: Alignment.topLeft),
                  _LeafPlaceholder(alignment: Alignment.topRight),
                ],
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/restaurant_bottom.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.brownMuted.withOpacity(0.15),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.cream,
                            AppColors.cream.withOpacity(0.85),
                            AppColors.cream.withOpacity(0.35),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.20, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 180),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 50),
                    const Center(child: DinelyLogo()),
                    const SizedBox(height: 40),

                    Text(widget.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading),
                    const SizedBox(height: 10),
                    Text(widget.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.subtitle),
                    const SizedBox(height: 36),

                    DinelyTextField(
                      hint: widget.emailHint,
                      icon: widget.emailIcon,
                      controller: _emailCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please enter your ${widget.emailHint.toLowerCase()}'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    DinelyTextField(
                      hint: widget.passwordHint,
                      icon: Icons.lock_outline,
                      obscure: true,
                      controller: _pwdCtrl,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Password must be at least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _remember,
                            onChanged: (v) =>
                                setState(() => _remember = v ?? false),
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(
                                color: AppColors.brownMuted),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Remember me', style: AppTextStyles.link),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {},
                          child: Text('Forgot password?',
                              style: AppTextStyles.link),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    PrimaryButton(text: 'Sign In', onPressed: _submit),
                    const SizedBox(height: 32),

                    if (!widget.hideOr) ...[
                      const OrDivider(text: 'Or continue with'),
                      const SizedBox(height: 20),
                      const SocialRow(),
                      const SizedBox(height: 32),
                    ],

                    if (widget.footnote != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_user_outlined,
                              size: 14, color: AppColors.brownMuted),
                          const SizedBox(width: 6),
                          Text(widget.footnote!, style: AppTextStyles.link),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (widget.roleBox != null) ...[
                      widget.roleBox!,
                      const SizedBox(height: 24),
                    ],

                    if (widget.backButton != null) ...[
                      widget.backButton!,
                      const SizedBox(height: 24),
                    ],

                    if (widget.showSignUp)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Not a member? ',
                              style: AppTextStyles.subtitle),
                          GestureDetector(
                            onTap: widget.onSignUp,
                            child: Text(
                              'Sign Up',
                              style: AppTextStyles.link.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeafPlaceholder extends StatelessWidget {
  final Alignment alignment;
  const _LeafPlaceholder({required this.alignment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Transform.rotate(
        angle: alignment == Alignment.topLeft ? -0.4 : 0.4,
        child: Icon(Icons.eco, size: 60, color: Colors.green.withOpacity(0.25)),
      ),
    );
  }
}