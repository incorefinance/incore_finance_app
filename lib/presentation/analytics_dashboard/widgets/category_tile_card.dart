import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../theme/app_colors_ext.dart';

/// Generalized category tile card for income/expense breakdown.
/// Based on ExpenseCategoryCard but works for both income and expenses.
class CategoryTileCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final double percentage;
  final String locale;
  final String symbol;
  final String currencyCode;
  final Color accentColor;
  final bool isOthersCard;
  final VoidCallback? onTap;

  const CategoryTileCard({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    required this.accentColor,
    this.isOthersCard = false,
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

    final percentRounded = percentage.isFinite ? percentage.round() : 0;
    final percentLabel = '$percentRounded%';

    final cardChild = Container(
      padding: EdgeInsets.all(3.w),
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
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: isOthersCard
                  ? context.borderSubtle.withValues(alpha: 0.6)
                  : accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: CustomIconWidget(
              iconName: categoryIcon,
              color: isOthersCard ? context.textSecondary : accentColor,
              size: 22,
            ),
          ),
          SizedBox(height: 1.0.h),
          // Category name
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              categoryName,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          SizedBox(height: 0.5.h),
          // Amount
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatted,
              style: theme.textTheme.titleMedium?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 0.3.h),
          // Percentage label
          Text(
            percentLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: cardChild,
      ),
    );
  }
}
