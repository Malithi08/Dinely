import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle heading = GoogleFonts.playfairDisplay(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.brownDeep,
    letterSpacing: 0.2,
  );

  static TextStyle subtitle = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.brownMuted,
  );

  static TextStyle inputText = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.brownDeep,
  );

  static TextStyle inputHint = GoogleFonts.poppins(
    fontSize: 13.5,
    fontWeight: FontWeight.w400,
    color: AppColors.brownMuted,
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.cream,
    letterSpacing: 0.3,
  );

  static TextStyle link = GoogleFonts.poppins(
    fontSize: 12.5,
    fontWeight: FontWeight.w500,
    color: AppColors.brownMedium,
  );

  static TextStyle smallMuted = GoogleFonts.poppins(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: AppColors.grayBrown,
  );

  static TextStyle roleTitle = GoogleFonts.poppins(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: AppColors.brownDeep,
  );

  static TextStyle roleSubtitle = GoogleFonts.poppins(
    fontSize: 11.5,
    fontWeight: FontWeight.w400,
    color: AppColors.brownMuted,
  );

  static TextStyle outlinedButton = GoogleFonts.poppins(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: AppColors.brownDeep,
  );
}