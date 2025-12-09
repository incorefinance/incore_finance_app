import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Widget for selecting payment method
class PaymentMethodSelector extends StatelessWidget {
  final String? selectedMethod;
  final Function(String) onMethodSelected;

  const PaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final paymentMethods = [
      {'name': 'Cash', 'icon': 'payments'},
      {'name': 'Card', 'icon': 'credit_card'},
      {'name': 'Bank Transfer', 'icon': 'account_balance'},
      {'name': 'Digital Wallet', 'icon': 'account_balance_wallet'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 6.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: paymentMethods.length,
            separatorBuilder: (context, index) => SizedBox(width: 2.w),
            itemBuilder: (context, index) {
              final method = paymentMethods[index];
              final isSelected = selectedMethod == method['name'];

              return InkWell(
                onTap: () => onMethodSelected(method['name'] as String),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentGold.withValues(alpha: 0.15)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentGold
                          : colorScheme.outline.withValues(alpha: 0.2),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: method['icon'] as String,
                        color: isSelected
                            ? AppTheme.accentGold
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        method['name'] as String,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: isSelected
                              ? AppTheme.accentGold
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
