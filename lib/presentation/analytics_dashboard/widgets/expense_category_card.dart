import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../theme/app_colors_ext.dart';

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

  void _defaultTap(BuildContext context, String formatted, String percentLabel) {
    showDialog<void>(
      context: context,
      builder: (_) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          title: Text(
            categoryName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatted,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: context.expense,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 0.8.h),
              Text(
                percentLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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

    final percentRounded = percentage.isFinite ? percentage.round() : 0;
    final percentLabel = '$percentRounded% of expenses';

    final cardChild = Container(
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: context.primaryTint,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: CustomIconWidget(
              iconName: categoryIcon,
              color: context.primarySoft,
              size: 22,
            ),
          ),
          SizedBox(height: 1.0.h),

          // ✅ amount will never overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatted,
              style: theme.textTheme.titleMedium?.copyWith(
                color: context.expense,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          SizedBox(height: 0.5.h),

          // ✅ label will never overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              percentLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: context.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap ??
            () {
              _defaultTap(context, formatted, percentLabel);
            },
        child: cardChild,
      ),
    );
  }
}
