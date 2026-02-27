// lib/data/usage/supabase_windowed_usage_counter.dart
//
// Supabase implementation of WindowedUsageCounter.
// Queries source tables directly for accurate window-based counts.
//
// Date Column Documentation:
// - Transaction monthly counting uses `date` column (user-selected date)
// - Type: timestamptz (stored as ISO8601 string) → using UTC-converted month boundaries
// - Backdated transactions: counted in the month the user selected, not when logged
// - Soft deletes: Filter with `deleted_at IS NULL`

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/usage/windowed_usage_counter.dart';
import '../../domain/usage/month_window.dart';

/// Supabase implementation of [WindowedUsageCounter].
///
/// Queries source tables directly:
/// - `transactions` table for spend entries (monthly window)
/// - `recurring_expenses` table for active recurring expenses
/// - `income_events` table for income events (monthly window) [TODO]
///
/// Uses Supabase exact count option for efficiency.
class SupabaseWindowedUsageCounter implements WindowedUsageCounter {
  final SupabaseClient _client;

  SupabaseWindowedUsageCounter({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<int> transactionsThisMonth() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    // Transaction `date` column is timestamptz, use UTC boundaries
    final (monthStart, nextMonthStart) =
        getCurrentMonthBoundaries(MonthWindowMode.timestamptz);

    try {
      // Use count query for efficiency - no data transfer, just count
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .gte('date', monthStart.toIso8601String())
          .lt('date', nextMonthStart.toIso8601String())
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      AppLogger.w('[UsageCounter] transactionsThisMonth failed', error: e);
      return 0;
    }
  }

  @override
  Future<int> activeRecurringExpenses() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      // Use count query for efficiency
      final response = await _client
          .from('recurring_expenses')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .count(CountOption.exact);

      return response.count;
    } catch (e) {
      AppLogger.w('[UsageCounter] activeRecurringExpenses failed', error: e);
      return 0;
    }
  }

  @override
  Future<int> incomeEventsThisMonth() async {
    return 0;
  }
}
