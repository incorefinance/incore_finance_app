import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../domain/guidance/insight_severity.dart';
import '../../../theme/app_colors.dart';

/// Precomputed severity-based colors for the insight card.
class _SeverityColors {
  final Color accent;
  final Color background;
  final Color border;
  final Color iconBackground;

  const _SeverityColors({
    required this.accent,
    required this.background,
    required this.border,
    required this.iconBackground,
  });

  factory _SeverityColors.from(InsightSeverity severity, ColorScheme cs) {
    switch (severity) {
      case InsightSeverity.risk:
        return _SeverityColors(
          accent: cs.error,
          background: cs.error.withValues(alpha: 0.08),
          border: cs.error.withValues(alpha: 0.20),
          iconBackground: cs.error.withValues(alpha: 0.14),
        );
      case InsightSeverity.watch:
        const amber = AppColors.warning;
        return _SeverityColors(
          accent: amber,
          background: amber.withValues(alpha: 0.08),
          border: amber.withValues(alpha: 0.20),
          iconBackground: amber.withValues(alpha: 0.14),
        );
      case InsightSeverity.info:
        return _SeverityColors(
          accent: cs.primary,
          background: cs.primary.withValues(alpha: 0.06),
          border: cs.primary.withValues(alpha: 0.18),
          iconBackground: cs.primary.withValues(alpha: 0.12),
        );
    }
  }
}

/// A card displaying a guidance insight with optional action and dismiss.
class InsightCard extends StatelessWidget {
  final InsightSeverity severity;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;
  final String dismissTooltip;
  final String? secondaryText;
  final List<String>? details;

  const InsightCard({
    super.key,
    required this.severity,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
    required this.dismissTooltip,
    this.secondaryText,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final colors = _SeverityColors.from(severity, colorScheme);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 2.h),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 3.5.w,
          vertical: 3.w,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
                      // Title row: icon badge + title + dismiss
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Icon badge
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: colors.iconBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _severityIcon(severity),
                              size: 18,
                              color: colors.accent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Title
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Dismiss button
                          Tooltip(
                            message: dismissTooltip,
                            child: InkWell(
                              onTap: onDismiss,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.60),
                                  semanticLabel: dismissTooltip,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Body text
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                      // Secondary text (explainability v1)
                      if (secondaryText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          secondaryText!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // Details lines (explainability v2)
                      if (details != null && details!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...details!.map((line) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                line,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      // Action link
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: onAction,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  actionLabel!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                  color: colors.accent,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
          ],
        ),
      ),
    );
  }

  /// Returns the icon for the severity badge.
  IconData _severityIcon(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.risk:
        return Icons.warning_amber_rounded;
      case InsightSeverity.watch:
        return Icons.visibility_outlined;
      case InsightSeverity.info:
        return Icons.info_outline_rounded;
    }
  }
}
