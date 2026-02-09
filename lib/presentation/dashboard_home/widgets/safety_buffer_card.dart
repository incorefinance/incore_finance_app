import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';

class SafetyBufferCard extends StatelessWidget {
  final int? bufferDays;
  final double? bufferWeeks;
  final int taxPercent;
  final double taxAmount;
  final String qualifier;
  final String currencyLocale;
  final String currencySymbol;

  const SafetyBufferCard({
    super.key,
    required this.bufferDays,
    this.bufferWeeks,
    required this.taxPercent,
    required this.taxAmount,
    required this.qualifier,
    required this.currencyLocale,
    required this.currencySymbol,
  });

  String _daysText(AppLocalizations l10n) {
    if (bufferDays == null) return l10n.safetyBufferNotEnoughData;
    return l10n.safetyBufferDays(bufferDays!);
  }

  String get _weeksFormatted {
    if (bufferWeeks == null) return '';
    return bufferWeeks == bufferWeeks!.roundToDouble()
        ? bufferWeeks!.toInt().toString()
        : bufferWeeks!.toStringAsFixed(1);
  }

  String get _formattedTaxAmount {
    return IncoreNumberFormatter.formatMoney(
      taxAmount,
      locale: currencyLocale,
      symbol: currencySymbol,
      currencyCode: '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

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
                // Title
                Text(
                  l10n.safetyBufferTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Primary value: days
                Text(
                  _daysText(l10n),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.slate900,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                // Secondary: weeks (if days >= 7)
                if (bufferWeeks != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '≈ $_weeksFormatted weeks',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.slate500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                Divider(color: AppColors.dividerGlass60Light),
                const SizedBox(height: 12),

                // Tax line
                Text(
                  l10n.safetyBufferTaxReserveIncludedWithAmount(
                    taxPercent,
                    _formattedTaxAmount,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 4),

                // Qualifier line
                Text(
                  qualifier,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate500,
                    fontWeight: FontWeight.w400,
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
