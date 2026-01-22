import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../utils/number_formatter.dart';
import '../../../theme/app_colors.dart';

/// Widget for quick transaction templates
class QuickTemplatesWidget extends StatelessWidget {
  final Function(String description, String category, double amount)
      onTemplateSelected;
  final bool isIncome;
  final String locale;

  const QuickTemplatesWidget({
    super.key,
    required this.onTemplateSelected,
    required this.isIncome,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Templates',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 1.h),
        SizedBox(
          height: 8.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            separatorBuilder: (context, index) => SizedBox(width: 2.w),
            itemBuilder: (context, index) {
              final template = templates[index];
              final formatted = IncoreNumberFormatter.formatAmount(
                template['amount'] as double,
                locale: locale,
              );

              return InkWell(
                onTap: () => onTemplateSelected(
                  template['description'] as String,
                  template['category'] as String,
                  template['amount'] as double,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: template['icon'] as String,
                            color:
                                isIncome ? AppColors.income : AppColors.expense,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            template['description'] as String,
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        formatted,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
