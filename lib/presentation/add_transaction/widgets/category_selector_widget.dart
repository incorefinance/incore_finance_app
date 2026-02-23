import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:incore_finance/l10n/app_localizations.dart';

import '../../../core/app_export.dart';
import '../../../models/transaction_category.dart';
import '../../../theme/app_colors_ext.dart';
import '../../../utils/category_localizer.dart';

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
    final l10n = AppLocalizations.of(context)!;

    // Single source of truth
    final categories = TransactionCategory.values
        .where((c) => c.isIncome == isIncome)
        .toList();

    // Calculate tile width for 3-column grid
    // Screen width minus padding (4.w * 2 = 8.w) minus spacing (2.w * 2 = 4.w), divided by 3
    final tileWidth = (100.w - 8.w - 4.w) / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.category,
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.slate500,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.4.h,
          children: categories.map((cat) {
            final dbValue = cat.dbValue;
            final isSelected = selectedCategory == dbValue;

            return InkWell(
              onTap: () => onCategorySelected(isSelected ? null : dbValue),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: tileWidth,
                padding: EdgeInsets.symmetric(vertical: 1.4.h),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon container box
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.blue50
                            : context.surfaceGlass80,
                        borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: context.borderGlass60,
                                width: 1,
                              ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: cat.iconName,
                          color: isSelected ? context.blue600 : context.slate400,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.8.h),
                    // Centered label below icon
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1.w),
                      child: Text(
                        getLocalizedCategoryLabel(context, cat),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected ? context.blue600 : context.slate500,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
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
