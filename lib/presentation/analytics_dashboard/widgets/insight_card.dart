import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../domain/guidance/insight_severity.dart';
import '../../../theme/app_colors.dart';

/// Precomputed severity-based colors for the insight card.
class _SeverityColors {
  final Color gradientStart;
  final Color gradientEnd;
  final Color border;
  final Color iconBackground;
  final Color iconColor;
  final Color titleColor;
  final Color bodyColor;
  final Color detailsColor;
  final Color ctaColor;
  final Color dismissColor;

  const _SeverityColors({
    required this.gradientStart,
    required this.gradientEnd,
    required this.border,
    required this.iconBackground,
    required this.iconColor,
    required this.titleColor,
    required this.bodyColor,
    required this.detailsColor,
    required this.ctaColor,
    required this.dismissColor,
  });

  factory _SeverityColors.from(InsightSeverity severity, ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;

    switch (severity) {
      case InsightSeverity.risk:
        return _SeverityColors(
          gradientStart: isDark
              ? AppColors.rose900.withValues(alpha: 0.30)
              : AppColors.rose50.withValues(alpha: 0.90),
          gradientEnd: isDark
              ? AppColors.rose900.withValues(alpha: 0.30)
              : AppColors.rose100.withValues(alpha: 0.90),
          border: isDark
              ? AppColors.rose900.withValues(alpha: 0.40)
              : AppColors.rose200.withValues(alpha: 0.60),
          iconBackground: isDark ? AppColors.rose600 : AppColors.rose500,
          iconColor: Colors.white,
          titleColor: isDark ? Colors.white : AppColors.slate900,
          bodyColor: isDark ? AppColors.slate300 : AppColors.slate600,
          detailsColor: isDark ? AppColors.slate400 : AppColors.slate500,
          ctaColor: isDark ? AppColors.rose400 : AppColors.rose700,
          dismissColor: AppColors.slate400,
        );
      case InsightSeverity.watch:
        return _SeverityColors(
          gradientStart: isDark
              ? AppColors.amber950.withValues(alpha: 0.30)
              : AppColors.amber50.withValues(alpha: 0.90),
          gradientEnd: isDark
              ? AppColors.orange950.withValues(alpha: 0.30)
              : AppColors.orange50.withValues(alpha: 0.90),
          border: isDark
              ? AppColors.amber900.withValues(alpha: 0.40)
              : AppColors.amber200.withValues(alpha: 0.60),
          iconBackground: isDark ? AppColors.amber600 : AppColors.amber500,
          iconColor: Colors.white,
          titleColor: isDark ? Colors.white : AppColors.slate900,
          bodyColor: isDark ? AppColors.slate300 : AppColors.slate600,
          detailsColor: isDark ? AppColors.slate400 : AppColors.slate500,
          ctaColor: isDark ? AppColors.amber400 : AppColors.amber700,
          dismissColor: AppColors.slate400,
        );
      case InsightSeverity.info:
        return _SeverityColors(
          gradientStart: isDark
              ? AppColors.blue600.withValues(alpha: 0.15)
              : AppColors.blueBg50.withValues(alpha: 0.90),
          gradientEnd: isDark
              ? AppColors.blue600.withValues(alpha: 0.15)
              : AppColors.blueBg50.withValues(alpha: 0.90),
          border: isDark
              ? AppColors.blue600.withValues(alpha: 0.30)
              : AppColors.blue600.withValues(alpha: 0.20),
          iconBackground: isDark ? AppColors.blue600 : AppColors.blue600,
          iconColor: Colors.white,
          titleColor: isDark ? Colors.white : AppColors.slate900,
          bodyColor: isDark ? AppColors.slate300 : AppColors.slate600,
          detailsColor: isDark ? AppColors.slate400 : AppColors.slate500,
          ctaColor: isDark ? AppColors.blue600 : AppColors.blue600,
          dismissColor: AppColors.slate400,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.gradientStart, colors.gradientEnd],
        ),
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
                // Icon badge - solid background with white icon
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
                    color: colors.iconColor,
                  ),
                ),
                const SizedBox(width: 10),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colors.titleColor,
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
                        size: 18,
                        color: colors.dismissColor,
                        semanticLabel: dismissTooltip,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Body text
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.bodyColor,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
            ),
            // Secondary text (explainability v1)
            if (secondaryText != null) ...[
              const SizedBox(height: 6),
              Text(
                secondaryText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.detailsColor,
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
                        color: colors.detailsColor,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )),
            ],
            // Action link
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onAction,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        actionLabel!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.ctaColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: colors.ctaColor,
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
        return Icons.error_outline_rounded;
      case InsightSeverity.info:
        return Icons.info_outline_rounded;
    }
  }
}
