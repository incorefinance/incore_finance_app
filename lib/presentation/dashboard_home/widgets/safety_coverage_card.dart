import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/protection_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_formatter.dart';

/// Safety Coverage Card - Shows safety buffer coverage in months.
/// Displays: Coverage months (hero), average monthly expenses, confidence level.
/// Shows "Not enough data" when avgMonthlyExpenses <= 0.
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

  String _coverageText(AppLocalizations l10n) {
    if (avgMonthlyExpenses <= 0) {
      return l10n.safetyBufferNotEnoughData;
    }
    final months = safetyProtected / avgMonthlyExpenses;
    return l10n.safetyCoverageMonths(months.toStringAsFixed(1));
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
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            offset: const Offset(0, 6),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            l10n.safetyBufferTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.4.h),

          // Primary value: months coverage
          Text(
            _coverageText(l10n),
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (avgMonthlyExpenses > 0) ...[
            SizedBox(height: 1.h),
            Divider(color: AppColors.borderSubtle),
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
