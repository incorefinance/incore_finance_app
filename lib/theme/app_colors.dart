import 'package:flutter/material.dart';

/// Product specific color palette for InCore Finance App
/// Independent from corporate Incore branding
abstract final class AppColors {
  // Prevent instantiation
  AppColors._();

  // ============================================================================
  // NEUTRALS - Foundation colors for surfaces and backgrounds
  // ============================================================================

  /// Primary canvas background
  /// #F9FAFB
  static const Color canvas = Color(0xFFF9FAFB);

  /// Surface background for cards and dialogs
  /// #FFFFFF
  static const Color surface = Color(0xFFFFFFFF);

  /// Subtle borders
  /// #E5EDF2
  static const Color borderSubtle = Color(0xFFE5EDF2);

  /// Dividers between sections and list items
  /// Alias of borderSubtle for semantic clarity
  static const Color divider = borderSubtle;

  // ============================================================================
  // TEXT - Hierarchy for readability
  // ============================================================================

  /// Primary text color, highest emphasis
  /// #253E4C
  static const Color textPrimary = Color(0xFF253E4C);

  /// Secondary text color, medium emphasis
  /// #5F7A89
  static const Color textSecondary = Color(0xFF5F7A89);

  /// Tertiary text color, low emphasis
  /// #9BB1BC
  static const Color textTertiary = Color(0xFF9BB1BC);

  /// Disabled text color, lowest emphasis
  /// #C7D4DC
  static const Color textDisabled = Color(0xFFC7D4DC);

  // ============================================================================
  // BRAND - Primary brand identity
  // ============================================================================

  /// Primary brand color
  /// #253E4C
  static const Color primary = Color(0xFF253E4C);

  /// Softer primary variant
  /// #6EABC6
  static const Color primarySoft = Color(0xFF6EABC6);

  /// Subtle primary tint for backgrounds
  /// #E6F2F7
  static const Color primaryTint = Color(0xFFE6F2F7);

  /// Calm supporting brand color
  /// #BCD4CC
  static const Color calmSupport = Color(0xFFBCD4CC);

  /// Focus and interaction highlight
  /// Used for focus rings, active inputs, accessibility states
  /// #036D9A
  static const Color focus = primary;

  // ============================================================================
  // SEMANTICS - Status and feedback colors
  // ============================================================================

  /// Success state
  /// #6FB3A2
  static const Color success = Color(0xFF6FB3A2);

  /// Warning state
  /// #E0A458
  static const Color warning = Color(0xFFE0A458);

  /// Error state
  /// #D16C6C
  static const Color error = Color(0xFFD16C6C);

  /// Income or positive financial indicator
  /// #4F9E8F
  static const Color income = Color(0xFF4F9E8F);

  /// Expense or negative financial indicator
  /// Distinct from error to avoid judgment
  /// #C95F5F
  static const Color expense = Color(0xFFC95F5F);

  // ============================================================================
  // DARK THEME - Preserved values for consistency
  // ============================================================================

  /// Dark theme background
  /// #0A0A0A
  static const Color backgroundDark = Color(0xFF0A0A0A);

  /// Dark theme surface
  /// #1A1A1A
  static const Color surfaceDark = Color(0xFF1A1A1A);

  /// Dark theme primary text
  /// #F4F4F4
  static const Color textPrimaryDark = Color(0xFFF4F4F4);

  /// Dark theme secondary text
  /// #999999
  static const Color textSecondaryDark = Color(0xFF999999);

  /// Dark theme divider
  /// #2A2A2A
  static const Color dividerDark = Color(0xFF2A2A2A);

  /// Dark theme neutral variant
  /// #3A3A3A
  static const Color neutralDark = Color(0xFF3A3A3A);

  // ============================================================================
  // SHADOWS - Elevation system
  // ============================================================================

  /// Light shadow for elevation
  /// 0x0F000000
  static const Color shadowLight = Color(0x0F000000);

  /// Subtle glow used in dark theme elevation
  /// 0x1FFFFFFF
  static const Color shadowGlow = Color(0x1FFFFFFF);
}
