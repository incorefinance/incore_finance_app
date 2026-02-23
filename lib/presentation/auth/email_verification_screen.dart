import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/onboarding_service.dart';
import '../../theme/app_colors_ext.dart';

/// Key for storing the last resend timestamp in SharedPreferences.
const String _kLastResendAtKey = 'email_verification_last_resend_at';

/// Cooldown duration in seconds between resend attempts.
const int _kResendCooldownSeconds = 60;

/// Screen shown to users who have signed up but not yet verified their email.
/// Provides:
/// - Message explaining verification is required
/// - Resend verification email button with 60 second cooldown (persisted)
/// - Manual refresh button to re check verification status
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  StreamSubscription<AuthState>? _authSubscription;

  String? _emailFromArgs;
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _initializeCooldown();
    _listenToAuthChanges();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (_emailFromArgs == null && args is String && args.trim().isNotEmpty) {
      _emailFromArgs = args.trim();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  /// Initializes the cooldown state from SharedPreferences.
  /// If a recent resend occurred, calculates remaining cooldown.
  Future<void> _initializeCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final lastResendAt = prefs.getInt(_kLastResendAtKey);

    if (lastResendAt != null) {
      final elapsed = DateTime.now().millisecondsSinceEpoch - lastResendAt;
      final elapsedSeconds = elapsed ~/ 1000;
      final remaining = _kResendCooldownSeconds - elapsedSeconds;

      if (remaining > 0) {
        _startCooldownTimer(remaining);
      }
    }
  }

  /// Starts a countdown timer that decrements _cooldownRemaining each second.
  void _startCooldownTimer(int seconds) {
    if (!mounted) return;

    setState(() {
      _cooldownRemaining = seconds;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _cooldownRemaining--;
        if (_cooldownRemaining <= 0) {
          timer.cancel();
        }
      });
    });
  }

  /// Listens to auth state changes. If user becomes verified or signs out,
  /// handles routing appropriately.
  void _listenToAuthChanges() {
    final supabase = Supabase.instance.client;

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.signedOut) {
        // User signed out; route back to initial (auth) screen
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.initial,
            (route) => false,
          );
        }
      } else if (event == AuthChangeEvent.userUpdated ||
          event == AuthChangeEvent.tokenRefreshed) {
        // Check if email is now verified
        _checkVerificationAndRoute();
      }
    });
  }

  /// Checks if the current user's email is verified and routes accordingly.
  Future<void> _checkVerificationAndRoute() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      // No active session yet. User likely needs to confirm email before signing in.
      // Stay on this screen and allow resend using the email argument.
      return;
    }

    if (user.emailConfirmedAt != null) {
      // Email is verified; proceed with onboarding check
      await _routeToAppropriateScreen();
    }
  }

  /// Routes to onboarding or dashboard based on onboarding completion status.
  Future<void> _routeToAppropriateScreen() async {
    if (!mounted) return;

    try {
      final isComplete = await _onboardingService.isOnboardingComplete();

      if (!mounted) return;

      if (isComplete) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.dashboardHome,
          (route) => false,
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.onboarding,
          (route) => false,
        );
      }
    } catch (e) {
      // On error, default to onboarding
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.onboarding,
          (route) => false,
        );
      }
    }
  }

  /// Resends the verification email using Supabase auth.resend().
  /// Enforces cooldown and persists last resend timestamp.
  Future<void> _resendVerificationEmail() async {
    if (_isResending || _cooldownRemaining > 0) return;

    final supabase = Supabase.instance.client;
    final email = supabase.auth.currentUser?.email ?? _emailFromArgs;

    if (email == null || email.isEmpty) {
      setState(() {
        _errorMessage = 'No email found. Please go back and enter your email again.';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      // Persist resend timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _kLastResendAtKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      _startCooldownTimer(_kResendCooldownSeconds);

      if (mounted) {
        setState(() {
          _successMessage = 'Verification email sent. Please check your inbox.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send verification email. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  /// Manually refreshes the session to check if email was verified externally.
  Future<void> _refreshAndCheck() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;
      await supabase.auth.refreshSession();

      final user = supabase.auth.currentUser;

      if (user == null) {
        // No active session. Provide guidance to user.
        if (mounted) {
          setState(() {
            _errorMessage = 'After confirming your email, return to the app and sign in.';
          });
        }
        return;
      }

      if (user.emailConfirmedAt != null) {
        // Email is now verified
        await _routeToAppropriateScreen();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Email not yet verified. Please check your inbox and click the verification link.';
          });
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to refresh session. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Signs out the current user and returns to auth screen.
  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      // Ignore errors during sign out
    }

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.initial,
        (route) => false,
      );
    }
  }

  /// Converts technical auth error messages to user friendly language.
  String _getUserFriendlyError(String? technicalMessage) {
    if (technicalMessage == null) return 'Something went wrong. Please try again.';

    final lower = technicalMessage.toLowerCase();

    // Session related errors
    if (lower.contains('session') ||
        lower.contains('auth session missing') ||
        lower.contains('not authenticated')) {
      return 'Please confirm your email first, then sign in to continue.';
    }

    // Rate limiting
    if (lower.contains('rate') || lower.contains('too many')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }

    // Network errors
    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('timeout')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    // Invalid email
    if (lower.contains('invalid') && lower.contains('email')) {
      return 'The email address appears to be invalid. Please check and try again.';
    }

    // User not found
    if (lower.contains('user not found') || lower.contains('no user')) {
      return 'No account found with this email. Please sign up first.';
    }

    // Default: return original if no match, but clean it up
    return technicalMessage;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final supabase = Supabase.instance.client;
    final userEmail = supabase.auth.currentUser?.email ?? _emailFromArgs;

    return Scaffold(
      backgroundColor: context.canvasFrosted,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sign out button aligned top-right
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _signOut,
                  child: Text(
                    'Sign out',
                    style: TextStyle(color: context.blue600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: context.blue600,
              ),
              const SizedBox(height: 32),
              Text(
                'Check Your Email',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We sent a verification link to:',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: context.slate500,
                ),
                textAlign: TextAlign.center,
              ),
              if (userEmail != null) ...[
                const SizedBox(height: 8),
                Text(
                  userEmail,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Click the link in your email to verify your account and continue.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.slate500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Success message
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _successMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getUserFriendlyError(_errorMessage),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Resend button
              ElevatedButton(
                onPressed:
                    (_isResending || _cooldownRemaining > 0) ? null : _resendVerificationEmail,
                child: _isResending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _cooldownRemaining > 0
                            ? 'Resend Email ($_cooldownRemaining s)'
                            : 'Resend Verification Email',
                      ),
              ),
              const SizedBox(height: 12),
              // Refresh/check button
              OutlinedButton(
                onPressed: _isLoading ? null : _refreshAndCheck,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('I Have Verified, Refresh'),
              ),
              const SizedBox(height: 24),
              // Help text
              Text(
                'Did not receive the email? Check your spam folder or try resending.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.slate400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Show "Back to sign in" when no active session
              if (supabase.auth.currentUser == null)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.initial,
                      (route) => false,
                    );
                  },
                  child: const Text('Back to sign in'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
