import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/payment_method.dart';
import '../../../models/transaction_category.dart';

/// Bottom sheet for transaction filtering options
class FilterBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheet({
    super.key,
    required this.currentFilters,
    required this.onApplyFilters,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    // Copy so we never mutate the original map reference
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  void _selectCategory(String? categoryDbValue) {
    setState(() {
      _filters['categoryId'] = categoryDbValue;
    });
  }

  void _selectPaymentMethod(String? methodDbValue) {
    setState(() {
      _filters['paymentMethod'] = methodDbValue;
    });
  }

  void _clearFilters() {
    setState(() {
      _filters['categoryId'] = null;
      _filters['dateRange'] = null;
      _filters['paymentMethod'] = null;
      _filters['client'] = null;
      _filters['startDate'] = null;
      _filters['endDate'] = null;
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(Map<String, dynamic>.from(_filters));
  }

  String _iconForPaymentMethod(PaymentMethod method) {
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
    final colorScheme = theme.colorScheme;

    final selectedCategoryDbValue = _filters['categoryId'] as String?;
    final selectedPaymentDbValue = _filters['paymentMethod'] as String?;

    // Business logic grouping: Income first, then Expenses
    final incomeCategories =
        TransactionCategory.values.where((c) => c.isIncome).toList();
    final expenseCategories =
        TransactionCategory.values.where((c) => !c.isIncome).toList();

    final tileWidth = (100.w - 8.w - 4.w) / 3; // 3 columns, safe spacing

    Widget buildTile({
      required bool isSelected,
      required String label,
      required String iconName,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Container(
          width: tileWidth,
          padding: EdgeInsets.symmetric(vertical: 1.4.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentGold.withValues(alpha: 0.12)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentGold
                  : colorScheme.outline.withValues(alpha: 0.18),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: isSelected
                    ? AppTheme.accentGold
                    : colorScheme.onSurface.withValues(alpha: 0.65),
                size: 22,
              ),
              SizedBox(height: 0.8.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.w),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? AppTheme.accentGold
                        : colorScheme.onSurface.withValues(alpha: 0.8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildCategorySection(String title, List<TransactionCategory> cats) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.4.h,
            children: cats.map((cat) {
              final isSelected = selectedCategoryDbValue == cat.dbValue;
              return buildTile(
                isSelected: isSelected,
                label: cat.label,
                iconName: cat.iconName,
                onTap: () => _selectCategory(isSelected ? null : cat.dbValue),
              );
            }).toList(),
          ),
        ],
      );
    }

    Widget buildPaymentSection() {
      final methods = PaymentMethod.values;

      return Wrap(
        spacing: 2.w,
        runSpacing: 1.4.h,
        children: methods.map((m) {
          final isSelected = selectedPaymentDbValue == m.dbValue;
          return buildTile(
            isSelected: isSelected,
            label: m.label,
            iconName: _iconForPaymentMethod(m),
            onTap: () => _selectPaymentMethod(isSelected ? null : m.dbValue),
          );
        }).toList(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header row
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Transactions',
                        style: theme.textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text(
                          'Clear All',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 1.h),
                Divider(color: colorScheme.outline),

                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.8.h),

                        // Income first, then Expenses
                        buildCategorySection('Income', incomeCategories),
                        SizedBox(height: 3.h),
                        buildCategorySection('Expenses', expenseCategories),

                        SizedBox(height: 3.h),

                        Text(
                          'Payment Method',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.8.h),
                        buildPaymentSection(),

                        SizedBox(height: 1.h),
                      ],
                    ),
                  ),
                ),

                Divider(color: colorScheme.outline),

                // Apply button
                Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.h),
                  child: ElevatedButton(
                    onPressed: () {
                      _applyFilters();
                      // DO NOT pop here – parent handles it
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 6.h),
                    ),
                    child: const Text('Apply Filters'),
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
