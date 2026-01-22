import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../models/transaction_category.dart';
import '../../../theme/app_colors.dart';

/// Widget for selecting transaction category
class CategorySelectorWidget extends StatelessWidget {
  final bool isIncome; // ✅ keep same constructor param
  final String? selectedCategory; // stored as dbValue string (ex: 'mkt_ads')
  final Function(String?) onCategorySelected; // returns dbValue (or null)

  const CategorySelectorWidget({
    super.key,
    required this.isIncome,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ✅ single source of truth
    final categories = TransactionCategory.values
        .where((c) => c.isIncome == isIncome)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 1.h),

        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: categories.map((cat) {
            final dbValue = cat.dbValue;
            final isSelected = selectedCategory == dbValue;

            return InkWell(
              onTap: () => onCategorySelected(isSelected ? null : dbValue),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primarySoft.withValues(alpha: 0.15)
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : colorScheme.outline.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: cat.iconName, // ✅ enum icon
                      color: isSelected
                          ? AppColors.primary
                          : colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      cat.label, // ✅ enum label
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
