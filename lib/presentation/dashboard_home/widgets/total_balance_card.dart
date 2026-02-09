import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/number_formatter.dart';

/// Total Balance Card - Primary block showing current balance with income/expenses breakdown.
/// Replaces CashPositionCard with a more comprehensive view.
class TotalBalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expenses;
  final String locale;
  final String symbol;
  final String currencyCode;
  final VoidCallback? onWalletPressed;

  const TotalBalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
    this.onWalletPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final formattedBalance = IncoreNumberFormatter.formatMoney(
      balance.abs(),
      locale: locale,
      symbol: symbol,
      currencyCode: currencyCode,
    );

    final displayBalance = balance < 0 ? '- $formattedBalance' : formattedBalance;

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
                // Header row: Title + Wallet icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.totalBalance,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // Always render wallet icon; only interactive if callback provided
                    _buildWalletIcon(),
                  ],
                ),
                const SizedBox(height: 8),
                // Balance amount
                Text(
                  displayBalance,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                // Currency code
                Text(
                  currencyCode,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                // Income/Expenses pills row
                Row(
                  children: [
                    // Income pill
                    Expanded(
                      child: _BalancePill(
                        label: l10n.income,
                        amount: formattedIncome,
                        backgroundColor: AppColors.tealBg80,
                        borderColor: AppColors.tealBorder50,
                        textColor: AppColors.teal600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Expenses pill
                    Expanded(
                      child: _BalancePill(
                        label: l10n.expense,
                        amount: formattedExpenses,
                        backgroundColor: AppColors.roseBg80,
                        borderColor: AppColors.roseBorder50,
                        textColor: AppColors.rose600,
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

  /// Wallet icon - always rendered; interactive only if callback provided.
  Widget _buildWalletIcon() {
    final iconContainer = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.blueBg50,
        borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
      ),
      child: Icon(
        Icons.account_balance_wallet_outlined,
        size: 24,
        color: AppColors.blue600,
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

/// Internal pill widget for Income/Expenses display.
/// No arrow icons per design spec.
class _BalancePill extends StatelessWidget {
  final String label;
  final String amount;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _BalancePill({
    required this.label,
    required this.amount,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
