import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';

class MonthlyProfitCard extends StatelessWidget {
  final double profit;
  final double percentageChange;
  final bool isProfit;
  final String locale;
  final String symbol;
  final String currencyCode;

  const MonthlyProfitCard({
    super.key,
    required this.profit,
    required this.percentageChange,
    required this.isProfit,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final formatted = IncoreNumberFormatter.formatMoney(
      profit.abs(),
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

    // ✅ Correct up/down color logic: based on percentageChange direction.
    final bool isUp = percentageChange >= 0;
    final Color trendColor = isUp ? AppColors.success : AppColors.error;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // ✅ Profit + This month hierarchy
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profit, // was l10n.monthlyProfit
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    l10n.thisMonth, // new: explicit timeframe
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // ✅ Explicit chip label: Up/Down vs last month
              _TrendChip(
                value: percentageChange,
                color: trendColor,
              ),
            ],
          ),
          SizedBox(height: 1.4.h),
          Text(
            formatted,
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),

          // ✅ Removed redundant "Net Profit / Net Loss" line
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final double value;
  final Color color;

  const _TrendChip({
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final bool isUp = value >= 0;
    final String directionText = isUp ? l10n.up : l10n.down;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: color,
          ),
          SizedBox(width: 1.w),
          Text(
            '$directionText ${value.abs().toStringAsFixed(1)}% ${l10n.vsLastMonth}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
