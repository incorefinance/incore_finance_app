import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension on BuildContext providing brightness-aware color getters.
/// Use these instead of hardcoded AppColors to enable automatic dark mode switching.
///
/// Example:
/// ```dart
/// Container(
///   color: context.surfaceGlass80, // auto-switches light/dark
/// )
/// ```
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ============================================================================
  // CANVAS & SURFACE - Background colors
  // ============================================================================

  /// Main canvas background
  Color get canvasFrosted =>
      isDark ? AppColors.canvasFrostedDark : AppColors.canvasFrostedLight;

  /// 80% glass surface for cards
  Color get surfaceGlass80 =>
      isDark ? AppColors.surfaceGlass80Dark : AppColors.surfaceGlass80Light;

  /// 90% glass surface for nav
  Color get surfaceGlass90 =>
      isDark ? AppColors.surfaceGlass90Dark : AppColors.surfaceGlass90Light;

  /// Glass border
  Color get borderGlass60 =>
      isDark ? AppColors.borderGlass60Dark : AppColors.borderGlass60Light;

  /// Glass divider
  Color get dividerGlass60 =>
      isDark ? AppColors.dividerGlass60Dark : AppColors.dividerGlass60Light;

  // ============================================================================
  // SLATE - Neutral UI colors
  // ============================================================================

  /// Slate 50 - Card backgrounds (light: #f8fafc, dark: slate-800)
  Color get slate50 => isDark ? AppColors.slate50Dark : const Color(0xFFF8FAFC);

  /// Slate 100 - Button backgrounds
  Color get slate100 =>
      isDark ? AppColors.slate100Dark : const Color(0xFFF1F5F9);

  /// Slate 200 - Borders, dividers
  Color get slate200 =>
      isDark ? AppColors.slate200Dark : const Color(0xFFE2E8F0);

  /// Slate 300 - Inactive dots, subtle borders
  Color get slate300 => isDark ? AppColors.slate300Dark : AppColors.slate300;

  /// Slate 400 - Disabled text, placeholders
  Color get slate400 => isDark ? AppColors.slate400Dark : AppColors.slate400;

  /// Slate 500 - Tertiary text
  Color get slate500 => isDark ? AppColors.slate500Dark : AppColors.slate500;

  /// Slate 600 - Body text
  Color get slate600 => isDark ? AppColors.slate600Dark : AppColors.slate600;

  /// Slate 700 - Headings (dark mode)
  Color get slate700 =>
      isDark ? AppColors.slate700Dark : const Color(0xFF334155);

  /// Slate 800 - Tooltips
  Color get slate800 =>
      isDark ? AppColors.slate800Dark : const Color(0xFF1E293B);

  /// Slate 900 - Primary text
  Color get slate900 => isDark ? AppColors.slate900Dark : AppColors.slate900;

  // ============================================================================
  // BLUE - Primary/Active states
  // ============================================================================

  /// Blue 50 - Light backgrounds
  Color get blue50 => isDark ? AppColors.blue50Dark : AppColors.blueBg50;

  /// Blue 100 - Container backgrounds
  Color get blue100 =>
      isDark ? AppColors.blue100Dark : const Color(0xFFDBEAFE);

  /// Blue 300 - Borders
  Color get blue300 =>
      isDark ? AppColors.blue300Dark : const Color(0xFF93C5FD);

  /// Blue 600 - Active tabs, links, primary actions
  Color get blue600 => isDark ? AppColors.blue600Dark : AppColors.blue600;

  /// Blue 700 - Hover states
  Color get blue700 =>
      isDark ? AppColors.blue700Dark : const Color(0xFF1D4ED8);

  // ============================================================================
  // TEAL - Income colors
  // ============================================================================

  /// Teal 50 - Income background
  Color get teal50 => isDark ? AppColors.teal50Dark : AppColors.teal50;

  /// Teal 100 - Income container background
  Color get teal100 => isDark ? AppColors.teal100Dark : AppColors.teal100;

  /// Teal 200 - Income borders
  Color get teal200 =>
      isDark ? AppColors.teal200Dark : const Color(0xFF99F6E4);

  /// Teal 400 - Income accent
  Color get teal400 => isDark ? AppColors.teal600Dark : AppColors.teal400;

  /// Teal 500 - Income standard
  Color get teal500 => isDark ? AppColors.teal600Dark : AppColors.teal500;

  /// Teal 600 - Income text
  Color get teal600 => isDark ? AppColors.teal600Dark : AppColors.teal600;

  /// Teal 700 - Income bold text
  Color get teal700 => isDark ? AppColors.teal700Dark : AppColors.teal700;

  /// Teal background with 80% opacity
  Color get tealBg80 =>
      isDark ? AppColors.teal50Dark : AppColors.tealBg80;

  /// Teal border with 50% opacity
  Color get tealBorder50 =>
      isDark ? AppColors.teal200Dark : AppColors.tealBorder50;

  // ============================================================================
  // ROSE - Expense colors
  // ============================================================================

  /// Rose 50 - Expense background
  Color get rose50 => isDark ? AppColors.rose50Dark : AppColors.rose50;

  /// Rose 100 - Expense container background
  Color get rose100 => isDark ? AppColors.rose100Dark : AppColors.rose100;

  /// Rose 200 - Expense borders
  Color get rose200 => isDark ? AppColors.rose200Dark : AppColors.rose200;

  /// Rose 400 - Expense accent
  Color get rose400 => isDark ? AppColors.rose600Dark : AppColors.rose400;

  /// Rose 500 - Expense standard
  Color get rose500 => isDark ? AppColors.rose600Dark : AppColors.rose500;

  /// Rose 600 - Expense text
  Color get rose600 => isDark ? AppColors.rose600Dark : AppColors.rose600;

  /// Rose 700 - Expense bold text
  Color get rose700 => isDark ? AppColors.rose700Dark : AppColors.rose700;

  /// Rose 900 - Expense dark text
  Color get rose900 =>
      isDark ? AppColors.rose600Dark : AppColors.rose900;

  /// Rose background with 80% opacity
  Color get roseBg80 =>
      isDark ? AppColors.rose50Dark : AppColors.roseBg80;

  /// Rose border with 50% opacity
  Color get roseBorder50 =>
      isDark ? AppColors.rose200Dark : AppColors.roseBorder50;

  // ============================================================================
  // RED - Negative trends
  // ============================================================================

  /// Red 50 - Error background
  Color get red50 =>
      isDark ? AppColors.red50Dark : const Color(0xFFFEF2F2);

  /// Red 600 - Error text
  Color get red600 => isDark ? AppColors.red600Dark : AppColors.red600;

  /// Red background with 80% opacity
  Color get redBg80 =>
      isDark ? AppColors.red50Dark : AppColors.redBg80;

  // ============================================================================
  // AMBER - Warnings
  // ============================================================================

  /// Amber 50 - Warning background
  Color get amber50 => isDark ? AppColors.amber100Dark : AppColors.amber50;

  /// Amber 100 - Warning container
  Color get amber100 => isDark ? AppColors.amber100Dark : AppColors.amber100;

  /// Amber 200 - Warning borders
  Color get amber200 =>
      isDark ? AppColors.amber700Dark : AppColors.amber200;

  /// Amber 400 - Warning accent
  Color get amber400 => isDark ? AppColors.amber700Dark : AppColors.amber400;

  /// Amber 500 - Warning standard
  Color get amber500 => isDark ? AppColors.amber700Dark : AppColors.amber500;

  /// Amber 600 - Warning emphasis
  Color get amber600 => isDark ? AppColors.amber700Dark : AppColors.amber600;

  /// Amber 700 - Warning text
  Color get amber700 => isDark ? AppColors.amber700Dark : AppColors.amber700;

  /// Amber 800 - Warning dark
  Color get amber800 => isDark ? AppColors.amber700Dark : AppColors.amber800;

  /// Amber 900 - Warning darkest
  Color get amber900 => isDark ? AppColors.amber700Dark : AppColors.amber900;

  /// Amber 950 - Warning extreme
  Color get amber950 => isDark ? AppColors.amber700Dark : AppColors.amber950;

  // ============================================================================
  // ORANGE - Watch card gradients
  // ============================================================================

  /// Orange 50 - Light background
  Color get orange50 =>
      isDark ? AppColors.amber100Dark : AppColors.orange50;

  /// Orange 950 - Dark gradient
  Color get orange950 =>
      isDark ? AppColors.amber700Dark : AppColors.orange950;

  // ============================================================================
  // EMERALD - Success/Healthy states
  // ============================================================================

  /// Emerald 100 - Success background
  Color get emerald100 =>
      isDark ? AppColors.emerald100Dark : AppColors.emerald100;

  /// Emerald 400 - Success accent
  Color get emerald400 =>
      isDark ? AppColors.emerald700Dark : AppColors.emerald400;

  /// Emerald 700 - Success text
  Color get emerald700 =>
      isDark ? AppColors.emerald700Dark : AppColors.emerald700;

  /// Emerald 900 - Success dark
  Color get emerald900 =>
      isDark ? AppColors.emerald700Dark : AppColors.emerald900;

  // ============================================================================
  // SEMANTIC ALIASES - For clearer intent
  // ============================================================================

  /// Income color (teal)
  Color get income => isDark ? AppColors.teal600Dark : AppColors.income;

  /// Income background
  Color get incomeBg => isDark ? AppColors.teal50Dark : AppColors.incomeBg;

  /// Expense color (rose)
  Color get expense => isDark ? AppColors.rose600Dark : AppColors.expense;

  /// Expense background
  Color get expenseBg => isDark ? AppColors.rose50Dark : AppColors.expenseBg;

  /// Primary text color
  Color get textPrimary =>
      isDark ? AppColors.slate900Dark : AppColors.textPrimary;

  /// Secondary text color
  Color get textSecondary =>
      isDark ? AppColors.slate600Dark : AppColors.textSecondary;

  /// Tertiary text color
  Color get textTertiary =>
      isDark ? AppColors.slate500Dark : AppColors.textTertiary;

  /// Disabled text color
  Color get textDisabled =>
      isDark ? AppColors.slate400Dark : AppColors.textDisabled;

  /// Subtle border color
  Color get borderSubtle =>
      isDark ? AppColors.slate200Dark : AppColors.borderSubtle;

  /// Divider color
  Color get divider => isDark ? AppColors.slate200Dark : AppColors.divider;

  /// Surface color (cards, dialogs)
  Color get surface => isDark ? AppColors.slate50Dark : AppColors.surface;

  /// Primary brand color
  Color get primary => isDark ? AppColors.blue600Dark : AppColors.primary;

  /// Primary soft color
  Color get primarySoft =>
      isDark ? AppColors.blue600Dark : AppColors.primarySoft;

  /// Primary tint color
  Color get primaryTint =>
      isDark ? AppColors.blue50Dark : AppColors.primaryTint;

  /// Success color
  Color get success => isDark ? AppColors.emerald700Dark : AppColors.success;

  /// Warning color
  Color get warning => isDark ? AppColors.amber700Dark : AppColors.warning;

  /// Error color
  Color get error => isDark ? AppColors.red600Dark : AppColors.error;

  /// Badge background
  Color get badgeBg80 =>
      isDark ? AppColors.slate100Dark : AppColors.badgeBg80;

  /// Card shadow color
  Color get shadowCard =>
      isDark ? AppColors.shadowGlow : AppColors.shadowCardLight;

  /// Navigation shadow color
  Color get shadowNav =>
      isDark ? AppColors.shadowGlow : AppColors.shadowNavLight;

  /// FAB shadow color
  Color get shadowFab =>
      isDark ? AppColors.shadowGlow : AppColors.shadowFabLight;
}
