// lib/domain/usage/windowed_usage_counter.dart
//
// Pure interface for counting usage within time windows.
// Implementation queries source tables directly, NOT usage_metrics.

/// Pure interface for counting usage within time windows.
///
/// Implementations query source tables directly (transactions, recurring_expenses)
/// rather than the usage_metrics table, which is used for telemetry only.
///
/// Window semantics:
/// - Transactions: calendar month based on user-selected date
/// - Recurring expenses: count of currently active items (no time window)
/// - Income events: calendar month based on user-selected date
abstract class WindowedUsageCounter {
  /// Count transactions in the current calendar month.
  ///
  /// Counts transactions where the user-selected `date` falls within
  /// the current month boundaries. Excludes soft-deleted records.
  Future<int> transactionsThisMonth();

  /// Count active recurring expenses.
  ///
  /// Counts recurring expenses where `is_active = true`.
  /// This is not time-windowed; it reflects the current active count.
  Future<int> activeRecurringExpenses();

  /// Count income events in the current calendar month.
  ///
  /// Returns 0 if income_events table doesn't exist yet.
  Future<int> incomeEventsThisMonth();
}
