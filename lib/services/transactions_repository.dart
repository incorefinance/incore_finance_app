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
import 'protection_ledger_service.dart';
import 'safety_drawdown_reconciler.dart';

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
    final userId = _client.auth.currentUser!.id;

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

    // Debug logging while we are fixing Sprint 01
    // ignore: avoid_print
    print('addTransaction() -> payload: $payload');

    try {
      final response = await _client
          .from('transactions')
          .insert(payload)
          .select()
          .maybeSingle();

      // ignore: avoid_print
      print('addTransaction() -> insert response: $response');

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
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('=== SUPABASE INSERT ERROR ===');
      // ignore: avoid_print
      print('Error: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
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
    final userId = _client.auth.currentUser!.id;

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
    final userId = _client.auth.currentUser!.id;

    // ignore: avoid_print
    print('=== DELETE TRANSACTION START ===');
    // ignore: avoid_print
    print('Transaction ID: $transactionId');
    // ignore: avoid_print
    print('User ID: $userId');

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
      final response = await _client
          .from('transactions')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', transactionId)
          .eq('user_id', userId);

      // ignore: avoid_print
      print('=== DELETE TRANSACTION SUCCESS ===');
      // ignore: avoid_print
      print('Response: $response');

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
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('=== DELETE TRANSACTION ERROR ===');
      // ignore: avoid_print
      print('Error: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Raw fetch: used by legacy code.
  Future<List<Map<String, dynamic>>> getTransactionsForCurrentUser() async {
    final userId = _client.auth.currentUser!.id;

    // ignore: avoid_print
    print('=== TRANSACTIONS FETCH ===');
    // ignore: avoid_print
    print('Table: transactions, user_id (UUID): $userId');

    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .filter('deleted_at', 'is', null)
          .order('date', ascending: false)
          .order('created_at', ascending: false);

      // ignore: avoid_print
      print('Fetch success: ${(response as List).length} transactions');

      return response
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('=== TRANSACTIONS FETCH ERROR ===');
      // ignore: avoid_print
      print('Error: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
      rethrow;
    }
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
    final userId = _client.auth.currentUser!.id;

    // ignore: avoid_print
    print('=== TRANSACTIONS DATE RANGE FETCH ===');
    // ignore: avoid_print
    print('Table: transactions, user_id (UUID): $userId');
    // ignore: avoid_print
    print('Date range: $startDate to $endDate');

    try {
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

      // ignore: avoid_print
      print('Date range fetch success: ${(response as List).length} transactions');

      return response
          .whereType<Map<String, dynamic>>()
          .map(TransactionRecord.fromMap)
          .toList(growable: false);
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('=== TRANSACTIONS DATE RANGE FETCH ERROR ===');
      // ignore: avoid_print
      print('Error: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
      rethrow;
    }
  }

  /// Restore a soft-deleted transaction.
  Future<void> restoreTransaction({
    required String transactionId,
  }) async {
    final userId = _client.auth.currentUser!.id;

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

// TODO: When income events feature is implemented, wire:
// - increment(UsageMetricsRepository.incomeEventsCount) on create
// - decrement(UsageMetricsRepository.incomeEventsCount) on delete
