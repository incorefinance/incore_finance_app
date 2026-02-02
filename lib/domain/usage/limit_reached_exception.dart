// lib/domain/usage/limit_reached_exception.dart
//
// Exception thrown when a free user attempts to exceed their usage limit.

/// Exception thrown when a free user attempts to exceed their usage limit.
///
/// UI callers should catch this and handle gracefully (paywall already shown).
/// The repository will have already presented the paywall before throwing.
///
/// Example:
/// ```dart
/// try {
///   await repository.addTransaction(...);
/// } on LimitReachedException {
///   // Paywall was shown, user did not upgrade
///   // Stay on screen so user can try again or go back
///   SnackbarHelper.showInfo(context, l10n.limitReachedMonthly);
/// }
/// ```
class LimitReachedException implements Exception {
  /// The type of metric that reached its limit.
  final String metricType;

  /// The limit that was reached.
  final int limit;

  /// The current count when the limit was hit.
  final int currentCount;

  const LimitReachedException({
    required this.metricType,
    required this.limit,
    required this.currentCount,
  });

  @override
  String toString() =>
      'LimitReachedException: $metricType limit $limit reached (current: $currentCount)';
}
