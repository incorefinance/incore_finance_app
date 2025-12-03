import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Month-over-month comparison metrics card
/// Displays income and expenses comparison against last month
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

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Month-over-Month',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Compared with last month',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 2.h),
          _buildMetricRow(
            context,
            label: 'Income',
            change: incomeChange,
            iconName: 'attach_money',
            // For income, an increase is good
            positiveIsGood: true,
          ),
          SizedBox(height: 1.5.h),
          _buildMetricRow(
            context,
            label: 'Expenses',
            change: expenseChange,
            iconName: 'shopping_cart',
            // For expenses, a decrease is good
            positiveIsGood: false,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
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

    final Color trendColor =
        isGood ? AppTheme.successGreen : AppTheme.errorRed;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: CustomIconWidget(
            iconName: iconName,
            color: trendColor,
            size: 16,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 0.3.h),
              Row(
                children: [
                  Icon(
                    isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: trendColor,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${change.abs().toStringAsFixed(1)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
