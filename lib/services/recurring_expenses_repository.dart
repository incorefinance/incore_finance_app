// lib/services/recurring_expenses_repository.dart
//
// Repository for the `recurring_expenses` table in Supabase.
// Used by:
//  - Dashboard Home (upcoming bills placeholder, later wired)
//  - Short-term pressure logic (later ticket)
//
// Note: This repository handles data access only.
// Date calculations (clamp-to-last-day-of-month) are NOT implemented here.
// They belong in the short-term pressure logic (separate ticket).

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:incore_finance/models/recurring_expense.dart';

class RecurringExpensesRepository {
  final SupabaseClient _client;

  RecurringExpensesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // =========================================================================
  // READ
  // =========================================================================

  /// Fetches all recurring expenses for the current user.
  /// Returns both active and inactive expenses.
  Future<List<RecurringExpense>> getRecurringExpensesForCurrentUser() async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('recurring_expenses')
        .select()
        .eq('user_id', userId)
        .order('due_day', ascending: true)
        .order('name', ascending: true);

    return (response as List)
        .whereType<Map<String, dynamic>>()
        .map(RecurringExpense.fromMap)
        .toList(growable: false);
  }

  /// Fetches only active recurring expenses for the current user.
  /// Use this for Dashboard and short-term pressure calculations.
  Future<List<RecurringExpense>> getActiveRecurringExpenses() async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('recurring_expenses')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('due_day', ascending: true)
        .order('name', ascending: true);

    return (response as List)
        .whereType<Map<String, dynamic>>()
        .map(RecurringExpense.fromMap)
        .toList(growable: false);
  }

  /// Fetches a single recurring expense by ID.
  /// Returns null if not found or not owned by current user.
  Future<RecurringExpense?> getRecurringExpenseById(String id) async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('recurring_expenses')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return RecurringExpense.fromMap(response);
  }

  // =========================================================================
  // CREATE
  // =========================================================================

  /// Adds a new recurring expense for the current user.
  /// Returns the created RecurringExpense with its generated ID.
  /// Throws StateError if no user is authenticated.
  Future<RecurringExpense> addRecurringExpense({
    required String name,
    required double amount,
    required int dueDay,
    bool isActive = true,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw StateError(
        'Cannot add recurring expense: No authenticated user. '
        'Please log in first.',
      );
    }
    final userId = currentUser.id;

    // Validate constraints before sending to database
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
    if (dueDay < 1 || dueDay > 31) {
      throw ArgumentError('Due day must be between 1 and 31');
    }

    final payload = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'amount': amount,
      'due_day': dueDay,
      'is_active': isActive,
    };

    final response = await _client
        .from('recurring_expenses')
        .insert(payload)
        .select()
        .single();

    return RecurringExpense.fromMap(response);
  }

  // =========================================================================
  // UPDATE
  // =========================================================================

  /// Updates an existing recurring expense.
  /// Only updates the specified fields; user_id and created_at cannot be changed.
  Future<void> updateRecurringExpense({
    required String id,
    required String name,
    required double amount,
    required int dueDay,
    required bool isActive,
  }) async {
    final userId = _client.auth.currentUser!.id;

    // Validate constraints before sending to database
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
    if (dueDay < 1 || dueDay > 31) {
      throw ArgumentError('Due day must be between 1 and 31');
    }

    final payload = <String, dynamic>{
      'name': name,
      'amount': amount,
      'due_day': dueDay,
      'is_active': isActive,
    };

    await _client
        .from('recurring_expenses')
        .update(payload)
        .eq('id', id)
        .eq('user_id', userId);
  }

  // =========================================================================
  // DELETE / DEACTIVATE
  // =========================================================================

  /// Deactivates a recurring expense (soft delete).
  /// Preferred over hard delete to preserve history.
  Future<void> deactivateRecurringExpense({
    required String id,
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('recurring_expenses')
        .update({'is_active': false})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Reactivates a previously deactivated recurring expense.
  Future<void> reactivateRecurringExpense({
    required String id,
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('recurring_expenses')
        .update({'is_active': true})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Permanently deletes a recurring expense.
  /// Use with caution; prefer deactivateRecurringExpense for most cases.
  Future<void> deleteRecurringExpense({
    required String id,
  }) async {
    final userId = _client.auth.currentUser!.id;

    await _client
        .from('recurring_expenses')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
}
