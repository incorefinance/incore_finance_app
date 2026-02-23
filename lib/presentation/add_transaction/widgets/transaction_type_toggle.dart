import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_colors_ext.dart';

/// Toggle widget for switching between Income and Expense
class TransactionTypeToggle extends StatelessWidget {
  final bool isIncome;
  final Function(bool) onToggle;

  const TransactionTypeToggle({
    super.key,
    required this.isIncome,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: _buildToggleButton(
              context: context,
              label: 'Income',
              icon: 'arrow_downward',
              isSelected: isIncome,
              color: context.teal600,
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle(true);
              },
            ),
          ),
          SizedBox(width: 1.w),
          Expanded(
            child: _buildToggleButton(
              context: context,
              label: 'Expense',
              icon: 'arrow_upward',
              isSelected: !isIncome,
              color: context.rose600,
              onTap: () {
                HapticFeedback.selectionClick();
                onToggle(false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required BuildContext context,
    required String label,
    required String icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    // Determine income vs expense from the color param (no new params)
    final isIncomeType = color == context.teal600;

    // Selected colors based on type
    final selectedBgColor = isIncomeType ? context.tealBg80 : context.roseBg80;
    final selectedBorderColor = isIncomeType ? context.tealBorder50 : context.roseBorder50;
    final selectedTextColor = isIncomeType ? context.teal700 : context.rose700;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: selectedBorderColor, width: 1)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // KEEP existing icon - no changes to icon name or presence
              CustomIconWidget(
                iconName: icon,
                color: isSelected ? selectedTextColor : context.slate500,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected ? selectedTextColor : context.slate500,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
