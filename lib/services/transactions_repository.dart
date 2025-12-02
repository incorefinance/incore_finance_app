import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';

class TransactionsRepository {
  final SupabaseService _supabaseService = SupabaseService.instance;

  SupabaseClient get _client => _supabaseService.client;

  /// Add a new transaction to the database
  ///
  /// Parameters:
  /// - amount: Transaction amount (numeric)
  /// - description: Transaction description
  /// - category: Category ID (must match business_category enum)
  /// - type: Transaction type ('income' or 'expense')
  /// - date: Transaction date
  /// - paymentMethod: Payment method used
  /// - client: Optional client name
  Future<void> addTransaction({
    required double amount,
    required String description,
    required String category,
    required String type,
    required DateTime date,
    required String paymentMethod,
    String? client,
  }) async {
    try {
      await _client.from('transactions').insert({
        'amount': amount,
        'description': description,
        'category': category,
        'type': type,
        'date': date.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
        'payment_method': paymentMethod,
        'client': client,
        'user_id': _supabaseService.currentUserId,
      });
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  /// Get all transactions for the current user, ordered by date descending
  ///
  /// Returns a list of transaction maps with all fields
  Future<List<Map<String, dynamic>>> getTransactionsForCurrentUser() async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', _supabaseService.currentUserId)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  /// Get transactions filtered by category
  ///
  /// Parameters:
  /// - categoryId: The category to filter by
  ///
  /// Returns a list of transaction maps matching the category
  Future<List<Map<String, dynamic>>> getTransactionsByCategory(
      String categoryId) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', _supabaseService.currentUserId)
          .eq('category', categoryId)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch transactions by category: $e');
    }
  }

  /// Get transactions within a date range
  ///
  /// Parameters:
  /// - startDate: Start of date range
  /// - endDate: End of date range
  ///
  /// Returns a list of transaction maps within the date range
  Future<List<Map<String, dynamic>>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client
          .from('transactions')
          .select()
          .eq('user_id', _supabaseService.currentUserId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch transactions by date range: $e');
    }
  }
}
