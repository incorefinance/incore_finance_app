import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

/// Screen displayed when the app detects an unrecoverable auth state.
/// Provides a clear path back to login without exposing technical details.
class AuthGuardErrorScreen extends StatelessWidget {
  const AuthGuardErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    // Read debug reason from route arguments for logging only
    final debugReason = ModalRoute.of(context)?.settings.arguments as String?;
    if (debugReason != null) {
      debugPrint('AuthGuardErrorScreen: $debugReason');
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  l10n?.authErrorTitle ?? 'Session Expired',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  l10n?.authErrorDescription ??
                      'Your session has ended. Please log in again to continue.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Primary CTA: Log in again
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleLogInAgain(context),
                    icon: const Icon(Icons.login, size: 20),
                    label: Text(l10n?.logInAgain ?? 'Log in again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Signs out from Supabase and navigates back to the startup screen.
  Future<void> _handleLogInAgain(BuildContext context) async {
    try {
      // Sign out to clear any stale session data
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      // Log but don't block navigation - we want user to get to login
      debugPrint('AuthGuardErrorScreen: Sign out error (ignored): $e');
    }

    if (!context.mounted) return;

    // Clear navigation stack and go to startup screen
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.initial,
      (route) => false,
    );
  }
}
