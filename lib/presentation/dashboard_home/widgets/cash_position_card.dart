import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';

/// Cash Position Card - Primary block showing current cash balance.
/// Visually dominant, top-most widget on Dashboard Home.
class CashPositionCard extends StatelessWidget {
  final double balance;
  final String locale;
  final String symbol;
  final String currencyCode;

  const CashPositionCard({
    super.key,
    required this.balance,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final formatted = IncoreNumberFormatter.formatMoney(
      balance.abs(),
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

    final displayValue = balance < 0 ? '- $formatted' : formatted;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            offset: const Offset(0, 8),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.cashBalance,
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            displayValue,
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
