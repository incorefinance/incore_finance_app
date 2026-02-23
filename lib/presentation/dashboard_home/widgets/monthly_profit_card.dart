import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../theme/app_theme.dart';

class MonthlyProfitCard extends StatelessWidget {
  final double profit;
  final double currentMonthIncome;
  final double percentageChange;
  final double prevMonthProfit;
  final bool prevMonthHasData;
  final bool isProfit;
  final String locale;
  final String symbol;
  final String currencyCode;

  const MonthlyProfitCard({
    super.key,
    required this.profit,
    required this.currentMonthIncome,
    required this.percentageChange,
    required this.prevMonthProfit,
    required this.prevMonthHasData,
    required this.isProfit,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
  });

  /// Determines if the trend badge should be shown.
  /// Returns true only when the comparison is meaningful.
  bool _shouldShowTrendBadge() {
    // Case C: Last month has no data - hide badge
    if (!prevMonthHasData) {
      return false;
    }

    // Case A & B: prevProfit == 0 - hide badge
    if (prevMonthProfit == 0) {
      return false;
    }

    // Case D: Loss to profit or profit to loss - hide badge
    // prevProfit < 0 and currentProfit > 0
    // prevProfit > 0 and currentProfit < 0
    if ((prevMonthProfit < 0 && profit > 0) ||
        (prevMonthProfit > 0 && profit < 0)) {
      return false;
    }

    // Case E: Normal case - both positive or both negative
    // Show badge when prevProfit > 0 and currentProfit >= 0
    // Also allow both negative for consistency
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final formatted = IncoreNumberFormatter.formatMoney(
      profit.abs(),
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

    // Up/down color logic: based on percentageChange direction.
    final bool isUp = percentageChange >= 0;

    final showBadge = _shouldShowTrendBadge();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        boxShadow: AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.surfaceGlass80,
              borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
              border: Border.all(
                color: context.borderGlass60,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profit + This month hierarchy
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.profit,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: context.slate500,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.thisMonth,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: context.slate400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Conditionally show trend chip
                    if (showBadge)
                      _TrendChip(
                        value: percentageChange,
                        isUp: isUp,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  formatted,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: context.slate900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                // Profit percentage (only when income > 0)
                if (currentMonthIncome > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.profitPercent(
                      ((profit / currentMonthIncome) * 100).toStringAsFixed(1),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.slate400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final double value;
  final bool isUp;

  const _TrendChip({
    required this.value,
    required this.isUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final String directionText = isUp ? l10n.up : l10n.down;
    final chipColor = isUp ? context.teal600 : context.red600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isUp ? context.tealBg80 : context.redBg80,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isUp ? context.tealBorder50 : context.roseBorder50,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.trending_up : Icons.trending_down,
            size: 16,
            color: chipColor,
          ),
          const SizedBox(width: 4),
          Text(
            '$directionText ${value.abs().toStringAsFixed(1)}% ${l10n.vsLastMonth}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
