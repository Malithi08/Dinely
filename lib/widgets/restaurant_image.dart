import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RestaurantImage extends StatelessWidget {
  final String imagePath;
  final String fallbackName;
  final BoxFit fit;

  const RestaurantImage({
    Key? key,
    required this.imagePath,
    required this.fallbackName,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  Color _colorFromName(String name) {
    final hash = name.codeUnits.fold<int>(0, (prev, c) => prev + c);
    final colors = [
      AppColors.primary,
      AppColors.brownWarm,
      AppColors.brownDeep,
      AppColors.brownOlive,
      AppColors.tan,
    ];
    return colors[hash % colors.length];
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: _colorFromName(fallbackName),
      alignment: Alignment.center,
      child: Text(
        _initials(fallbackName),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) return _buildPlaceholder();

    if (!imagePath.startsWith('http')) {
      return Image.file(
        File(imagePath),
        width: double.infinity,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return Image.network(
      imagePath,
      width: double.infinity,
      fit: fit,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.cream,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }
}