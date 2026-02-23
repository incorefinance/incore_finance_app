import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/l10n/app_localizations.dart';

import '../../../core/app_export.dart';
import 'package:incore_finance/models/payment_method.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../utils/payment_localizer.dart';

/// Widget for selecting payment method
class PaymentMethodSelector extends StatelessWidget {
  final String? selectedMethod; // stores dbValue
  final ValueChanged<String> onMethodSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  String _iconFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'payments';
      case PaymentMethod.card:
        return 'credit_card';
      case PaymentMethod.bankTransfer:
        return 'account_balance';
      case PaymentMethod.mbWay:
        return 'smartphone';
      case PaymentMethod.paypal:
        return 'account_balance_wallet';
      case PaymentMethod.directDebit:
        return 'receipt_long';
      case PaymentMethod.other:
        return 'more_horiz';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final paymentMethods = PaymentMethod.values;

    // Calculate tile width for 3-column grid
    final tileWidth = (100.w - 8.w - 4.w) / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.paymentMethod,
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.slate500,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.4.h,
          children: paymentMethods.map((method) {
            final dbValue = method.dbValue;
            final label = getLocalizedPaymentLabel(context, method);
            final isSelected = selectedMethod == dbValue;

            return InkWell(
              onTap: () => onMethodSelected(dbValue),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: tileWidth,
                padding: EdgeInsets.symmetric(vertical: 1.4.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.blue50
                      : context.surfaceGlass80,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? context.blue600.withValues(alpha: 0.25)
                        : context.borderGlass60,
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon container box
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.blue50
                            : context.surfaceGlass80,
                        borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: context.borderGlass60,
                                width: 1,
                              ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: _iconFor(method),
                          color: isSelected ? context.blue600 : context.slate400,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.8.h),
                    // Centered label below icon
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1.w),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected ? context.blue600 : context.slate500,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
