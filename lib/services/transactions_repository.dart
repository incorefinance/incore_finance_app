// lib/services/transactions_repository.dart
//
// Repository for the `transactions` table in Supabase.
// Used by:
//  - AddTransaction screen      -> addTransaction(...)
//  - Transactions list screen   -> getTransactionsForCurrentUserTyped()
//  - Dashboard home             -> getTransactionsByDateRangeTyped(...)

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/core/state/transactions_change_notifier.dart';
import 'package:incore_finance/core/logging/app_logger.dart';
import 'package:incore_finance/data/usage/usage_metrics_repository.dart';
import 'package:incore_finance/data/usage/supabase_windowed_usage_counter.dart';
import 'package:incore_finance/domain/entitlements/entitlement_service.dart';
import 'package:incore_finance/domain/entitlements/plan_type.dart';
import 'package:incore_finance/domain/usage/limit_reached_exception.dart';
import 'package:incore_finance/domain/usage/windowed_usage_counter.dart';
import 'package:incore_finance/services/subscription/subscription_service.dart';
import 'package:incore_finance/services/transaction_import_service.dart';
import 'protection_ledger_service.dart';
import 'safety_drawdown_reconciler.dart';

/// Result of a bulk import operation.
class ImportResult {
  final int imported;
  final List<ImportRowError> rowErrors;

  const ImportResult({required this.imported, required this.rowErrors});

  int get failed => rowErrors.length;
  bool get hasErrors => rowErrors.isNotEmpty;
}

/// Describes a single row that failed to import.
class ImportRowError {
  final int rowNumber;
  final String reason;

  const ImportRowError({required this.rowNumber, required this.reason});
}

class TransactionsRepository {
  final SupabaseClient _client;
  final WindowedUsageCounter _usageCounter;
  final SubscriptionService _subscriptionService;
  final EntitlementService _entitlementService;

  TransactionsRepository({
    SupabaseClient? client,
    WindowedUsageCounter? usageCounter,
    SubscriptionService? subscriptionService,
    EntitlementService? entitlementService,
  })  : _client = client ?? Supabase.instance.client,
        _usageCounter = usageCounter ?? SupabaseWindowedUsageCounter(),
        _subscriptionService = subscriptionService ?? SubscriptionService(),
        _entitlementService = entitlementService ?? EntitlementService();

  /// Insert a new transaction.
  ///
  /// Throws [LimitReachedException] if free user has reached their monthly limit.
  /// The paywall is presented before throwing, so UI callers should catch
  /// this exception and show an appropriate message.
  Future<void> addTransaction({
    required double amount,
    required String description,
    required String category,
    required String type, // "income" or "expense"
    required DateTime date,
    required String paymentMethod,
    String? client,
  }) async {
    // 1. Check plan and enforce limit BEFORE insert
    final plan = await _subscriptionService.getCurrentPlan();

    if (plan == PlanType.free) {
      final currentCount = await _usageCounter.transactionsThisMonth();
      final limit = _entitlementService.getLimitForMetric(
        UsageMetricsRepository.spendEntriesCount,
      );

      if (currentCount >= limit) {
        // Present paywall (no cooldown for limit gates)
        await _subscriptionService.presentPaywall(
          'limit_crossed_spend_entries_count',
        );
        // DO NOT save - throw exception so UI knows to stay on screen
        throw LimitReachedException(
          metricType: 'spend_entries_count',
          limit: limit,
          currentCount: currentCount,
        );
      }
    }

    // 2. Proceed with insert
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user');

    final payload = <String, dynamic>{
      'user_id': userId,
      'amount': amount,
      'description': description,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      // IMPORTANT: matches your Supabase schema exactly
      'client': client,
    };

    try {
      final response = await _client
          .from('transactions')
          .insert(payload)
          .select()
          .maybeSingle();

      // Notify listeners that transactions have changed
      TransactionsChangeNotifier.instance.markChanged();

      // === PROTECTION LEDGER WIRING ===
      // Allocate tax/safety credits for income, or reconcile drawdowns for expenses
      try {
        if (type == 'income') {
          // Parse the inserted transaction to get the ID
          if (response != null) {
            final insertedTx = TransactionRecord.fromMap(response);
            await ProtectionLedgerService().allocateOnIncomeCreated(insertedTx);
          }
        } else if (type == 'expense') {
          // Check for overspend after expense
          await SafetyDrawdownReconciler().reconcileIfNeeded();
        }
      } catch (e) {
        // Non-blocking: log but don't fail the transaction
        AppLogger.w('[TransactionsRepository] Protection ledger wiring failed', error: e);
      }
      // === END PROTECTION LEDGER WIRING ===

      // 3. Telemetry only - increment usage_metrics for analytics
      try {
        await UsageMetricsRepository().increment(
          UsageMetricsRepository.spendEntriesCount,
        );
      } catch (e) {
        // Log but don't fail the transaction
        AppLogger.w('Failed to increment spend_entries_count', error: e);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransaction({
    required String transactionId,
    required double amount,
    required String description,
    required String category,
    required String type, // "income" or "expense"
    required DateTime date,
    required String paymentMethod,
    String? client,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user');

    final payload = <String, dynamic>{
      'amount': amount,
      'description': description,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'client': client,
    };

    await _client
        .from('transactions')
        .update(payload)
        .eq('id', transactionId)
        .eq('user_id', userId);

    // Notify listeners that transactions have changed
    TransactionsChangeNotifier.instance.markChanged();

    // === PROTECTION LEDGER WIRING ===
    try {
      if (type == 'income') {
        // Reallocate credits for updated income
        // Build a TransactionRecord for the service
        final updatedTx = TransactionRecord(
          id: transactionId,
          userId: userId,
          amount: amount,
          description: description,
          category: category,
          type: type,
          date: date,
          paymentMethod: paymentMethod,
          client: client,
        );
        await ProtectionLedgerService().reallocateOnIncomeUpdated(updatedTx);
      }
      // Always reconcile after any update (income or expense changes can affect balance)
      await SafetyDrawdownReconciler().reconcileIfNeeded();
    } catch (e) {
      AppLogger.w('[TransactionsRepository] Protection ledger wiring failed', error: e);
    }
    // === END PROTECTION LEDGER WIRING ===
  }

  Future<void> deleteTransaction({
    required String transactionId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user');

    // === PROTECTION LEDGER: Fetch type BEFORE delete ===
    String? transactionType;
    try {
      final existing = await _client
          .from('transactions')
          .select('type')
          .eq('id', transactionId)
          .eq('user_id', userId)
          .maybeSingle();
      transactionType = existing?['type']?.toString();
    } catch (e) {
      AppLogger.w('[TransactionsRepository] Failed to fetch transaction type before delete', error: e);
    }
    // === END FETCH ===

    try {
      await _client
          .from('transactions')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', transactionId)
          .eq('user_id', userId);

      // Notify listeners that transactions have changed
      TransactionsChangeNotifier.instance.markChanged();

      // === PROTECTION LEDGER WIRING ===
      try {
        if (transactionType == 'income') {
          final txId = int.tryParse(transactionId);
          if (txId != null) {
            await ProtectionLedgerService().removeAllocationsOnIncomeDeleted(txId);
          }
        }
        // Always reconcile after delete (balance may have changed)
        await SafetyDrawdownReconciler().reconcileIfNeeded();
      } catch (e) {
        AppLogger.w('[TransactionsRepository] Protection ledger wiring failed', error: e);
      }
      // === END PROTECTION LEDGER WIRING ===

      // Track usage metric for monetization
      try {
        await UsageMetricsRepository().decrement(
          UsageMetricsRepository.spendEntriesCount,
        );
      } catch (e) {
        // Log but don't fail the deletion
        AppLogger.w('Failed to decrement spend_entries_count', error: e);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Raw fetch: used by legacy code.
  Future<List<Map<String, dynamic>>> getTransactionsForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user');

    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  /// Typed fetch for the transactions list.
  Future<List<TransactionRecord>> getTransactionsForCurrentUserTyped() async {
    final raw = await getTransactionsForCurrentUser();

    return raw.map(TransactionRecord.fromMap).toList(growable: false);
  }

  /// Typed fetch by date range used by DashboardHome.
  Future<List<TransactionRecord>> getTransactionsByDateRangeTyped(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user');

    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .filter('deleted_at', 'is', null)
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        // For charts it is easier to work in ascending order
        .order('date', ascending: true)
        .order('created_at', ascending: true);

    return (response as List)
        .whereType<Map<String, dynamic>>()
        .map(TransactionRecord.fromMap)
        .toList(growable: false);
  }

  /// Bulk-import pre-validated rows from CSV/Excel.
  ///
  /// [rows] must already be validated — pass the output of
  /// `TransactionImportService().validRows(parsed)` so only clean rows arrive here.
  ///
  /// Free-tier users are limited to 20 rows per import batch.
  /// Premium users have no row limit.
  ///
  /// Duplicate detection: any row whose (date|amount|description|category|type)
  /// fingerprint already exists in Supabase is skipped and reported in [ImportResult.rowErrors].
  Future<ImportResult> importTransactions(
    List<TransactionImportRow> rows,
  ) async {
    if (rows.isEmpty) return const ImportResult(imported: 0, rowErrors: []);

    // 1. Free-tier row limit (20 rows per batch)
    final plan = await _subscriptionService.getCurrentPlan();
    if (plan == PlanType.free && rows.length > 20) {
      await _subscriptionService.presentPaywall('import_row_limit');
      throw LimitReachedException(
        metricType: 'import_rows',
        limit: 20,
        currentCount: rows.length,
      );
    }

    // 2. Deduplication: fetch fingerprints for the date range covered by the batch
    final fingerprints = await _fetchFingerprintsForRows(rows);

    // 3. Insert rows sequentially (preserves protection ledger ordering)
    int successCount = 0;
    final List<ImportRowError> rowErrors = [];

    for (final row in rows) {
      final fp = _fingerprint(row);
      if (fingerprints.contains(fp)) {
        rowErrors.add(ImportRowError(
          rowNumber: row.rowNumber,
          reason: 'Duplicate — this transaction already exists',
        ));
        continue;
      }

      try {
        await addTransaction(
          amount: row.amount!,
          description: row.description!,
          category: row.category!,
          type: row.type!,
          date: row.date!,
          paymentMethod: row.paymentMethod!,
          client: row.client,
        );
        successCount++;
        fingerprints.add(fp); // prevent in-file duplicates
      } on LimitReachedException {
        rethrow; // bubble up so UI can handle paywall
      } catch (e) {
        rowErrors.add(ImportRowError(
          rowNumber: row.rowNumber,
          reason: 'Failed to save: ${e.toString()}',
        ));
      }
    }

    // 4. Single UI refresh after the full batch
    if (successCount > 0) {
      TransactionsChangeNotifier.instance.markChanged();
    }

    return ImportResult(imported: successCount, rowErrors: rowErrors);
  }

  /// Builds a fingerprint string for a row: date|amount|description|category|type.
  static String _fingerprint(TransactionImportRow row) {
    final dateStr = row.date!.toIso8601String().substring(0, 10);
    return '$dateStr|${row.amount}|${row.description}|${row.category}|${row.type}';
  }

  /// Queries Supabase for existing transactions in the date range covered by [rows]
  /// and returns a mutable Set of fingerprints.
  Future<Set<String>> _fetchFingerprintsForRows(
    List<TransactionImportRow> rows,
  ) async {
    final dates = rows.where((r) => r.date != null).map((r) => r.date!);
    if (dates.isEmpty) return {};

    final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user');

    try {
      final response = await _client
          .from('transactions')
          .select('date, amount, description, category, type')
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .gte('date', minDate.toIso8601String())
          .lte('date', maxDate.toIso8601String());

      final set = <String>{};
      for (final row in (response as List).cast<Map<String, dynamic>>()) {
        final rawDate = row['date']?.toString() ?? '';
        final dateStr = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;
        final fp =
            '$dateStr|${row['amount']}|${row['description']}|${row['category']}|${row['type']}';
        set.add(fp);
      }
      return set;
    } catch (e) {
      AppLogger.w('[TransactionsRepository] Failed to fetch fingerprints for dedup', error: e);
      return {}; // if we can't check, proceed without dedup
    }
  }

  /// Restore a soft-deleted transaction.
  Future<void> restoreTransaction({
    required String transactionId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user');

    await _client
        .from('transactions')
        .update({'deleted_at': null})
        .eq('id', transactionId)
        .eq('user_id', userId);

    // Notify listeners that transactions have changed
    TransactionsChangeNotifier.instance.markChanged();

    // Track usage metric for monetization (restoring adds back to count)
    try {
      await UsageMetricsRepository().increment(
        UsageMetricsRepository.spendEntriesCount,
      );
    } catch (e) {
      // Log but don't fail the restore
      AppLogger.w('Failed to increment spend_entries_count on restore', error: e);
    }
  }
}
