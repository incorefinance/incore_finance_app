import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/l10n/app_localizations.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors.dart';

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
                  positiveIsGood: true,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricTile(
                  context,
                  label: l10n.expenses,
                  change: expenseChange,
                  iconName: 'shopping_cart',
                  positiveIsGood: false,
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
    required bool positiveIsGood,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isIncrease = change >= 0;

    // For income: increase is good.
    // For expenses: increase is bad, decrease is good.
    bool isGood;
    if (change == 0) {
      isGood = true;
    } else if (isIncrease) {
      isGood = positiveIsGood;
    } else {
      isGood = !positiveIsGood;
    }

    final Color trendColor = isGood ? AppColors.success : AppColors.error;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              color: trendColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: trendColor,
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
          Row(
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
        ],
      ),
    );
  }
}
