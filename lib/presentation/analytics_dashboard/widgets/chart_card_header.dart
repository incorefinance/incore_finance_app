import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Reusable header for chart cards.
/// Displays title, optional badge, and optional subtitle.
class ChartCardHeader extends StatelessWidget {
  final String title;
  final Widget? badge;
  final String? subtitle;

  const ChartCardHeader({
    super.key,
    required this.title,
    this.badge,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 2.w),
              badge!,
            ],
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: 0.75.h),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
