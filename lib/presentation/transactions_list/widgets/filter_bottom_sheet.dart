import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/l10n/app_localizations.dart';

import '../../../core/app_export.dart';
import '../../../models/payment_method.dart';
import '../../../models/transaction_category.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../utils/category_localizer.dart';
import '../../../utils/payment_localizer.dart';
import '../transactions_list.dart' show TransactionTypeFilter;

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
  TransactionTypeFilter _typeFilter = TransactionTypeFilter.all;

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.currentFilters);

    // Parse incoming transactionType
    final typeStr = _filters['transactionType'] as String?;
    if (typeStr == 'income') {
      _typeFilter = TransactionTypeFilter.income;
    } else if (typeStr == 'expense') {
      _typeFilter = TransactionTypeFilter.expense;
    } else {
      _typeFilter = TransactionTypeFilter.all;
    }
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

  void _selectType(TransactionTypeFilter type) {
    setState(() {
      _typeFilter = type;

      // Auto-clear category if incompatible with new type
      final selectedCatDbValue = _filters['categoryId'] as String?;
      if (selectedCatDbValue != null) {
        final selectedCat =
            TransactionCategory.fromDbValue(selectedCatDbValue);
        if (selectedCat != null) {
          final isIncomeCat = selectedCat.isIncome;
          if ((type == TransactionTypeFilter.income && !isIncomeCat) ||
              (type == TransactionTypeFilter.expense && isIncomeCat)) {
            _filters['categoryId'] = null;
          }
        }
      }
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
      _typeFilter = TransactionTypeFilter.all;
    });
  }

  void _applyFilters() {
    final appliedFilters = Map<String, dynamic>.from(_filters);
    appliedFilters['transactionType'] = _typeFilter.name;
    widget.onApplyFilters(appliedFilters);
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
    final l10n = AppLocalizations.of(context)!;

    final selectedCategoryDbValue = _filters['categoryId'] as String?;
    final selectedPaymentDbValue = _filters['paymentMethod'] as String?;
    final selectedDateRange = _filters['dateRange'] as String?;

    final incomeCategories =
        TransactionCategory.values.where((c) => c.isIncome).toList();
    final expenseCategories =
        TransactionCategory.values.where((c) => !c.isIncome).toList();

    final tileWidth = (100.w - 8.w - 4.w) / 3;

    // Build category/payment tile with frosted design
    Widget buildTile({
      required bool isSelected,
      required String label,
      required String iconName,
      required VoidCallback onTap,
      bool isDisabled = false,
    }) {
      // When disabled: lower opacity, no tap response
      return IgnorePointer(
        ignoring: isDisabled,
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: tileWidth,
              padding: EdgeInsets.symmetric(vertical: 1.4.h),
              decoration: BoxDecoration(
                color: isSelected && !isDisabled
                    ? context.blue50
                    : context.surfaceGlass80,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected && !isDisabled
                      ? context.blue600.withValues(alpha: 0.25)
                      : context.borderGlass60,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected && !isDisabled
                          ? context.blue50
                          : context.surfaceGlass80,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusIconBox),
                      border: isSelected && !isDisabled
                          ? null
                          : Border.all(
                              color: context.borderGlass60,
                              width: 1,
                            ),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: iconName,
                        color: isDisabled
                            ? context.slate400
                            : (isSelected
                                ? context.blue600
                                : context.slate400),
                        size: 20,
                      ),
                    ),
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
                        color: isDisabled
                            ? context.slate400
                            : (isSelected
                                ? context.blue600
                                : context.slate500),
                        fontWeight:
                            isSelected && !isDisabled ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Build date chip with frosted design
    Widget buildDateChip(String? value, String label) {
      final isSelected = selectedDateRange == value;

      return InkWell(
        onTap: () {
          setState(() {
            _filters['dateRange'] = value;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
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
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: isSelected ? context.blue600 : context.slate500,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    // Build type option for toggle
    Widget buildTypeOption(TransactionTypeFilter type, String label) {
      final isSelected = _typeFilter == type;

      // Colors based on type
      Color bgColor;
      Color borderColor;
      Color textColor;

      if (isSelected) {
        if (type == TransactionTypeFilter.income) {
          bgColor = context.tealBg80;
          borderColor = context.tealBorder50;
          textColor = context.teal700;
        } else if (type == TransactionTypeFilter.expense) {
          bgColor = context.roseBg80;
          borderColor = context.roseBorder50;
          textColor = context.rose700;
        } else {
          bgColor = context.blue50;
          borderColor = context.blue600.withValues(alpha: 0.25);
          textColor = context.blue600;
        }
      } else {
        bgColor = Colors.transparent;
        borderColor = Colors.transparent;
        textColor = context.slate500;
      }

      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectType(type),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(color: borderColor, width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Build type toggle segment
    Widget buildTypeToggle() {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.surfaceGlass80,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.borderGlass60,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            buildTypeOption(TransactionTypeFilter.all, l10n.all),
            buildTypeOption(TransactionTypeFilter.income, l10n.income),
            buildTypeOption(TransactionTypeFilter.expense, l10n.expense),
          ],
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
              color: context.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.2.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.4.h,
            children: cats.map((cat) {
              final isSelected = selectedCategoryDbValue == cat.dbValue;
              // Disable categories that don't match the selected type filter
              final isDisabled =
                  (_typeFilter == TransactionTypeFilter.income &&
                      !cat.isIncome) ||
                  (_typeFilter == TransactionTypeFilter.expense &&
                      cat.isIncome);
              return buildTile(
                isSelected: isSelected,
                isDisabled: isDisabled,
                label: getLocalizedCategoryLabel(context, cat),
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
            label: getLocalizedPaymentLabel(context, m),
            iconName: _iconForPaymentMethod(m),
            onTap: () => _selectPaymentMethod(isSelected ? null : m.dbValue),
          );
        }).toList(),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: context.canvasFrosted,
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
                    color: context.slate400,
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
                        l10n.filterTransactions,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: context.slate900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: Text(
                          l10n.clearAll,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: context.rose600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 1.h),
                Divider(color: context.dividerGlass60),

                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Transaction Type Toggle
                        Text(
                          l10n.transactionType,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        buildTypeToggle(),

                        SizedBox(height: 3.h),

                        // Date Range
                        Text(
                          l10n.dateRange,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: [
                            buildDateChip(null, l10n.allTime),
                            buildDateChip('today', l10n.today),
                            buildDateChip('week', l10n.lastSevenDays),
                            buildDateChip('month', l10n.thisMonth),
                            buildDateChip('year', l10n.thisYear),
                          ],
                        ),

                        SizedBox(height: 3.h),

                        // Category section header
                        Text(
                          l10n.category,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 1.8.h),

                        // Income categories
                        buildCategorySection(l10n.income, incomeCategories),
                        SizedBox(height: 3.h),

                        // Expense categories
                        buildCategorySection(l10n.expenses, expenseCategories),

                        SizedBox(height: 3.h),

                        // Payment Method
                        Text(
                          l10n.paymentMethod,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.slate500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 1.8.h),
                        buildPaymentSection(),

                        SizedBox(height: 1.h),
                      ],
                    ),
                  ),
                ),

                Divider(color: context.dividerGlass60),

                // Apply button
                Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 6.h,
                    child: ElevatedButton(
                      onPressed: () {
                        _applyFilters();
                        // Parent handles pop
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.blue600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        l10n.applyFilters,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
