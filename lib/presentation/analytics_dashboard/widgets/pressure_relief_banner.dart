import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

/// Calm, neutral banner confirming that a pressure-reducing action completed.
///
/// Mirrors the SafetyBufferSection row styling but with surface/neutral colors.
/// No green, no red — just a subtle check icon and subdued text.
class PressureReliefBanner extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onDismiss;

  const PressureReliefBanner({
    super.key,
    required this.title,
    this.subtitle,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.check_circle_outline,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
