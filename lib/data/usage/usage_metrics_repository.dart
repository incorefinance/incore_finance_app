// lib/data/usage/usage_metrics_repository.dart
//
// Repository for tracking user usage metrics in Supabase.
// Tracks counts for spend entries, recurring expenses, and income events.

import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for tracking user usage metrics in Supabase.
///
/// Uses upsert pattern to safely handle concurrent updates.
/// Ensures decrement never goes below zero.
///
/// Database table: `usage_metrics`
/// Columns:
/// - user_id: uuid (references auth.users)
/// - metric_type: text (e.g., 'spend_entries_count')
/// - value: int (current count)
/// - last_crossed_limit_at: timestamptz (when limit was first exceeded)
/// - updated_at: timestamptz
class UsageMetricsRepository {
  final SupabaseClient _client;

  UsageMetricsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // =========================================================================
  // Metric Type Constants
  // =========================================================================

  /// Metric type for tracking spend entries (transactions).
  static const String spendEntriesCount = 'spend_entries_count';

  /// Metric type for tracking recurring expenses.
  static const String recurringExpensesCount = 'recurring_expenses_count';

  /// Metric type for tracking income events.
  static const String incomeEventsCount = 'income_events_count';

  // =========================================================================
  // Read Operations
  // =========================================================================

  /// Get current value for a metric type.
  ///
  /// Returns 0 if:
  /// - No user is authenticated
  /// - No row exists for this metric
  /// - The value column is null
  Future<int> getMetric(String metricType) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    try {
      final response = await _client
          .from('usage_metrics')
          .select('value')
          .eq('user_id', userId)
          .eq('metric_type', metricType)
          .maybeSingle();

      if (response == null) return 0;
      return response['value'] as int? ?? 0;
    } catch (_) {
      // If table doesn't exist or query fails, return 0
      return 0;
    }
  }

  /// Get when limit was last crossed.
  ///
  /// Returns null if:
  /// - No user is authenticated
  /// - No row exists for this metric
  /// - Limit has never been crossed
  Future<DateTime?> getLastCrossed(String metricType) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _client
          .from('usage_metrics')
          .select('last_crossed_limit_at')
          .eq('user_id', userId)
          .eq('metric_type', metricType)
          .maybeSingle();

      if (response == null) return null;
      final timestamp = response['last_crossed_limit_at'] as String?;
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (_) {
      return null;
    }
  }

  // =========================================================================
  // Write Operations
  // =========================================================================

  /// Increment a metric by the specified amount (default 1).
  ///
  /// Uses upsert to create row if not exists.
  /// Thread-safe through database upsert conflict handling.
  Future<void> increment(String metricType, {int by = 1}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final current = await getMetric(metricType);
    final newValue = current + by;

    await _client.from('usage_metrics').upsert(
      {
        'user_id': userId,
        'metric_type': metricType,
        'value': newValue,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,metric_type',
    );
  }

  /// Decrement a metric by the specified amount (default 1).
  ///
  /// Never goes below zero to maintain data integrity.
  Future<void> decrement(String metricType, {int by = 1}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final current = await getMetric(metricType);
    // Ensure we never go below zero
    final newValue = (current - by).clamp(0, current);

    await _client.from('usage_metrics').upsert(
      {
        'user_id': userId,
        'metric_type': metricType,
        'value': newValue,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,metric_type',
    );
  }

  /// Mark the timestamp when a limit was crossed.
  ///
  /// This is set when a user first exceeds their free plan limit.
  /// Used to track when to show paywalls and prevent spam.
  Future<void> markCrossed(String metricType) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    // We need to preserve the existing value when marking crossed
    final currentValue = await getMetric(metricType);

    await _client.from('usage_metrics').upsert(
      {
        'user_id': userId,
        'metric_type': metricType,
        'value': currentValue,
        'last_crossed_limit_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'user_id,metric_type',
    );
  }

  /// Clear the last_crossed_limit_at timestamp.
  ///
  /// Used when a user's count goes back below the limit
  /// (e.g., after deleting entries or upgrading and downgrading).
  Future<void> clearCrossed(String metricType) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('usage_metrics')
        .update({
          'last_crossed_limit_at': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('user_id', userId)
        .eq('metric_type', metricType);
  }
}
