// lib/services/transactions_repository.dart

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

  /// Add a new transaction for the current user.
  ///
  /// This matches the call you already have in add_transaction.dart:
  /// _transactionsRepository.addTransaction(
  ///   amount: amount,
  ///   description: _descriptionController.text,
  ///   category: _selectedCategory!,
  ///   type: _selectedType!,
  ///   date: _selectedDate,
  ///   paymentMethod: _selectedPaymentMethod,
  ///   client: _clientName!,
  /// );
  Future<void> addTransaction({
    required double amount,
    required String description,
    required String category,
    required String type,
    required DateTime date,
    String? paymentMethod,
    String? client,

  }) async {
    final userId = _supabaseService.currentUserId;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final payload = {
      'user_id': userId,
      'amount': amount,
      'description': description,
      'category': category,
      'type': type,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod,
      'client_name': client,
    };

    await _client.from('transactions').insert(payload);
  }

  /// Basic fetch used by the Transactions List screen (Sprint 01).
  ///
  /// NOTE: this returns a List<Map<String, dynamic>> because the original
  /// transactions_list.dart expects raw maps.
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

    return response
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }
  /// Typed version of getTransactionsForCurrentUser.
  ///
  /// This is used by parts of the app that expect List<TransactionRecord>
  /// instead of raw maps. It simply reuses the existing fetch and maps
  /// each row with TransactionRecord.fromMap.
  Future<List<TransactionRecord>> getTransactionsForCurrentUserTyped() async {
    final raw = await getTransactionsForCurrentUser();

    return raw
      .map(TransactionRecord.fromMap)
      .toList(growable: false);
  }

  /// Typed fetch used by Dashboard Home for monthly profit, top expenses, etc.
  ///
  /// ThisTransactionRecord matches the calls you have in dashboard_home.dart:
  ///   getTransactionsByDateRangeTyped(startDate, endDate)
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
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return response
        .whereType<Map<String, dynamic>>()
        .map(TransactionRecord.fromMap)
        .toList(growable: false);
  }
}
