import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/utils/number_formatter.dart';
import 'package:incore_finance/l10n/app_localizations.dart';
import 'package:incore_finance/theme/app_colors_ext.dart';

class HorizontalCategoryBreakdownWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String locale;
  final String symbol;
  final Color? accentColor;
  final String currencyCode;

  const HorizontalCategoryBreakdownWidget({
    super.key,
    required this.data,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (data.isEmpty) {
      return Text(
        l10n.noDataYet,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final total = data.fold<double>(
      0.0,
      (sum, item) => sum + (item['amount'] as num).toDouble(),
    );

    return Column(
      children: List.generate(data.length, (index) {
        final item = data[index];
        final label = item['label'] as String;
        final amount = (item['amount'] as num).toDouble();
        final share = total == 0.0 ? 0.0 : (amount / total);

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 0.6.h),
          child: _BreakdownRow(
            label: label,
            amount: amount,
            share: share,
            locale: locale,
            symbol: symbol,
            currencyCode: currencyCode,
            accentColor: accentColor,
            isTop: index == 0,
          ),
        );
      }),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final double amount;
  final double share;
  final String locale;
  final String symbol;
  final String currencyCode;
  final Color? accentColor;
  final bool isTop;

  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.share,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    required this.isTop,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Keep your API, but make the fill more saturated (less washed out),
    // similar to the updated bar chart.
    final base = accentColor ?? context.primary;

    // More contrast between top item and others, without looking neon.
    final fillColor = isTop
        ? base.withValues(alpha: 0.70)
        : base.withValues(alpha: 0.52);

    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: isTop ? FontWeight.w700 : FontWeight.w600,
      color: context.textPrimary,
    );

    final formattedAmount = IncoreNumberFormatter.formatMoney(
      amount,
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

    final progressValue = share.clamp(0.0, 1.0).toDouble();

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: isTop ? 11 : 9,
              // Slightly lighter track so fill pops more.
              backgroundColor: context.borderSubtle.withValues(alpha: 0.55),
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(
            formattedAmount,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
