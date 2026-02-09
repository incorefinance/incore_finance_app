import '../../domain/guidance/insight_id.dart';

/// Abstract interface for storing insight dismissal state.
abstract class InsightStateStore {
  /// Get the date until which the insight is dismissed.
  /// Returns null if not dismissed or dismissal has expired.
  Future<DateTime?> getDismissedUntil(InsightId id);

  /// Dismiss the insight for the specified number of days.
  Future<void> dismissForDays(InsightId id, int days);
}
