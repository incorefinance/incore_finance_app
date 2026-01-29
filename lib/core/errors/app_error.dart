/// Error categories for routing to appropriate UI treatment.
enum AppErrorCategory {
  /// Network-related errors (no connectivity, timeout, DNS failure).
  /// UI: Show retry action, wifi_off icon.
  network,

  /// Authentication errors (session expired, invalid token, unauthorized).
  /// UI: Show "Log in again" action, lock icon.
  auth,

  /// Unknown/unexpected errors.
  /// UI: Show retry if callback provided, generic error icon.
  unknown,
}

/// Structured error representation for consistent UI handling.
///
/// Important: This class does NOT store localized strings.
/// The widget resolves localized text via AppLocalizations in build().
class AppError {
  /// The category determines UI treatment and available actions.
  final AppErrorCategory category;

  /// Debug-only reason for logging (never shown to users).
  final String? debugReason;

  /// Original exception for logging purposes.
  final Object? originalError;

  /// Stack trace for debugging.
  final StackTrace? stackTrace;

  const AppError({
    required this.category,
    this.debugReason,
    this.originalError,
    this.stackTrace,
  });

  /// Factory for network errors.
  factory AppError.network({
    String? debugReason,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      category: AppErrorCategory.network,
      debugReason: debugReason,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory for auth errors.
  factory AppError.auth({
    String? debugReason,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      category: AppErrorCategory.auth,
      debugReason: debugReason,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  /// Factory for unknown errors.
  factory AppError.unknown({
    String? debugReason,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      category: AppErrorCategory.unknown,
      debugReason: debugReason,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() {
    return 'AppError(category: $category, debugReason: $debugReason)';
  }
}
