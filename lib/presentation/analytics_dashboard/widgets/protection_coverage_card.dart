import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/protection_snapshot.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

/// Protection Coverage Card for Analytics dashboard.
///
/// Displays:
/// - Protection totals (tax + safety reserves)
/// - Coverage in months (based on avg monthly expenses)
/// - Overspend warning if safeToSpend < 0
///
/// Uses frosted glass card styling consistent with Analytics.
class ProtectionCoverageCard extends StatelessWidget {
  final double taxProtected;
  final double safetyProtected;
  final double safeToSpend;
  final double avgMonthlyExpenses;
  final int monthsUsed;
  final ConfidenceLevel confidence;
  final String locale;
  final String symbol;
  final String currencyCode;

  const ProtectionCoverageCard({
    super.key,
    required this.taxProtected,
    required this.safetyProtected,
    required this.safeToSpend,
    required this.avgMonthlyExpenses,
    required this.monthsUsed,
    required this.confidence,
    required this.locale,
    required this.symbol,
    required this.currencyCode,
  });

  double get _totalProtected => taxProtected + safetyProtected;

  bool get _hasEnoughData => avgMonthlyExpenses > 0 && monthsUsed > 0;

  double? get _coverageMonths {
    if (!_hasEnoughData || _totalProtected <= 0) return null;
    return _totalProtected / avgMonthlyExpenses;
  }

  bool get _isOverspent => safeToSpend < 0;

  String _formatMoney(double amount) {
    return NumberFormat.currency(
      locale: locale,
      symbol: symbol,
      decimalDigits: 0,
    ).format(amount.abs());
  }

  String _confidenceText(AppLocalizations l10n) {
    switch (confidence) {
      case ConfidenceLevel.low:
        return l10n.confidenceLow;
      case ConfidenceLevel.medium:
        return l10n.confidenceMedium;
      case ConfidenceLevel.high:
        return l10n.confidenceHigh;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
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
                // Title
                Text(
                  l10n.protectionCoverage,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.slate600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Protection totals row
                _buildProtectionTotalsRow(theme, l10n),

                const SizedBox(height: 16),
                Divider(color: AppColors.borderSubtle, height: 1),
                const SizedBox(height: 16),

                // Coverage section
                _buildCoverageSection(theme, l10n),

                // Overspend warning
                if (_isOverspent) ...[
                  const SizedBox(height: 16),
                  _buildOverspendWarning(theme, l10n),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProtectionTotalsRow(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        // Tax reserve pill
        Expanded(
          child: _ProtectionPill(
            label: l10n.taxReserve,
            amount: _formatMoney(taxProtected),
            icon: Icons.shield_outlined,
            backgroundColor: AppColors.amber50,
            borderColor: AppColors.amber200,
            textColor: AppColors.amber700,
          ),
        ),
        const SizedBox(width: 12),
        // Safety buffer pill
        Expanded(
          child: _ProtectionPill(
            label: l10n.safetyBufferTitle,
            amount: _formatMoney(safetyProtected),
            icon: Icons.savings_outlined,
            backgroundColor: AppColors.blueBg50,
            borderColor: AppColors.borderSubtle,
            textColor: AppColors.blue600,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageSection(ThemeData theme, AppLocalizations l10n) {
    if (!_hasEnoughData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.safetyBufferNotEnoughData,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.slate400,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.addTransactionsToSeeTrends,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.slate400,
            ),
          ),
        ],
      );
    }

    final months = _coverageMonths;
    final coverageDisplay = months != null
        ? l10n.coverageRunwayMonths(months.toStringAsFixed(1))
        : l10n.safetyBufferNotEnoughData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total protected
        Text(
          l10n.totalProtected,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.slate500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatMoney(_totalProtected),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.slate900,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        // Coverage in months
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 18,
              color: AppColors.teal600,
            ),
            const SizedBox(width: 8),
            Text(
              coverageDisplay,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.teal600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Based on X months of data
        Text(
          l10n.coverageBasedOnMonths(monthsUsed),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.slate400,
          ),
        ),
        const SizedBox(height: 4),

        // Confidence level
        Text(
          _confidenceText(l10n),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.slate400,
          ),
        ),
      ],
    );
  }

  Widget _buildOverspendWarning(ThemeData theme, AppLocalizations l10n) {
    final overspentAmount = safeToSpend.abs();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.rose100.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppColors.roseBorder50, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            size: 18,
            color: AppColors.rose600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.overspentWarning(_formatMoney(overspentAmount)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.rose600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Protection pill widget for tax/safety totals
class _ProtectionPill extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  const _ProtectionPill({
    required this.label,
    required this.amount,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Expanded(
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
