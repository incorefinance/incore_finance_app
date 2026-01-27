import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/onboarding_service.dart';
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
            event == AuthChangeEvent.tokenRefreshed ||
            event == AuthChangeEvent.initialSession) {
          if (data.session?.user != null) {
            if (mounted) {
              setState(() {
                _showAuthForm = false;
              });
            }
            _authSubscription?.cancel();
            _handleAuthenticatedUser();
          }
        } else if (event == AuthChangeEvent.signedOut) {
          if (mounted) {
            setState(() {
              _showAuthForm = true;
              _hasRouted = false;
            });
          }
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

    try {
      final isComplete = await _onboardingService.isOnboardingComplete();

      if (!mounted) return;
      if (_hasRouted) return;

      _hasRouted = true;
      if (isComplete) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardHome);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('StartupScreen auth routing error: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
      // On error, default to onboarding to ensure user can complete setup
      if (mounted && !_hasRouted) {
        _hasRouted = true;
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    }
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
