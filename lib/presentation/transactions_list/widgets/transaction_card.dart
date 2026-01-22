import 'package:flutter/material.dart';
import 'package:incore_finance/models/payment_method.dart';
import 'package:incore_finance/models/transaction_category.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/user_settings_service.dart';
import 'package:incore_finance/theme/app_colors.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';

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
    final colorScheme = theme.colorScheme;

    final t = widget.transaction;

    final isExpense = t.type == 'expense';

    // Category shown as title (label)
    final category = TransactionCategory.fromDbValue(t.category);
    final categoryLabel = category?.label ?? t.category;
    final categoryIcon = category?.iconName ?? 'category';

    // Description shown as subtitle (smaller)
    final description = (t.description.trim().isEmpty) ? 'No description' : t.description.trim();

    // Payment method label must be user-friendly
    final paymentLabel =
        PaymentMethodParser.fromAny(t.paymentMethod)?.label ??
        ((t.paymentMethod ?? '').replaceAll('_', ' '));

    // Amount formatting:
    // - income: green
    // - expense: red + minus sign
    final amountAbs = (t.amount).abs();
    final formattedAbs = _formatCurrency(amountAbs);
    final formattedAmount = isExpense ? '- $formattedAbs' : formattedAbs;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left icon box (keep grey look)
          Container(
            width: 12.w,
            height: 12.w,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: categoryIcon,
                color: colorScheme.onSurface.withValues(alpha: 0.45),
                size: 22,
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
                          color: colorScheme.onSurface.withValues(alpha: 0.65),
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
                      color: colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      paymentLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
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
                  color: isExpense ? colorScheme.error : AppColors.success,
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
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    if (widget.onDelete != null)
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                  ],
                icon: Icon(
                  Icons.more_horiz,
                  color: colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
