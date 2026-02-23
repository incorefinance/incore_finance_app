import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../theme/app_colors_ext.dart';

/// Widget for quick transaction templates
class QuickTemplatesWidget extends StatelessWidget {
  final Function(String description, String category, double amount)
      onTemplateSelected;
  final bool isIncome;
  final String locale;
  final String? selectedTemplate; // Track selected template by description

  const QuickTemplatesWidget({
    super.key,
    required this.onTemplateSelected,
    required this.isIncome,
    required this.locale,
    this.selectedTemplate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final templates = isIncome
        ? [
            {
              'description': 'Client Payment',
              'category': 'rev_sales',
              'amount': 500.0,
              'icon': 'work',
            },
            {
              'description': 'Monthly Salary',
              'category': 'rev_sales',
              'amount': 3000.0,
              'icon': 'account_balance_wallet',
            },
          ]
        : [
            {
              'description': 'Coffee',
              'category': 'other_expense',
              'amount': 5.0,
              'icon': 'local_cafe',
            },
            {
              'description': 'Gas',
              'category': 'travel_general',
              'amount': 50.0,
              'icon': 'local_gas_station',
            },
            {
              'description': 'Software',
              'category': 'mkt_software',
              'amount': 30.0,
              'icon': 'computer',
            },
            {
              'description': 'Rent',
              'category': 'ops_rent',
              'amount': 800.0,
              'icon': 'home',
            },
          ];

    // Calculate tile width for 3-column grid (matching category/payment selectors)
    final tileWidth = (100.w - 8.w - 4.w) / 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: theme.textTheme.labelMedium?.copyWith(
            color: context.slate500,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.4.h,
          children: templates.map((template) {
            final description = template['description'] as String;
            final formatted = IncoreNumberFormatter.formatAmount(
              template['amount'] as double,
              locale: locale,
            );
            final isSelected = selectedTemplate == description;

            // Colors based on income/expense type
            final accentColor = isIncome ? context.teal600 : context.rose600;
            final accentBgColor = isIncome ? context.tealBg80 : context.roseBg80;
            final accentBorderColor = isIncome ? context.tealBorder50 : context.roseBorder50;

            return InkWell(
              onTap: () => onTemplateSelected(
                description,
                template['category'] as String,
                template['amount'] as double,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: tileWidth,
                padding: EdgeInsets.symmetric(vertical: 1.4.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentBgColor
                      : context.surfaceGlass80,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? accentBorderColor
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
                        color: accentBgColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: accentBorderColor,
                                width: 1,
                              ),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: template['icon'] as String,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.8.h),
                    // Centered label below icon
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 1.w),
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: isSelected ? accentColor : context.slate900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: 0.3.h),
                    // Amount below description
                    Text(
                      formatted,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isSelected ? accentColor : context.slate500,
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
