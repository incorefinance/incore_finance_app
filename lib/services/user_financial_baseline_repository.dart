// lib/services/user_financial_baseline_repository.dart
//
// Repository for the `user_financial_baseline` table in Supabase.
// Manages the starting balance (financial baseline) for each user.
// Used by:
//  - Dashboard Home (future: baseline-aware balance calculations)
//  - Settings (future: edit starting balance)
//
// Design note:
// - Uses upsert pattern because one row per user
// - No separate insert/update methods; upsert handles both cases
// - All operations scoped to current user (enforced by RLS)

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:incore_finance/models/user_financial_baseline.dart';

class UserFinancialBaselineRepository {
  final SupabaseClient _client;

  UserFinancialBaselineRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  // =========================================================================
  // READ
  // =========================================================================

  /// Fetches the financial baseline for the current user.
  /// Returns null if no baseline exists (baseline will be created on first upsert).
  Future<UserFinancialBaseline?> getBaselineForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('No authenticated user');

    try {
      final response = await _client
          .from('user_financial_baseline')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return UserFinancialBaseline.fromMap(response);
    } catch (e) {
      // Handle error - return null to indicate baseline doesn't exist
      return null;
    }
  }

  // =========================================================================
  // UPSERT (Create or Update)
  // =========================================================================

  /// Creates or updates the starting balance for the current user.
  /// If a baseline exists, updates the starting_balance.
  /// If no baseline exists, creates a new one with the provided value.
  ///
  /// Returns the created or updated UserFinancialBaseline.
  ///
  /// Note: The starting_balance can be negative, zero, or positive.
  /// Throws StateError if no user is authenticated.
  Future<UserFinancialBaseline> upsertStartingBalance(double value) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw StateError(
        'Cannot save starting balance: No authenticated user. '
        'Please log in first.',
      );
    }
    final userId = currentUser.id;

    // Prepare payload for upsert
    // Supabase's upsert uses the unique constraint (user_id) as the conflict key
    final payload = {
      'user_id': userId,
      'starting_balance': value,
    };

    final response = await _client
        .from('user_financial_baseline')
        .upsert(payload, onConflict: 'user_id')
        .select()
        .single();

    return UserFinancialBaseline.fromMap(response);
  }

  /// Alias for upsertStartingBalance. Sets the starting balance for the current user.
  ///
  /// Prefer this method name for clarity in business logic contexts.
  /// Internally delegates to upsertStartingBalance.
  Future<UserFinancialBaseline> setStartingBalance(double value) async {
    return upsertStartingBalance(value);
  }
}
