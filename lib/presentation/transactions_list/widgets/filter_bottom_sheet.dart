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
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
    if (_filters['startDate'] != null && _filters['endDate'] != null) {
      _dateRange = DateTimeRange(
        start: _filters['startDate'] as DateTime,
        end: _filters['endDate'] as DateTime,
      );
    }
  }

  void _selectCategory(String category) {
    setState(() {
      if (_filters['category'] == category) {
        _filters['category'] = null;
      } else {
        _filters['category'] = category;
      }
    });
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      if (_filters['paymentMethod'] == method) {
        _filters['paymentMethod'] = null;
      } else {
        _filters['paymentMethod'] = method;
      }
    });
  }

  void _selectClient(String client) {
    setState(() {
      if (_filters['client'] == client) {
        _filters['client'] = null;
      } else {
        _filters['client'] = client;
      }
    });
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryNavyLight,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
        _filters['startDate'] = picked.start;
        _filters['endDate'] = picked.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _filters = {
        'category': null,
        'paymentMethod': null,
        'client': null,
        'startDate': null,
        'endDate': null,
      };
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final categories = [
      'Food',
      'Transport',
      'Shopping',
      'Entertainment',
      'Utilities',
      'Income'
    ];
    final paymentMethods = [
      'Cash',
      'Credit Card',
      'Debit Card',
      'Bank Transfer',
      'Digital Wallet'
    ];
    final clients = [
      'Client A',
      'Client B',
      'Client C',
      'Client D',
      'Personal'
    ];

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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
            Divider(color: colorScheme.outline),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: categories.map((category) {
                        final isSelected = _filters['category'] == category;
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => _selectCategory(category),
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
                    SizedBox(height: 2.h),
                    Text(
                      'Payment Method',
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: paymentMethods.map((method) {
                        final isSelected = _filters['paymentMethod'] == method;
                        return FilterChip(
                          label: Text(method),
                          selected: isSelected,
                          onSelected: (_) => _selectPaymentMethod(method),
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
                    SizedBox(height: 2.h),
                    Text(
                      'Client',
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 1.h),
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: clients.map((client) {
                        final isSelected = _filters['client'] == client;
                        return FilterChip(
                          label: Text(client),
                          selected: isSelected,
                          onSelected: (_) => _selectClient(client),
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
                    SizedBox(height: 2.h),
                    Text(
                      'Date Range',
                      style: theme.textTheme.titleMedium,
                    ),
                    SizedBox(height: 1.h),
                    OutlinedButton.icon(
                      onPressed: _selectDateRange,
                      icon: CustomIconWidget(
                        iconName: 'calendar_today',
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      label: Text(
                        _dateRange != null
                            ? '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year} - ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}'
                            : 'Select Date Range',
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, 6.h),
                      ),
                    ),
                    SizedBox(height: 3.h),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  widget.onApplyFilters(_filters);
                  Navigator.pop(context);
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
    );
  }
}
