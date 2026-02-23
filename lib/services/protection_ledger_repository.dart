// lib/services/protection_ledger_repository.dart
//
// Repository for the `protection_ledger` table in Supabase.
// Handles CRUD operations and aggregation for tax/safety allocations.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/logging/app_logger.dart';
import '../models/protection_ledger_entry.dart';
import '../models/protection_snapshot.dart';

class ProtectionLedgerRepository {
  final SupabaseClient _client;

  ProtectionLedgerRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // =========================================================================
  // INSERT (Auth-Injected)
  // =========================================================================

  /// Insert credit entries for an income transaction.
  ///
  /// userId is injected from auth, NOT passed in the model.
  /// This ensures security - client cannot spoof userId.
  Future<void> insertCreditEntries({
    required int sourceTransactionId,
    required double taxAmount,
    required double taxPercent,
    required double safetyAmount,
    required double safetyPercent,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot insert credit entries: No authenticated user.');
    }

    final entries = <Map<String, dynamic>>[];

    if (taxAmount > 0) {
      entries.add({
        'user_id': userId,
        'source_transaction_id': sourceTransactionId,
        'allocation_type': 'tax',
        'direction': 'credit',
        'percentage_at_time': taxPercent,
        'amount': taxAmount,
        // effective_at NOT included - DB trigger sets from source transaction date
      });
    }

    if (safetyAmount > 0) {
      entries.add({
        'user_id': userId,
        'source_transaction_id': sourceTransactionId,
        'allocation_type': 'safety',
        'direction': 'credit',
        'percentage_at_time': safetyPercent,
        'amount': safetyAmount,
        // effective_at NOT included - DB trigger sets from source transaction date
      });
    }

    if (entries.isEmpty) {
      AppLogger.d('[ProtectionLedger] No credits to insert (0% rates or 0 amounts)');
      return;
    }

    await _client.from('protection_ledger').insert(entries);
    AppLogger.d('[ProtectionLedger] Inserted ${entries.length} credit entries for tx $sourceTransactionId');
  }

  /// Insert a safety debit entry for overspend drawdown.
  ///
  /// userId is injected from auth, NOT passed in.
  /// effective_at is set explicitly (DB trigger only works for credits with source_transaction_id).
  Future<void> insertSafetyDebit({
    required double amount,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot insert safety debit: No authenticated user.');
    }

    final payload = {
      'user_id': userId,
      'allocation_type': 'safety',
      'direction': 'debit',
      'amount': amount,
      'effective_at': DateTime.now().toUtc().toIso8601String(),
      // source_transaction_id: null (debits don't come from income)
      // trigger_transaction_id: null (could be enhanced later)
      // percentage_at_time: null (N/A for debits)
    };

    await _client.from('protection_ledger').insert(payload);
    AppLogger.d('[ProtectionLedger] Inserted safety debit of $amount');
  }

  // =========================================================================
  // INSERT (Legacy - Model-Based)
  // =========================================================================

  /// Insert multiple ledger entries in a single batch.
  /// Each entry must have userId already set on the model.
  Future<void> insertEntries(List<ProtectionLedgerEntry> entries) async {
    if (entries.isEmpty) return;

    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot insert ledger entries: No authenticated user.');
    }

    // Verify all entries belong to current user
    for (final entry in entries) {
      if (entry.userId != userId) {
        throw StateError(
          'Entry userId (${entry.userId}) does not match current user ($userId)',
        );
      }
    }

    final payloads = entries.map((e) => e.toInsertMap()).toList();

    await _client.from('protection_ledger').insert(payloads);

    AppLogger.d('[ProtectionLedger] Inserted ${entries.length} entries');
  }

  /// Insert a single ledger entry.
  Future<void> insertEntry(ProtectionLedgerEntry entry) async {
    await insertEntries([entry]);
  }

  // =========================================================================
  // DELETE
  // =========================================================================

  /// Delete all ledger entries linked to a source transaction.
  /// Used when an income transaction is deleted.
  Future<void> deleteBySourceTransactionId(int sourceTransactionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot delete ledger entries: No authenticated user.');
    }

    await _client
        .from('protection_ledger')
        .delete()
        .eq('user_id', userId)
        .eq('source_transaction_id', sourceTransactionId);

    AppLogger.d(
      '[ProtectionLedger] Deleted entries for source_transaction_id: '
      '$sourceTransactionId',
    );
  }

  // =========================================================================
  // AGGREGATION (Server-side for precision)
  // =========================================================================

  /// Compute sum of protected amount for a given allocation type.
  /// Returns: sum(credits) - sum(debits) for the allocation type.
  /// Uses SQL aggregation via RPC for precision.
  ///
  /// Throws if RPC function is not available - fail loudly, don't approximate.
  Future<double> sumProtected(ProtectionAllocationType allocationType) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot sum protected: No authenticated user.');
    }

    // RPC uses auth.uid() internally, p_allocation_type is the only param
    final response = await _client.rpc(
      'sum_protected',
      params: {
        'p_allocation_type': allocationType.dbValue,
      },
    );

    if (response == null) return 0.0;

    // Parse result (could be int, double, or string from Postgres NUMERIC)
    if (response is num) return response.toDouble();
    if (response is String) return double.tryParse(response) ?? 0.0;
    return 0.0;
  }

  /// Compute sum of all protected amounts (tax and safety).
  /// Returns map with 'tax' and 'safety' keys.
  Future<Map<String, double>> sumAllProtected() async {
    final results = await Future.wait([
      sumProtected(ProtectionAllocationType.tax),
      sumProtected(ProtectionAllocationType.safety),
    ]);

    return {
      'tax': results[0],
      'safety': results[1],
    };
  }

  // =========================================================================
  // QUERY
  // =========================================================================

  /// Check if any ledger entries exist for a user.
  /// Useful for backfill detection.
  Future<bool> hasEntriesForUser(String userId) async {
    final response = await _client
        .from('protection_ledger')
        .select('id')
        .eq('user_id', userId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  /// Check if ledger entries exist for a specific source transaction.
  Future<bool> hasEntriesForSourceTransaction(int sourceTransactionId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('protection_ledger')
        .select('id')
        .eq('user_id', userId)
        .eq('source_transaction_id', sourceTransactionId)
        .limit(1);

    return (response as List).isNotEmpty;
  }

  // =========================================================================
  // SNAPSHOT (Server-side unified query)
  // =========================================================================

  /// Fetch unified protection snapshot for the authenticated user.
  ///
  /// Returns all protection metrics in a single RPC call:
  /// - tax_protected, safety_protected
  /// - balance, safe_to_spend
  /// - avg_monthly_expenses, months_used, confidence
  ///
  /// Throws if RPC is not available or user not authenticated.
  Future<ProtectionSnapshot> getProtectionSnapshot() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot get protection snapshot: No authenticated user.');
    }

    final response = await _client.rpc('get_protection_snapshot');

    // RPC returns a List with TABLE return type
    if (response == null || (response is List && response.isEmpty)) {
      // Return zero snapshot if no data
      return const ProtectionSnapshot(
        taxProtected: 0,
        safetyProtected: 0,
        balance: 0,
        safeToSpend: 0,
        avgMonthlyExpenses: 0,
        monthsUsed: 0,
        confidence: ConfidenceLevel.low,
      );
    }

    // Parse first row from response
    final Map<String, dynamic> row;
    if (response is List) {
      row = response.first as Map<String, dynamic>;
    } else if (response is Map<String, dynamic>) {
      row = response;
    } else {
      throw StateError('Unexpected RPC response type: ${response.runtimeType}');
    }

    return ProtectionSnapshot.fromMap(row);
  }

  // =========================================================================
  // MONTHLY SERIES (for sparkline visualization)
  // =========================================================================

  /// Fetch monthly protection series for sparkline visualization.
  ///
  /// Returns last N months of data grouped by month and allocation type.
  /// Each point contains net amount (credits minus debits) for that month.
  ///
  /// SQL RPC to add in Supabase SQL editor:
  /// ```sql
  /// CREATE OR REPLACE FUNCTION public.get_protection_monthly_series(
  ///   p_months INT DEFAULT 6
  /// )
  /// RETURNS TABLE (
  ///   month_key TEXT,
  ///   allocation_type TEXT,
  ///   net_amount NUMERIC
  /// )
  /// LANGUAGE sql
  /// SECURITY INVOKER
  /// AS $$
  ///   SELECT
  ///     TO_CHAR(effective_at, 'YYYY-MM') AS month_key,
  ///     allocation_type,
  ///     SUM(CASE WHEN direction = 'credit' THEN amount ELSE -amount END) AS net_amount
  ///   FROM protection_ledger
  ///   WHERE user_id = auth.uid()
  ///     AND effective_at >= DATE_TRUNC('month', CURRENT_DATE) - (p_months - 1) * INTERVAL '1 month'
  ///   GROUP BY TO_CHAR(effective_at, 'YYYY-MM'), allocation_type
  ///   ORDER BY month_key ASC, allocation_type ASC;
  /// $$;
  /// ```
  ///
  /// Returns empty list if RPC not available or user not authenticated.
  Future<List<Map<String, dynamic>>> getProtectionMonthlySeries({
    int months = 6,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      AppLogger.w('[ProtectionLedger] Cannot get monthly series: No authenticated user.');
      return [];
    }

    try {
      final response = await _client.rpc(
        'get_protection_monthly_series',
        params: {'p_months': months},
      );

      if (response == null) return [];

      if (response is List) {
        return response.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e) {
      // RPC might not exist yet, return empty gracefully
      AppLogger.w('[ProtectionLedger] get_protection_monthly_series RPC failed', error: e);
      return [];
    }
  }

  // =========================================================================
  // IDEMPOTENCY HELPERS
  // =========================================================================

  /// Check if a recent matching safety debit exists.
  ///
  /// Used by SafetyDrawdownReconciler to prevent duplicate debits.
  /// Matches on: direction=debit, allocation_type=safety, trigger_transaction_id IS NULL,
  /// amount within tolerance, created_at within window.
  ///
  /// NOTE: This is a temporary soft idempotency guard. It prevents runaway duplicates
  /// but is not deterministic. Phase 5 will add a proper unique constraint or
  /// overspend_key for true idempotency.
  Future<bool> hasRecentMatchingSafetyDebit({
    required double amount,
    required Duration window,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final cutoff = DateTime.now().toUtc().subtract(window);

    final response = await _client
        .from('protection_ledger')
        .select('amount')
        .eq('user_id', userId)
        .eq('direction', 'debit')
        .eq('allocation_type', 'safety')
        .isFilter('trigger_transaction_id', null)
        .gte('created_at', cutoff.toIso8601String())
        .limit(10);

    if ((response as List).isEmpty) {
      return false;
    }

    // Check amounts with tolerance (floating point comparison)
    for (final row in response) {
      final rowAmount = _parseNumeric(row['amount']);
      if ((rowAmount - amount).abs() < 0.01) {
        return true;
      }
    }

    return false;
  }

  /// Get current authenticated user ID.
  String? getCurrentUserId() {
    return _client.auth.currentUser?.id;
  }

  /// Parse NUMERIC from Supabase (could be int, double, String).
  static double _parseNumeric(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
