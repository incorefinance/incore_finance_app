import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Section header widget for grouping related settings
class SettingSectionHeader extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? padding;

  const SettingSectionHeader({
    super.key,
    required this.title,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: padding ?? EdgeInsets.fromLTRB(4.w, 3.h, 4.w, 1.h),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
