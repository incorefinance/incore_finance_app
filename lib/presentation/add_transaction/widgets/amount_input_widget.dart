import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_colors.dart';

/// Widget for amount input with currency formatting
class AmountInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final String currencySymbol;
  final String locale;
  final Function(String) onChanged;
  final bool isIncome;

  const AmountInputWidget({
    super.key,
    required this.controller,
    required this.currencySymbol,
    required this.locale,
    required this.onChanged,
    required this.isIncome,
  });

  @override
  State<AmountInputWidget> createState() => _AmountInputWidgetState();
}

class _AmountInputWidgetState extends State<AmountInputWidget> {
  late CurrencyTextInputFormatter _formatter;

  @override
  void initState() {
    super.initState();
    _initializeFormatter();
  }

  @override
  void didUpdateWidget(AmountInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale ||
        oldWidget.currencySymbol != widget.currencySymbol) {
      _initializeFormatter();
    }
  }

  void _initializeFormatter() {
    // Map user's locale to the correct formatter locale
    final formatterLocale = _getFormatterLocale(widget.locale);

    _formatter = CurrencyTextInputFormatter.currency(
      locale: formatterLocale,
      symbol: widget.currencySymbol,
      decimalDigits: 2,
    );
  }

  /// Maps user's locale settings to CurrencyTextInputFormatter locale
  String _getFormatterLocale(String userLocale) {
    switch (userLocale) {
      case 'pt_PT': // EUR - Portuguese format
      case 'pt_BR': // BRL - Brazilian format
        return userLocale;
      case 'en_US': // USD - US format
        return 'en_US';
      case 'en_GB': // GBP - UK format
        return 'en_GB';
      default:
        return userLocale; // Use as-is if already valid
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 3.h),
      decoration: BoxDecoration(
        color:
            widget.isIncome
                ? AppColors.income.withValues(alpha: 0.1)
                : AppColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: widget.controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_formatter],
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: widget.isIncome ? AppColors.income : AppColors.expense,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '${widget.currencySymbol}0.00',
              hintStyle: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }
}
