// lib/services/transactions_repository.dart
//
// Repository for the `transactions` table in Supabase.
// Used by:
//  - AddTransaction screen      -> addTransaction(...)
//  - Transactions list screen   -> getTransactionsForCurrentUserTyped()
//  - Dashboard home             -> getTransactionsByDateRangeTyped(...)

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:incore_finance/models/transaction_record.dart';
import 'package:incore_finance/services/supabase_service.dart';

class TransactionsRepository {
  final SupabaseClient _client;
  final SupabaseService _supabaseService;

  TransactionsRepository({
    SupabaseClient? client,
    SupabaseService? supabaseService,
  })  : _client = client ?? Supabase.instance.client,
        _supabaseService = supabaseService ?? SupabaseService.instance;

  /// Insert a new transaction.
  Future<void> addTransaction({
    required double amount,
    required String description,
    required String category,
    required String type, // "income" or "expense"
    required DateTime date,
    required String paymentMethod,
    String? client,
  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

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

  /// Raw fetch: used by legacy code.
  Future<List<Map<String, dynamic>>> getTransactionsForCurrentUser() async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  /// Typed fetch for the transactions list.
  Future<List<TransactionRecord>> getTransactionsForCurrentUserTyped() async {
    final raw = await getTransactionsForCurrentUser();

    return raw
        .map(TransactionRecord.fromMap)
        .toList(growable: false);
  }

  /// Typed fetch by date range used by DashboardHome.
  Future<List<TransactionRecord>> getTransactionsByDateRangeTyped(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
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
}
