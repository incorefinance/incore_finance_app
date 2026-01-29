import 'dart:ui';

import '../../../theme/app_colors.dart';

/// Standardized chart styling constants for visual consistency across all analytics charts.
abstract final class AnalyticsChartConstants {
  // Tooltip styling
  static const double tooltipAlpha = 0.90;
  static const double tooltipRadius = 10.0;

  /// Returns standardized tooltip background color.
  static Color tooltipBackground() =>
      AppColors.primary.withValues(alpha: tooltipAlpha);

  // Grid line styling
  static const double gridLineAlpha = 0.15;

  // Card styling (matching CashBalanceChart pattern)
  static const double cardBorderAlpha = 0.18;
  static const double cardShadowAlpha = 0.06;
  static const double cardShadowBlurRadius = 18.0;
  static const Offset cardShadowOffset = Offset(0, 6);
}
