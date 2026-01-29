import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/onboarding_service.dart';
import '../../services/auth_guard.dart';
import '../../routes/app_routes.dart';
import '../auth/widgets/auth_form.dart';

/// Startup screen that waits for auth state and routes based on onboarding status.
/// - If user is not authenticated: shows email/password auth form directly
/// - If user is authenticated and onboarding not completed: routes to onboarding
/// - If user is authenticated and onboarding completed: routes to dashboard
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  StreamSubscription<AuthState>? _authSubscription;
  bool _showAuthForm = false;
  bool _hasRouted = false;

  @override
  void initState() {
    super.initState();
    _initializeAuthListener();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _initializeAuthListener() {
    final supabase = Supabase.instance.client;

    // Check current auth state immediately
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      _handleAuthenticatedUser();
    } else {
      // Listen for auth state changes (user logs in or out)
      _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.tokenRefreshed) {
          // These events should always have a valid session
          if (data.session?.user != null) {
            if (mounted) {
              setState(() {
                _showAuthForm = false;
              });
            }
            _authSubscription?.cancel();
            _handleAuthenticatedUser();
          } else {
            // signedIn or tokenRefreshed without user is an error
            debugPrint('StartupScreen: Auth event without valid user: $event');
            if (mounted && !_hasRouted) {
              _routeToAuthError('Invalid session state');
            }
          }
        } else if (event == AuthChangeEvent.initialSession) {
          // initialSession fires on app start - null session is normal (not logged in)
          if (data.session?.user != null) {
            if (mounted) {
              setState(() {
                _showAuthForm = false;
              });
            }
            _authSubscription?.cancel();
            _handleAuthenticatedUser();
          }
          // If no session, just let _checkAuthAfterDelay show the auth form
        } else if (event == AuthChangeEvent.signedOut) {
          if (mounted) {
            setState(() {
              _showAuthForm = true;
              _hasRouted = false;
            });
          }
        }
      }, onError: (error) {
        // Handle stream errors (e.g., token refresh failure)
        debugPrint('StartupScreen: Auth stream error: $error');
        if (mounted && !_hasRouted) {
          _routeToAuthError('Session refresh failed');
        }
      });

      // Check after short delay to allow auth listener to fire
      _checkAuthAfterDelay();
    }
  }

  Future<void> _checkAuthAfterDelay() async {
    // Small delay to allow auth listener to potentially fire
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // If still no user after delay, show auth form
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) {
      if (mounted) {
        setState(() {
          _showAuthForm = true;
        });
      }
    } else {
      // User is authenticated, ensure form stays hidden
      if (mounted && _showAuthForm) {
        setState(() {
          _showAuthForm = false;
        });
      }
    }
  }

  Future<void> _handleAuthenticatedUser() async {
    if (!mounted) return;
    if (_hasRouted) return;

    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    // Guard: Ensure user is still valid
    if (user == null) {
      debugPrint('StartupScreen: User became null during routing');
      _routeToAuthError('User session lost');
      return;
    }

    // Check email verification status first.
    // If emailConfirmedAt is null, the user has not verified their email.
    if (user.emailConfirmedAt == null) {
      if (!mounted) return;
      if (_hasRouted) return;

      _hasRouted = true;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.emailVerification,
        (route) => false,
      );
      return;
    }

    try {
      final isComplete = await _onboardingService.isOnboardingComplete();

      // Re-check user after async call in case session expired
      if (supabase.auth.currentUser == null) {
        debugPrint('StartupScreen: User became null after onboarding check');
        _routeToAuthError('Session expired during initialization');
        return;
      }

      if (!mounted) return;
      if (_hasRouted) return;

      _hasRouted = true;
      if (isComplete) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardHome);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    } catch (e, stackTrace) {
      debugPrint('StartupScreen auth routing error: $e');
      debugPrint('StackTrace: $stackTrace');

      // Check if this is an auth-specific error requiring re-login
      if (AuthGuard.isAuthError(e)) {
        _routeToAuthError('Authentication error: ${e.runtimeType}');
        return;
      }

      // For non-auth errors, try onboarding as fallback
      if (mounted && !_hasRouted) {
        _hasRouted = true;
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    }
  }

  /// Routes to auth error screen for unrecoverable auth failures.
  void _routeToAuthError(String reason) {
    if (!mounted || _hasRouted) return;
    _hasRouted = true;
    debugPrint('StartupScreen: Routing to auth error - $reason');
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.authGuardError,
      (route) => false,
      arguments: reason,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _showAuthForm
            ? const AuthForm()
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
