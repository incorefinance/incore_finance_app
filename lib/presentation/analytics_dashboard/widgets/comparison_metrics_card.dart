import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/l10n/app_localizations.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors_ext.dart';

/// Month-over-month comparison metrics card
/// Displays income and expenses comparison against last month in side-by-side tiles
class ComparisonMetricsCard extends StatelessWidget {
  final double incomeChange;
  final double expenseChange;

  const ComparisonMetricsCard({
    super.key,
    required this.incomeChange,
    required this.expenseChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.18),
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
        children: [
          Text(
            l10n.monthOverMonth,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            l10n.comparedWithLastMonth,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 2.h),
          // Side-by-side metric tiles
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: l10n.income,
                  change: incomeChange,
                  iconName: 'attach_money',
                  isIncome: true,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: l10n.expenses,
                  change: expenseChange,
                  iconName: 'shopping_cart',
                  isIncome: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required double change,
    required String iconName,
    required bool isIncome,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final bool isIncrease = change >= 0;

    // Base colors for the tile (semantic: teal for income, rose for expense)
    final Color baseColor = isIncome
        ? (isDark ? context.teal400 : context.teal600)
        : (isDark ? context.rose400 : context.rose600);

    // For income: increase is good (emerald), decrease is bad (rose)
    // For expenses: increase is bad (rose), decrease is good (emerald)
    bool isGood;
    if (change == 0) {
      isGood = true;
    } else if (isIncrease) {
      isGood = isIncome;
    } else {
      isGood = !isIncome;
    }

    // Text/arrow color matches good/bad context (darker than pill bg)
    final Color trendColor = isGood
        ? (isDark ? context.emerald400 : context.emerald700)
        : (isDark ? context.rose400 : context.rose600);

    // Subtle background glow based on good/bad context
    final Color trendBgColor = isGood
        ? (isDark
            ? context.emerald900.withValues(alpha: 0.10)
            : context.emerald100.withValues(alpha: 0.50))
        : (isDark
            ? context.rose900.withValues(alpha: 0.10)
            : context.rose100.withValues(alpha: 0.50));

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: baseColor,
              size: 18,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 0.5.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: trendBgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: trendColor,
                ),
                SizedBox(width: 1.w),
                Text(
                  '${change.abs().toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: trendColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
