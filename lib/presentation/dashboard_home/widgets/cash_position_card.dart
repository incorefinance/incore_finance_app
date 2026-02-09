import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceGlass80Light,
              borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
              border: Border.all(
                color: AppColors.borderGlass60Light,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.cashBalance,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayValue,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
