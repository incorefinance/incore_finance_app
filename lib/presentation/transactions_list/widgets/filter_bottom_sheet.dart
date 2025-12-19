import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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

  void _selectCategory(String? category) {
    setState(() {
      _filters['categoryId'] = category;
    });
  }

  void _selectPaymentMethod(String? method) {
    setState(() {
      _filters['paymentMethod'] = method;
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

    // You can adjust these lists later to match your real categories
    final categories = [
      'Food',
      'Transport',
      'Shopping',
      'Entertainment',
      'Utilities',
      'Income',
    ];

    final paymentMethods = [
      'Cash',
      'Credit Card',
      'Debit Card',
      'Bank Transfer',
      'Other',
    ];

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
            // Cap total sheet height so Column never overflows
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

                // ✅ Small amendment: use Flexible instead of fixed height
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 2.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category section
                        Text(
                          'Category',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: categories.map((category) {
                            final isSelected = _filters['categoryId'] == category;
                            return FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (_) => _selectCategory(
                                isSelected ? null : category,
                              ),
                              backgroundColor: colorScheme.surface,
                              selectedColor: colorScheme.primaryContainer,
                              checkmarkColor: colorScheme.primary,
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 3.h),

                        // Payment method section
                        Text(
                          'Payment Method',
                          style: theme.textTheme.titleMedium,
                        ),
                        SizedBox(height: 1.h),
                        Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: paymentMethods.map((method) {
                            final isSelected =
                                _filters['paymentMethod'] == method;
                            return FilterChip(
                              label: Text(method),
                              selected: isSelected,
                              onSelected: (_) => _selectPaymentMethod(
                                isSelected ? null : method,
                              ),
                              backgroundColor: colorScheme.surface,
                              selectedColor: colorScheme.primaryContainer,
                              checkmarkColor: colorScheme.primary,
                              labelStyle: theme.textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            );
                          }).toList(),
                        ),

                        SizedBox(height: 3.h),

                        // You can later add client / date range fields here
                        // respecting the existing keys in _filters:
                        // 'client', 'startDate', 'endDate', 'dateRange'.
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
                      // ✅ minimal fix: actually return filters to the caller
                      final result = Map<String, dynamic>.from(_filters);
                      widget.onApplyFilters(result);
                      Navigator.pop(context, result);
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
