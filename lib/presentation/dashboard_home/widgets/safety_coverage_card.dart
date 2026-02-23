import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/protection_snapshot.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_formatter.dart';

/// Safety Coverage Card - Shows safety buffer coverage in days/months.
/// Displays: Coverage (hero), explanation, average monthly expenses, confidence level.
/// Shows "Not enough data" when avgMonthlyExpenses <= 0.
///
/// Coverage display rules (1 month = 30 days):
/// - If < 30 days: show "{days} days covered"
/// - If >= 30 days and < 360 days: show "{months} month(s) {days} days covered"
/// - If >= 360 days (12 months): show "{months} months covered"
class SafetyCoverageCard extends StatelessWidget {
  final double safetyProtected;
  final double avgMonthlyExpenses;
  final ConfidenceLevel confidence;
  final String locale;
  final String symbol;
  final String currencyCode;

  const SafetyCoverageCard({
    super.key,
    required this.safetyProtected,
    required this.avgMonthlyExpenses,
    required this.confidence,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
  });

  /// Formats coverage as days/months based on the rules:
  /// - < 30 days: "{days} days covered"
  /// - >= 30 days, < 360 days: "{months} month(s) {days} days covered"
  /// - >= 360 days: "{months} months covered"
  String _coverageText(AppLocalizations l10n) {
    if (avgMonthlyExpenses <= 0) {
      return l10n.safetyBufferNotEnoughData;
    }

    final coverageRatio = safetyProtected / avgMonthlyExpenses;
    final totalDays = (coverageRatio * 30).round();

    if (totalDays < 30) {
      // Less than 1 month: show days only
      return l10n.safetyCoverageDays(totalDays);
    }

    final months = totalDays ~/ 30;
    final remainingDays = totalDays % 30;

    if (totalDays >= 360) {
      // 12+ months: show months only (always plural at this point)
      return l10n.safetyCoverageMonthsOnly(months);
    }

    if (remainingDays == 0) {
      // Exact months - use singular or plural
      if (months == 1) {
        return l10n.safetyCoverageMonthOnly;
      }
      return l10n.safetyCoverageMonthsOnly(months);
    }

    // Months and days
    if (months == 1) {
      return l10n.safetyCoverageMonthDays(months, remainingDays);
    } else {
      return l10n.safetyCoverageMonthsDays(months, remainingDays);
    }
  }

  String _confidenceText(AppLocalizations l10n) {
    switch (confidence) {
      case ConfidenceLevel.low:
        return l10n.confidenceLow;
      case ConfidenceLevel.medium:
        return l10n.confidenceMedium;
      case ConfidenceLevel.high:
        return l10n.confidenceHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final formattedAvgExpenses = IncoreNumberFormatter.formatMoney(
      avgMonthlyExpenses,
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: context.surfaceGlass80,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: context.borderGlass60,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title (matches carousel card styling)
          Text(
            l10n.safetyBufferTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: context.slate500,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.4.h),

          // Primary value: coverage in days/months
          Text(
            _coverageText(l10n),
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (avgMonthlyExpenses > 0) ...[
            SizedBox(height: 0.8.h),

            // Explanation text (matches carousel card styling)
            Text(
              l10n.safetyCoverageExplanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.slate400,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
              ),
            ),

            SizedBox(height: 1.h),
            Divider(color: context.borderSubtle),
            SizedBox(height: 1.h),

            // Based on avg expenses
            Text(
              l10n.safetyCoverageBasedOn(formattedAvgExpenses),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),

            SizedBox(height: 0.5.h),

            // Confidence level
            Text(
              _confidenceText(l10n),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
