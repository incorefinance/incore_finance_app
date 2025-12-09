import 'package:flutter/material.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Filter chip widget for displaying active filters
class TransactionFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;
  final Color? backgroundColor;
  final Color? textColor;

  const TransactionFilterChip({
    super.key,
    required this.label,
    required this.onDeleted,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Chip(
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: textColor ?? colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
      deleteIcon: CustomIconWidget(
        iconName: 'close',
        size: 16,
        color: textColor ?? colorScheme.onSecondaryContainer,
      ),
      onDeleted: onDeleted,
      backgroundColor: backgroundColor ?? colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
