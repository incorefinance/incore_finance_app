import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Month-over-month comparison metrics card
/// Displays income, expenses, and savings comparison
class ComparisonMetricsCard extends StatelessWidget {
  final double incomeChange;
  final double expenseChange;
  final double savingsChange;

  const ComparisonMetricsCard({
    super.key,
    required this.incomeChange,
    required this.expenseChange,
    required this.savingsChange,
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
          SizedBox(height: 2.h),
          _buildMetricRow(
            context,
            'Income',
            incomeChange,
            'attach_money',
          ),
          SizedBox(height: 1.5.h),
          _buildMetricRow(
            context,
            'Expenses',
            expenseChange,
            'shopping_cart',
          ),
          SizedBox(height: 1.5.h),
          _buildMetricRow(
            context,
            'Savings',
            savingsChange,
            'savings',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    double change,
    String iconName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPositive = change >= 0;

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
            color: colorScheme.primary,
            size: 20,
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
                  CustomIconWidget(
                    iconName: isPositive ? 'arrow_upward' : 'arrow_downward',
                    color:
                        isPositive ? AppTheme.successGreen : AppTheme.errorRed,
                    size: 14,
                  ),
                  SizedBox(width: 1.w),
                  Text(
                    '${change.abs().toStringAsFixed(1)}%',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isPositive
                          ? AppTheme.successGreen
                          : AppTheme.errorRed,
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
