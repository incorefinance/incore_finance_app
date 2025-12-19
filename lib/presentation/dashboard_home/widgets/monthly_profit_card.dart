import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';

/// Monthly profit overview card widget
/// Displays current month's profit/loss with percentage change
class MonthlyProfitCard extends StatelessWidget {
  final double profit;
  final double percentageChange;
  final bool isProfit;
  final String locale;
  final String symbol;

  const MonthlyProfitCard({
    super.key,
    required this.profit,
    required this.percentageChange,
    required this.isProfit,
    required this.locale,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formatted = IncoreNumberFormatter.formatAmountWithCurrency(
      profit.abs(),
      locale: locale,
      symbol: symbol,
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: 20.h,
        maxHeight: 30.h,
      ),
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // ✅ Minimal fix: shrink-wrap + no spaceBetween
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Profit',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
                decoration: BoxDecoration(
                  color: isProfit
                      ? AppTheme.successGreen.withValues(alpha: 0.2)
                      : AppTheme.errorRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: isProfit ? 'trending_up' : 'trending_down',
                      color:
                          isProfit ? AppTheme.successGreen : AppTheme.errorRed,
                      size: 16,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      '${percentageChange.abs().toStringAsFixed(1)}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: isProfit
                            ? AppTheme.successGreen
                            : AppTheme.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 1.8.h),
          Text(
            formatted,
            style: theme.textTheme.displaySmall?.copyWith(
              color: const Color(0XFFFFFFFF),
              fontFamily: 'Inter_regular',
              fontSize: 25,
              fontWeight: FontWeight.w700,
              height: 1.22,
              letterSpacing: 0,
              wordSpacing: 0,
            ),
          ),
          SizedBox(height: 0.8.h),
          Text(
            isProfit ? 'Net Profit' : 'Net Loss',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
