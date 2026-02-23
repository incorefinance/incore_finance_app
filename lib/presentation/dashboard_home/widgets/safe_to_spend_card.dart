import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_formatter.dart';

/// Safe to Spend Card - Primary dashboard card showing available funds.
/// Displays: Safe to Spend (hero), Balance (secondary), and a 2x2 grid:
/// Row 1: Income | Expense (performance metrics)
/// Row 2: Tax reserve | Safety buffer (protection metrics)
class SafeToSpendCard extends StatelessWidget {
  final double safeToSpend;
  final double balance;
  final double income;
  final double expenses;
  final double taxReserve;
  final double safetyBuffer;
  final String locale;
  final String symbol;
  final String currencyCode;
  final VoidCallback? onWalletPressed;

  const SafeToSpendCard({
    super.key,
    required this.safeToSpend,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.taxReserve,
    required this.safetyBuffer,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    this.onWalletPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final formattedSafeToSpend = IncoreNumberFormatter.formatMoney(
      safeToSpend.abs(),
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );
    final displaySafeToSpend =
        safeToSpend < 0 ? '- $formattedSafeToSpend' : formattedSafeToSpend;

    final formattedBalance = IncoreNumberFormatter.formatMoney(
      balance.abs(),
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );
    final displayBalance =
        balance < 0 ? '- $formattedBalance' : formattedBalance;

    final formattedIncome = IncoreNumberFormatter.formatMoney(
      income,
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );
    final formattedExpenses = IncoreNumberFormatter.formatMoney(
      expenses,
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );
    final formattedTax = IncoreNumberFormatter.formatMoney(
      taxReserve,
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );
    final formattedSafety = IncoreNumberFormatter.formatMoney(
      safetyBuffer,
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

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
                // Header row: Title + Wallet icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.safeToSpend,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: context.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _buildWalletIcon(context),
                  ],
                ),
                const SizedBox(height: 4),

                // Hero: Safe to Spend amount
                Text(
                  displaySafeToSpend,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: context.slate900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary: Balance line
                Text(
                  '${l10n.balance} $displayBalance',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // 2x2 Grid: Performance (Income/Expense) then Protection (Tax/Safety)
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: l10n.income,
                        amount: formattedIncome,
                        backgroundColor: context.tealBg80,
                        borderColor: context.tealBorder50,
                        textColor: context.teal600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: l10n.expense,
                        amount: formattedExpenses,
                        backgroundColor: context.roseBg80,
                        borderColor: context.roseBorder50,
                        textColor: context.rose600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: l10n.taxReserve,
                        amount: formattedTax,
                        backgroundColor: context.amber50,
                        borderColor: context.amber200,
                        textColor: context.amber700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricTile(
                        label: l10n.safetyBufferTitle,
                        amount: formattedSafety,
                        backgroundColor: context.blue50,
                        borderColor: context.borderSubtle,
                        textColor: context.blue600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletIcon(BuildContext context) {
    final iconContainer = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: context.blue50,
        borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
      ),
      child: Icon(
        Icons.account_balance_wallet_outlined,
        size: 24,
        color: context.blue600,
      ),
    );

    if (onWalletPressed != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onWalletPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
          child: iconContainer,
        ),
      );
    }

    return iconContainer;
  }
}

/// Internal metric tile widget for the 2x2 grid.
class _MetricTile extends StatelessWidget {
  final String label;
  final String amount;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _MetricTile({
    required this.label,
    required this.amount,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
