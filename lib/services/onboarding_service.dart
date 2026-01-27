import 'onboarding_status_repository.dart';

/// Service for managing onboarding state.
/// Uses server-side persistence via OnboardingStatusRepository to ensure
/// onboarding state is consistent across devices and persists through
/// app reinstalls.
class OnboardingService {
  final OnboardingStatusRepository _repository;

  OnboardingService({OnboardingStatusRepository? repository})
      : _repository = repository ?? OnboardingStatusRepository();

  /// Check if onboarding has been completed for the current user.
  /// Returns true if user has finished onboarding, false otherwise.
  /// Server-side value is authoritative.
  Future<bool> isOnboardingComplete() async {
    return _repository.isOnboardingCompleted();
  }

  /// Mark onboarding as complete for the current user.
  /// Call this when user finishes the final onboarding screen.
  /// Persists to server-side storage.
  Future<void> setOnboardingComplete() async {
    await _repository.markOnboardingCompleted();
  }
}
