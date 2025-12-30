import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/payment_method.dart';

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
    _filters = Map<String, dynamic>.from(widget.currentFilters);
  }

  void _selectCategory(String? category) {
    setState(() {
      _filters['categoryId'] = category;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final categories = [
      'rev_sales',
      'mkt_ads',
      'mkt_software',
      'mkt_subs',
      'ops_equipment',
      'ops_supplies',
      'pro_accounting',
      'pro_contractors',
      'travel_general',
      'travel_meals',
      'ops_rent',
      'ops_insurance',
      'ops_taxes',
      'ops_fees',
      'people_salary',
      'people_training',
      'other_expense',
      'other_refunds',
    ];

    final selectedPaymentDbValue = _filters['paymentMethod'] as String?;

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
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter Transactions', style: theme.textTheme.titleLarge),
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
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Category', style: theme.textTheme.titleMedium),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: categories.map((categoryId) {
                            final isSelected = _filters['categoryId'] == categoryId;
                            return FilterChip(
                              label: Text(
                                categoryId,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) => _selectCategory(isSelected ? null : categoryId),
                              backgroundColor: colorScheme.surface,
                              selectedColor: colorScheme.primaryContainer,
                              checkmarkColor: colorScheme.primary,
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 3.h),

                        Text('Payment Method', style: theme.textTheme.titleMedium),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: PaymentMethod.values.map((method) {
                            final isSelected = selectedPaymentDbValue == method.dbValue;
                            return FilterChip(
                              label: Text(
                                method.label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                  fontSize: 12,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (_) => _selectPaymentMethod(
                                isSelected ? null : method.dbValue,
                              ),
                              backgroundColor: colorScheme.surface,
                              selectedColor: colorScheme.primaryContainer,
                              checkmarkColor: colorScheme.primary,
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 3.h),
                      ],
                    ),
                  ),
                ),

                Divider(color: colorScheme.outline),

                Padding(
                  padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.h),
                  child: ElevatedButton(
                    onPressed: _applyFilters,
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
