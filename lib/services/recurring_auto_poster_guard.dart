// lib/services/recurring_auto_poster_guard.dart
//
// Ensures auto-posting runs at most once per app session.
// This prevents unnecessary database calls on every screen navigation.
//
// Usage:
//   if (!RecurringAutoPosterGuard.instance.shouldRun()) return;
//   try {
//     await poster.postDueRecurringExpenses(...);
//     RecurringAutoPosterGuard.instance.markComplete();
//   } catch (e) {
//     RecurringAutoPosterGuard.instance.markFailed();
//   }

class RecurringAutoPosterGuard {
  static final RecurringAutoPosterGuard instance = RecurringAutoPosterGuard._();
  RecurringAutoPosterGuard._();

  bool _hasRunThisSession = false;
  bool _isRunning = false;

  /// Returns true if should run, false if already ran or running.
  /// Automatically marks as running when returning true.
  bool shouldRun() {
    if (_hasRunThisSession || _isRunning) return false;
    _isRunning = true;
    return true;
  }

  /// Call after successful completion.
  /// Prevents any future runs this session.
  void markComplete() {
    _hasRunThisSession = true;
    _isRunning = false;
  }

  /// Call after failure.
  /// Allows retry on next entry point.
  void markFailed() {
    _isRunning = false;
    // Don't set _hasRunThisSession so it can retry
  }
}
