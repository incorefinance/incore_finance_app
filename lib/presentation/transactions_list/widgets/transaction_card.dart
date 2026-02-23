import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:incore_finance/models/payment_method.dart';
import 'package:incore_finance/models/transaction_category.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/user_settings_service.dart';
import 'package:incore_finance/theme/app_colors_ext.dart';
import 'package:incore_finance/l10n/app_localizations.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../utils/category_localizer.dart';
import '../../../utils/payment_localizer.dart';

class TransactionCard extends StatefulWidget {
  final TransactionRecord transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> {
  final UserSettingsService _settingsService = UserSettingsService();

  String _currencyLocale = 'en_US';
  String _currencySymbol = '€';
  String _currencyCode = 'EUR';

  @override
  void initState() {
    super.initState();
    _loadCurrencySettings();
  }

  Future<void> _loadCurrencySettings() async {
    try {
      final settings = await _settingsService.getCurrencySettings();
      if (!mounted) return;

      setState(() {
      _currencyLocale = settings.locale;
      _currencySymbol = settings.symbol;
      _currencyCode = settings.currencyCode;
    });

    } catch (_) {
      // Keep defaults silently. Do not break the UI.
    }
  }

  String _formatCurrency(num value) {
    return IncoreNumberFormatter.formatMoney(
      value,
      locale: _currencyLocale,
      symbol: _currencySymbol,
      currencyCode: _currencyCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final t = widget.transaction;

    final isExpense = t.type == 'expense';

    // Category shown as title (label) - use localized label
    final category = TransactionCategory.fromDbValue(t.category);
    final categoryLabel = category != null
        ? getLocalizedCategoryLabel(context, category)
        : t.category;
    final categoryIcon = category?.iconName ?? 'category';

    // Description shown as subtitle (smaller)
    final description = (t.description.trim().isEmpty) ? l10n.noDescription : t.description.trim();

    // Payment method label must be user-friendly - use localized label
    final paymentMethod = PaymentMethodParser.fromAny(t.paymentMethod);
    final paymentLabel = paymentMethod != null
        ? getLocalizedPaymentLabel(context, paymentMethod)
        : ((t.paymentMethod ?? '').replaceAll('_', ' '));

    // Amount formatting:
    // - income: green
    // - expense: red + minus sign
    final amountAbs = (t.amount).abs();
    final formattedAbs = _formatCurrency(amountAbs);
    final formattedAmount = isExpense ? '- $formattedAbs' : formattedAbs;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.surfaceGlass80,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.borderGlass60,
                width: 1,
              ),
            ),
            child: Row(
        children: [
          // Left icon box
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.blue50,
              borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: categoryIcon,
                color: context.blue600,
                size: 20,
              ),
            ),
          ),

          SizedBox(width: 4.w),

          // Middle text block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title: Category
                Text(
                  categoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.slate900,
                  ),
                ),
                SizedBox(height: 0.4.h),

                // Subtitle: description + payment method
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.slate500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.4.h),

                Row(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 16,
                      color: context.slate400,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      paymentLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.slate400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: 3.w),

          // Right side: amount + menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formattedAmount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isExpense ? context.rose700 : context.teal700,
                ),
              ),
              SizedBox(height: 0.6.h),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      widget.onEdit?.call();
                      break;
                    case 'delete':
                      widget.onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                    if (widget.onEdit != null)
                      PopupMenuItem<String>(
                        value: 'edit',
                        child: Text(l10n.edit),
                      ),
                    if (widget.onDelete != null)
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text(l10n.delete),
                      ),
                  ],
                icon: Icon(
                  Icons.more_horiz,
                  color: this.context.slate400,
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
}
