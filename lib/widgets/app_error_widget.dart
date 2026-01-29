import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../core/errors/app_error.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Display mode for the error widget.
enum AppErrorDisplayMode {
  /// Full-screen error display with centered content.
  /// Use for: Replacing entire screen content.
  fullScreen,

  /// Inline error display within a card or section.
  /// Use for: Replacing a section that failed to load.
  inline,

  /// Compact error display with minimal height.
  /// Use for: Showing error in constrained spaces.
  compact,
}

/// Reusable error state widget supporting multiple display modes and error categories.
///
/// Important: This widget resolves localized text via AppLocalizations in build()
/// to support live locale switching. The AppError object contains NO localized strings.
///
/// Usage:
/// ```dart
/// // Full screen error with retry
/// AppErrorWidget(
///   error: appError,
///   displayMode: AppErrorDisplayMode.fullScreen,
///   onRetry: _loadData,
/// )
///
/// // Inline error within a card
/// AppErrorWidget(
///   error: appError,
///   displayMode: AppErrorDisplayMode.inline,
///   onRetry: _loadSectionData,
/// )
///
/// // Auth error (caller provides action callback)
/// AppErrorWidget(
///   error: appError,
///   displayMode: AppErrorDisplayMode.fullScreen,
///   onPrimaryAction: () => AuthGuard.routeToErrorIfInvalid(context),
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  /// The structured error to display.
  final AppError error;

  /// How to display the error (fullScreen, inline, compact).
  final AppErrorDisplayMode displayMode;

  /// Optional retry callback for network/unknown errors.
  final VoidCallback? onRetry;

  /// Optional primary action callback (overrides default behavior).
  /// For auth errors, caller should provide this to handle sign out and navigation.
  final VoidCallback? onPrimaryAction;

  const AppErrorWidget({
    super.key,
    required this.error,
    this.displayMode = AppErrorDisplayMode.inline,
    this.onRetry,
    this.onPrimaryAction,
  });

  @override
  Widget build(BuildContext context) {
    switch (displayMode) {
      case AppErrorDisplayMode.fullScreen:
        return _buildFullScreen(context);
      case AppErrorDisplayMode.inline:
        return _buildInline(context);
      case AppErrorDisplayMode.compact:
        return _buildCompact(context);
    }
  }

  Widget _buildFullScreen(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final title = _getTitleForCategory(error.category, l10n);
    final message = _getMessageForCategory(error.category, l10n);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIcon(context, size: 64),
            SizedBox(height: 3.h),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.5.h),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            _buildActionButton(context, l10n, isFullWidth: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInline(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final title = _getTitleForCategory(error.category, l10n);
    final message = _getMessageForCategory(error.category, l10n);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(context, size: 48),
          SizedBox(height: 2.h),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 1.h),
          Text(
            message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          _buildActionButton(context, l10n, isFullWidth: false),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final title = _getTitleForCategory(error.category, l10n);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _buildIcon(context, size: 24),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_hasAction)
            TextButton(
              onPressed: _getActionCallback(),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _getActionLabel(l10n),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIcon(BuildContext context, {required double size}) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData iconData;
    Color iconColor;

    switch (error.category) {
      case AppErrorCategory.network:
        iconData = Icons.wifi_off;
        iconColor = colorScheme.error;
        break;
      case AppErrorCategory.auth:
        iconData = Icons.lock_outline;
        iconColor = AppColors.error;
        break;
      case AppErrorCategory.unknown:
        iconData = Icons.error_outline;
        iconColor = colorScheme.error;
        break;
    }

    return Icon(iconData, size: size, color: iconColor);
  }

  Widget _buildActionButton(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isFullWidth,
  }) {
    if (!_hasAction) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final label = _getActionLabel(l10n);
    final callback = _getActionCallback();

    final button = ElevatedButton(
      onPressed: callback,
      style: ElevatedButton.styleFrom(
        backgroundColor: error.category == AppErrorCategory.auth
            ? AppColors.primary
            : colorScheme.primary,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: 6.w,
          vertical: 1.5.h,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
      child: Text(label),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }
    return button;
  }

  bool get _hasAction {
    // Custom action always shows
    if (onPrimaryAction != null) return true;
    // Auth errors show action if callback provided
    if (error.category == AppErrorCategory.auth) return onPrimaryAction != null;
    // Network/unknown errors show retry if callback provided
    return onRetry != null;
  }

  String _getActionLabel(AppLocalizations l10n) {
    switch (error.category) {
      case AppErrorCategory.auth:
        return l10n.logInAgain;
      case AppErrorCategory.network:
      case AppErrorCategory.unknown:
        return l10n.retry;
    }
  }

  VoidCallback? _getActionCallback() {
    if (onPrimaryAction != null) return onPrimaryAction;

    switch (error.category) {
      case AppErrorCategory.auth:
        // Widget does NOT hardcode navigation.
        // Caller must provide onPrimaryAction for auth errors.
        return onPrimaryAction;
      case AppErrorCategory.network:
      case AppErrorCategory.unknown:
        return onRetry;
    }
  }

  /// Get localized title based on error category.
  String _getTitleForCategory(AppErrorCategory category, AppLocalizations l10n) {
    switch (category) {
      case AppErrorCategory.network:
        return l10n.networkErrorTitle;
      case AppErrorCategory.auth:
        return l10n.authErrorTitle;
      case AppErrorCategory.unknown:
        return l10n.unknownErrorTitle;
    }
  }

  /// Get localized message based on error category.
  String _getMessageForCategory(
      AppErrorCategory category, AppLocalizations l10n) {
    switch (category) {
      case AppErrorCategory.network:
        return l10n.networkErrorMessage;
      case AppErrorCategory.auth:
        return l10n.authErrorDescription;
      case AppErrorCategory.unknown:
        return l10n.unknownErrorMessage;
    }
  }
}
