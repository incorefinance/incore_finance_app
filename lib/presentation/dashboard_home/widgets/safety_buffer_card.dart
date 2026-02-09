import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors.dart';

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
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

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
          // Title
          Text(
            l10n.safetyBufferTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.4.h),

          // Primary value: days
          Text(
            _daysText(l10n),
            style: theme.textTheme.displaySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),

          // Secondary: weeks (if days >= 7)
          if (bufferWeeks != null) ...[
            SizedBox(height: 0.3.h),
            Text(
              '≈ $_weeksFormatted weeks',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          SizedBox(height: 1.h),
          Divider(color: AppColors.borderSubtle),
          SizedBox(height: 1.h),

          // Tax line
          Text(
            l10n.safetyBufferTaxReserveIncludedWithAmount(
              taxPercent,
              _formattedTaxAmount,
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),

          SizedBox(height: 0.5.h),

          // Qualifier line
          Text(
            qualifier,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
