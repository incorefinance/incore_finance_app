import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/logging/app_logger.dart';
import '../../domain/onboarding/income_type.dart';

/// Repository for managing user income profile data.
/// Uses the user_onboarding_status table for storage.
class UserIncomeRepository {
  final SupabaseClient _client;

  UserIncomeRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Update income profile for current user.
  /// Upserts to user_onboarding_status table.
  Future<void> updateIncomeProfile({
    required IncomeType type,
    double? monthlyEstimate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    AppLogger.d(
        'Saving income profile: type=${type.name}, estimate=$monthlyEstimate (table: user_onboarding_status)');

    await _client.from('user_onboarding_status').upsert({
      'user_id': user.id,
      'income_type': type.toDbValue(),
      'monthly_income_estimate': monthlyEstimate,
    }, onConflict: 'user_id');
  }

  /// Get income profile for current user.
  /// Returns (null, null) if not set.
  Future<(IncomeType?, double?)> getIncomeProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return (null, null);

    final response = await _client
        .from('user_onboarding_status')
        .select('income_type, monthly_income_estimate')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return (null, null);

    final type =
        IncomeTypeExtension.fromDbValue(response['income_type'] as String?);
    final estimate =
        (response['monthly_income_estimate'] as num?)?.toDouble();

    return (type, estimate);
  }

  /// Check if income type has been set.
  Future<bool> hasIncomeTypeSet() async {
    final (type, _) = await getIncomeProfile();
    return type != null;
  }
}
