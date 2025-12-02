import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Widget for selecting transaction category
class CategorySelectorWidget extends StatelessWidget {
  final String? selectedCategory;
  final Function(String) onCategorySelected;
  final bool isIncome;

  const CategorySelectorWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.isIncome,
  });

  // Business category mapping: identifier -> display label
  static const Map<String, String> _categoryLabels = {
    // Revenue
    'rev_sales': 'Sales and client income',
    // Marketing and sales
    'mkt_ads': 'Advertising and marketing',
    'mkt_software': 'Website and software',
    'mkt_subs': 'Subscriptions',
    // Work tools and equipment
    'ops_equipment': 'Equipment and hardware',
    'ops_supplies': 'Office supplies',
    // Professional services
    'pro_accounting': 'Accounting and legal',
    'pro_contractors': 'Contractors and outsourcing',
    // Travel and client meetings
    'travel_general': 'Travel',
    'travel_meals': 'Meals and entertainment business',
    // Operations
    'ops_rent': 'Rent and utilities',
    'ops_insurance': 'Insurance',
    'ops_taxes': 'Taxes',
    'ops_fees': 'Bank and payment fees',
    // People and payroll
    'people_salary': 'Salary and payroll',
    'people_training': 'Benefits and training',
    // Other
    'other_expense': 'Other expense',
    'other_refunds': 'Refunds and adjustments',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: () => _showCategoryBottomSheet(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName:
                  selectedCategory != null
                      ? _getCategoryIcon(selectedCategory!)
                      : 'category',
              color:
                  selectedCategory != null
                      ? (isIncome ? AppTheme.successGreen : AppTheme.errorRed)
                      : colorScheme.onSurface.withValues(alpha: 0.5),
              size: 24,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Category',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    selectedCategory != null
                        ? _categoryLabels[selectedCategory] ??
                            'Unknown category'
                        : 'Select category',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color:
                          selectedCategory != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight:
                          selectedCategory != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: colorScheme.onSurface.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Most common business categories displayed first
    final commonCategories =
        isIncome
            ? [
              {
                'id': 'rev_sales',
                'label': 'Sales and client income',
                'icon': 'attach_money',
              },
              {
                'id': 'other_refunds',
                'label': 'Refunds and adjustments',
                'icon': 'sync',
              },
            ]
            : [
              {
                'id': 'mkt_ads',
                'label': 'Advertising and marketing',
                'icon': 'campaign',
              },
              {
                'id': 'mkt_software',
                'label': 'Website and software',
                'icon': 'code',
              },
              {
                'id': 'pro_contractors',
                'label': 'Contractors and outsourcing',
                'icon': 'people',
              },
              {'id': 'ops_rent', 'label': 'Rent and utilities', 'icon': 'home'},
              {'id': 'ops_taxes', 'label': 'Taxes', 'icon': 'receipt_long'},
              {
                'id': 'ops_fees',
                'label': 'Bank and payment fees',
                'icon': 'account_balance',
              },
              {
                'id': 'mkt_subs',
                'label': 'Subscriptions',
                'icon': 'subscriptions',
              },
              {
                'id': 'ops_equipment',
                'label': 'Equipment and hardware',
                'icon': 'computer',
              },
              {
                'id': 'ops_supplies',
                'label': 'Office supplies',
                'icon': 'inventory',
              },
              {
                'id': 'pro_accounting',
                'label': 'Accounting and legal',
                'icon': 'gavel',
              },
              {'id': 'travel_general', 'label': 'Travel', 'icon': 'flight'},
              {
                'id': 'travel_meals',
                'label': 'Meals and entertainment business',
                'icon': 'restaurant',
              },
              {'id': 'ops_insurance', 'label': 'Insurance', 'icon': 'shield'},
              {
                'id': 'people_salary',
                'label': 'Salary and payroll',
                'icon': 'payments',
              },
              {
                'id': 'people_training',
                'label': 'Benefits and training',
                'icon': 'school',
              },
              {
                'id': 'other_expense',
                'label': 'Other expense',
                'icon': 'more_horiz',
              },
            ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: 70.h,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 1.h),
                  width: 10.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Category',
                        style: theme.textTheme.titleLarge,
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: CustomIconWidget(
                          iconName: 'close',
                          color: colorScheme.onSurface,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    itemCount: commonCategories.length,
                    itemBuilder: (context, index) {
                      final category = commonCategories[index];
                      final categoryId = category['id'] as String;
                      final isSelected = selectedCategory == categoryId;

                      return InkWell(
                        onTap: () {
                          onCategorySelected(categoryId);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                        child: Container(
                          margin: EdgeInsets.only(bottom: 1.5.h),
                          padding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? (isIncome
                                            ? AppTheme.successGreen
                                            : AppTheme.errorRed)
                                        .withValues(alpha: 0.15)
                                    : colorScheme.surface,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? (isIncome
                                          ? AppTheme.successGreen
                                          : AppTheme.errorRed)
                                      : colorScheme.outline.withValues(
                                        alpha: 0.2,
                                      ),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(2.w),
                                decoration: BoxDecoration(
                                  color:
                                      isSelected
                                          ? (isIncome
                                              ? AppTheme.successGreen
                                              : AppTheme.errorRed)
                                          : colorScheme.onSurface.withValues(
                                            alpha: 0.1,
                                          ),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSmall,
                                  ),
                                ),
                                child: CustomIconWidget(
                                  iconName: category['icon'] as String,
                                  color:
                                      isSelected
                                          ? (isIncome
                                              ? AppTheme.successGreen
                                              : AppTheme.errorRed)
                                          : colorScheme.onSurface,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  category['label'] as String,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        isSelected
                                            ? (isIncome
                                                ? AppTheme.successGreen
                                                : AppTheme.errorRed)
                                            : colorScheme.onSurface,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                CustomIconWidget(
                                  iconName: 'check_circle',
                                  color:
                                      isIncome
                                          ? AppTheme.successGreen
                                          : AppTheme.errorRed,
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _getCategoryIcon(String categoryId) {
    final iconMap = {
      'rev_sales': 'attach_money',
      'mkt_ads': 'campaign',
      'mkt_software': 'code',
      'mkt_subs': 'subscriptions',
      'ops_equipment': 'computer',
      'ops_supplies': 'inventory',
      'pro_accounting': 'gavel',
      'pro_contractors': 'people',
      'travel_general': 'flight',
      'travel_meals': 'restaurant',
      'ops_rent': 'home',
      'ops_insurance': 'shield',
      'ops_taxes': 'receipt_long',
      'ops_fees': 'account_balance',
      'people_salary': 'payments',
      'people_training': 'school',
      'other_expense': 'more_horiz',
      'other_refunds': 'sync',
    };
    return iconMap[categoryId] ?? 'category';
  }
}
