import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for managing onboarding status in Supabase.
/// Provides server-side persistence of onboarding completion per user account.
/// This ensures onboarding state is consistent across devices and persists
/// through app reinstalls.
class OnboardingStatusRepository {
  final SupabaseClient _client;

  OnboardingStatusRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Check if the current user has completed onboarding.
  /// Returns true only if server-side onboarding_completed == true.
  /// If no row exists for the user, returns false (not completed).
  Future<bool> isOnboardingCompleted() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final response = await _client
          .from('user_onboarding_status')
          .select('onboarding_completed')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      return response['onboarding_completed'] == true;
    } catch (e) {
      // On error, treat as not completed to ensure user can complete onboarding
      return false;
    }
  }

  /// Mark onboarding as completed for the current user.
  /// Upserts the user row with onboarding_completed = true and completed_at = now().
  Future<void> markOnboardingCompleted() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user');
    }

    await _client.from('user_onboarding_status').upsert({
      'user_id': user.id,
      'onboarding_completed': true,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
