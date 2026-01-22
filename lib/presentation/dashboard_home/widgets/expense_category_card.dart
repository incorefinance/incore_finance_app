import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../theme/app_colors.dart';

class ExpenseCategoryCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final double percentage;
  final String locale;
  final String symbol;
  final String currencyCode;
  final VoidCallback? onTap;

  const ExpenseCategoryCard({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formatted = IncoreNumberFormatter.formatMoney(
      amount.abs(),
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

    return Container(
      width: 28.w,
      constraints: BoxConstraints(
        minHeight: 16.h,
        maxHeight: 20.h,
      ),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // ✅ Minimal fix: shrink-wrap + no spaceBetween
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: CustomIconWidget(
                iconName: categoryIcon,
                color: AppColors.primarySoft,
                size: 20,
              ),
            ),
            SizedBox(height: 0.8.h),
            Text(
              categoryName,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.3.h),
            Text(
              formatted,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.3.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
