import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DinelyTextField extends StatefulWidget {
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const DinelyTextField({
    super.key,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.controller,
    this.validator,
  });

  @override
  State<DinelyTextField> createState() => _DinelyTextFieldState();
}

class _DinelyTextFieldState extends State<DinelyTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      validator: widget.validator,
      style: AppTextStyles.inputText,
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: AppTextStyles.inputHint,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIcon:
            Icon(widget.icon, size: 20, color: AppColors.brownMuted),
        suffixIcon: widget.obscure
            ? IconButton(
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: AppColors.brownMuted,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.4),
        ),
      ),
    );
  }
}