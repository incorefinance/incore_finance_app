// lib/domain/usage/month_window.dart
//
// Pure helpers for month boundary calculations.
// Separate from interface to keep domain clean and enable easy unit testing.

/// Mode for month boundary calculation based on database column type.
enum MonthWindowMode {
  /// For date-only columns - no time component, local timezone.
  dateOnly,

  /// For timestamptz columns - convert to UTC for database queries.
  timestamptz,
}

/// Calculate start of month containing [date].
///
/// For [MonthWindowMode.dateOnly]: returns local DateTime at midnight.
/// For [MonthWindowMode.timestamptz]: returns UTC DateTime at midnight.
DateTime getMonthStart(DateTime date, MonthWindowMode mode) {
  final localStart = DateTime(date.year, date.month, 1);
  return mode == MonthWindowMode.timestamptz ? localStart.toUtc() : localStart;
}

/// Calculate start of month after [date].
///
/// For [MonthWindowMode.dateOnly]: returns local DateTime at midnight.
/// For [MonthWindowMode.timestamptz]: returns UTC DateTime at midnight.
///
/// Dart's DateTime constructor handles month overflow correctly:
/// DateTime(2026, 13, 1) becomes DateTime(2027, 1, 1).
DateTime getNextMonthStart(DateTime date, MonthWindowMode mode) {
  final localNext = DateTime(date.year, date.month + 1, 1);
  return mode == MonthWindowMode.timestamptz ? localNext.toUtc() : localNext;
}

/// Calculate current month boundaries for database queries.
///
/// Returns (monthStart, nextMonthStart) tuple.
/// Use for >= monthStart AND < nextMonthStart queries.
(DateTime, DateTime) getCurrentMonthBoundaries(MonthWindowMode mode) {
  final now = DateTime.now();
  return (getMonthStart(now, mode), getNextMonthStart(now, mode));
}
