import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Dialog for selecting primary currency
class CurrencySelectorDialog extends StatefulWidget {
  final String currentCurrency;
  final Function(String) onCurrencySelected;

  const CurrencySelectorDialog({
    super.key,
    required this.currentCurrency,
    required this.onCurrencySelected,
  });

  @override
  State<CurrencySelectorDialog> createState() => _CurrencySelectorDialogState();
}

class _CurrencySelectorDialogState extends State<CurrencySelectorDialog> {
  late String _selectedCurrency;

  List<Map<String, String>> _getCurrencies(AppLocalizations l10n) => [
    {'code': 'USD', 'name': l10n.currencyUsDollar, 'symbol': '\$'},
    {'code': 'BRL', 'name': l10n.currencyBrazilianReal, 'symbol': 'R\$'},
    {'code': 'EUR', 'name': l10n.currencyEuro, 'symbol': '€'},
    {'code': 'GBP', 'name': l10n.currencyBritishPound, 'symbol': '£'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectCurrency,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),

            // Currency options
            ..._getCurrencies(l10n).map((currency) => Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: _buildCurrencyOption(
                    context: context,
                    currency: currency,
                    theme: theme,
                    colorScheme: colorScheme,
                  ),
                )),

            SizedBox(height: 2.h),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: context.blue600,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                SizedBox(width: 2.w),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.blue600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    widget.onCurrencySelected(_selectedCurrency);
                    Navigator.pop(context);
                  },
                  child: Text(l10n.apply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption({
    required BuildContext context,
    required Map<String, String> currency,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _selectedCurrency == currency['code'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCurrency = currency['code']!;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? context.blue600
                  : context.borderGlass60,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: context.blue50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    currency['symbol']!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: context.blue600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currency['code']!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    Text(
                      currency['name']!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                CustomIconWidget(
                  iconName: 'check_circle',
                  size: 5.w,
                  color: context.blue600,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
