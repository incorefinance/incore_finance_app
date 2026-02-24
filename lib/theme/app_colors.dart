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
  /// #2563EB
  static const Color primary = Color(0xFF2563EB);

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

  /// Income financial indicator - uses teal palette
  static const Color income = teal500;
  static const Color incomeLight = teal600; // For dark mode text
  static const Color incomeBg = teal50;
  static const Color incomeBg80 = Color.fromRGBO(240, 253, 250, 0.80);

  /// Expense financial indicator - uses rose palette
  static const Color expense = rose500;
  static const Color expenseLight = rose600; // For dark mode text
  static const Color expenseBg = rose50;
  static const Color expenseBg80 = Color.fromRGBO(255, 241, 242, 0.80);

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

  // ============================================================================
  // FROSTED GLASS DESIGN SYSTEM - New tokens for iOS-style glassmorphism
  // ============================================================================

  // ─── Neutrals and Surfaces (Light) ───────────────────────────────────────

  /// Frosted canvas background for light mode
  static const Color canvasFrostedLight = Color(0xFFF9FAFB);

  /// 80% white glass surface
  static const Color surfaceGlass80Light = Color(0xCCFFFFFF);

  /// 90% white glass surface (for nav)
  static const Color surfaceGlass90Light = Color(0xE6FFFFFF);

  /// 60% white glass border
  static const Color borderGlass60Light = Color.fromRGBO(255, 255, 255, 0.60);

  /// 60% slate divider for glass surfaces
  static const Color dividerGlass60Light = Color.fromRGBO(226, 232, 240, 0.60);

  // ─── Slate Text Scale ────────────────────────────────────────────────────

  /// Slate 900 - Primary text
  static const Color slate900 = Color(0xFF0F172A);

  /// Slate 600 - Secondary text
  static const Color slate600 = Color(0xFF475569);

  /// Slate 500 - Tertiary text
  static const Color slate500 = Color(0xFF64748B);

  /// Slate 400 - Disabled/inactive
  static const Color slate400 = Color(0xFF94A3B8);

  /// Slate 300 - Dark mode secondary text
  static const Color slate300 = Color(0xFFCBD5E1);

  // ─── Teal Accent (Income) ────────────────────────────────────────────────

  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal100 = Color(0xFFCCFBF1);
  static const Color teal400 = Color(0xFF2DD4BF);
  static const Color teal500 = Color(0xFF14B8A6);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color teal700 = Color(0xFF0F766E);
  static const Color tealBg80 = Color.fromRGBO(240, 253, 250, 0.80);
  static const Color tealBorder50 = Color.fromRGBO(204, 251, 241, 0.50);

  // ─── Rose Accent (Expense) ─────────────────────────────────────────────────

  static const Color rose50 = Color(0xFFFFF1F2);
  static const Color rose100 = Color(0xFFFFE4E6);
  static const Color rose200 = Color(0xFFFECDD3);
  static const Color rose400 = Color(0xFFFB7185);
  static const Color rose500 = Color(0xFFF43F5E);
  static const Color rose600 = Color(0xFFE11D48);
  static const Color rose700 = Color(0xFFBE123C);
  static const Color rose900 = Color(0xFF881337);
  static const Color roseBg80 = Color.fromRGBO(255, 241, 242, 0.80);
  static const Color roseBorder50 = Color.fromRGBO(255, 228, 230, 0.50);

  // ─── Emerald (Healthy Badge) ───────────────────────────────────────────────

  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald900 = Color(0xFF064E3B);

  // ─── Amber (Watch Badge) ───────────────────────────────────────────────────

  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);
  static const Color amber950 = Color(0xFF451A03);

  // ─── Orange (Watch Card Gradient) ─────────────────────────────────────────

  static const Color orange50 = Color(0xFFFFF7ED);
  static const Color orange950 = Color(0xFF431407);

  // ─── Red (Negative Trend) ────────────────────────────────────────────────

  static const Color red600 = Color(0xFFDC2626);
  static const Color redBg80 = Color.fromRGBO(254, 242, 242, 0.80);

  // ─── Blue Accent ─────────────────────────────────────────────────────────

  static const Color blue600 = Color(0xFF2563EB);
  static const Color blueBg50 = Color(0xFFEFF6FF);

  // ─── Neutral Badge ───────────────────────────────────────────────────────

  static const Color badgeBg80 = Color.fromRGBO(241, 245, 249, 0.80);

  // ─── Shadow Colors (Frosted System) ──────────────────────────────────────

  /// Card shadow for frosted design
  static const Color shadowCardLight = Color.fromRGBO(0, 0, 0, 0.08);

  /// Nav bar shadow
  static const Color shadowNavLight = Color.fromRGBO(0, 0, 0, 0.12);

  /// FAB shadow
  static const Color shadowFabLight = Color.fromRGBO(0, 0, 0, 0.25);

  // ─── Frosted Glass (Dark Mode) ─────────────────────────────────────────────

  static const Color canvasFrostedDark = Color(0xFF0F172A);
  static const Color surfaceGlass80Dark = Color.fromRGBO(15, 23, 42, 0.80);
  static const Color surfaceGlass90Dark = Color.fromRGBO(15, 23, 42, 0.90);
  static const Color borderGlass60Dark = Color.fromRGBO(30, 41, 59, 0.60);
  static const Color dividerGlass60Dark = Color.fromRGBO(51, 65, 85, 0.60);

  // ─── Dark Mode Color Tokens ────────────────────────────────────────────────

  // Blue (Primary/Active States) - Dark Mode
  static const Color blue50Dark = Color.fromRGBO(23, 37, 84, 0.2);       // blue-950/20
  static const Color blue100Dark = Color.fromRGBO(30, 58, 138, 0.3);    // blue-900/30
  static const Color blue300Dark = Color(0xFF1D4ED8);                    // blue-700
  static const Color blue600Dark = Color(0xFF60A5FA);                    // blue-400 (active tabs, links)
  static const Color blue700Dark = Color(0xFF93C5FD);                    // blue-300 (hover)

  // Teal (Income) - Dark Mode
  static const Color teal50Dark = Color.fromRGBO(17, 94, 89, 0.3);      // teal-900/30
  static const Color teal100Dark = Color.fromRGBO(51, 65, 85, 0.8);     // slate-700/80
  static const Color teal200Dark = Color(0xFF0F766E);                    // teal-700 (borders)
  static const Color teal600Dark = Color(0xFF2DD4BF);                    // teal-400 (income text)
  static const Color teal700Dark = Color(0xFF2DD4BF);                    // teal-400 (bold text)

  // Rose (Expenses) - Dark Mode
  static const Color rose50Dark = Color.fromRGBO(136, 19, 55, 0.3);     // rose-900/30
  static const Color rose100Dark = Color.fromRGBO(51, 65, 85, 0.8);     // slate-700/80
  static const Color rose200Dark = Color(0xFFBE123C);                    // rose-700 (borders)
  static const Color rose600Dark = Color(0xFFFB7185);                    // rose-400 (expense text)
  static const Color rose700Dark = Color(0xFFFB7185);                    // rose-400 (bold text)

  // Red (Negative Trends) - Dark Mode
  static const Color red50Dark = Color.fromRGBO(127, 29, 29, 0.3);      // red-900/30
  static const Color red600Dark = Color(0xFFF87171);                     // red-400

  // Slate (Neutral UI) - Dark Mode
  static const Color slate50Dark = Color(0xFF1E293B);                    // slate-800 (card bg)
  static const Color slate100Dark = Color(0xFF1E293B);                   // slate-800 (button bg)
  static const Color slate200Dark = Color(0xFF334155);                   // slate-700 (borders)
  static const Color slate300Dark = Color(0xFF475569);                   // slate-600 (inactive dots)
  static const Color slate400Dark = Color(0xFF64748B);                   // slate-500 (secondary text)
  static const Color slate500Dark = Color(0xFF94A3B8);                   // slate-400 (tertiary text)
  static const Color slate600Dark = Color(0xFF94A3B8);                   // slate-400 (body text)
  static const Color slate700Dark = Color(0xFFCBD5E1);                   // slate-300 (headings)
  static const Color slate800Dark = Color(0xFF334155);                   // slate-700 (tooltips)
  static const Color slate900Dark = Color(0xFFFFFFFF);                   // white (primary text)

  // Amber (Warnings) - Dark Mode
  static const Color amber100Dark = Color.fromRGBO(120, 53, 15, 0.3);   // amber-900/30
  static const Color amber700Dark = Color(0xFFFBBF24);                   // amber-400

  // Emerald (Success) - Dark Mode
  static const Color emerald100Dark = Color.fromRGBO(6, 78, 59, 0.3);   // emerald-900/30
  static const Color emerald700Dark = Color(0xFF34D399);                 // emerald-400
}
