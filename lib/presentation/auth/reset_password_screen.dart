import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../../routes/app_routes.dart';
import '../../services/password_validator.dart';
import '../../theme/app_colors_ext.dart';

/// Screen for setting a new password after clicking a reset link.
/// Requires a valid recovery session to be set by DeepLinkService.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _passwordUpdated = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  /// Checks if there is a valid session for password update.
  bool get _hasSession => Supabase.instance.client.auth.currentSession != null;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    // Check passwords match
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = l10n.passwordsDoNotMatch;
      });
      return;
    }

    // Validate password policy
    final policyResult = PasswordValidator.validatePolicy(_passwordController.text);
    if (!policyResult.isValid) {
      setState(() {
        _errorMessage = policyResult.errorMessage;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Check session again before attempting update
      if (supabase.auth.currentSession == null) {
        setState(() {
          _errorMessage = l10n.authErrorSessionExpired;
        });
        return;
      }

      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      // Optionally refresh session
      try {
        await supabase.auth.refreshSession();
      } catch (e) {
        debugPrint('[ResetPassword] Session refresh failed: $e');
      }

      if (mounted) {
        setState(() {
          _passwordUpdated = true;
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getUserFriendlyError(e.message);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.authErrorGeneric;
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

  /// Converts technical error messages to user friendly language.
  String _getUserFriendlyError(String? message) {
    final l10n = AppLocalizations.of(context)!;
    if (message == null) return l10n.authErrorGeneric;

    final lower = message.toLowerCase();

    if (lower.contains('session') || lower.contains('not authenticated')) {
      return l10n.authErrorSessionExpired;
    }

    if (lower.contains('same password') || lower.contains('different')) {
      return l10n.authErrorChooseDifferentPassword;
    }

    if (lower.contains('rate') || lower.contains('too many')) {
      return l10n.authErrorTooManyAttempts;
    }

    return message;
  }

  void _navigateToStart() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.initial,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.canvasFrosted,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),
                Icon(
                  _passwordUpdated ? Icons.check_circle_outline : Icons.lock_outline,
                  size: 80,
                  color: context.blue600,
                ),
                const SizedBox(height: 32),
                Text(
                  _passwordUpdated ? l10n.passwordUpdated : l10n.setNewPassword,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Password updated success state
                if (_passwordUpdated) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.passwordUpdatedMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _navigateToStart,
                    child: Text(l10n.continueToSignIn),
                  ),
                ] else ...[
                  // No session warning
                  if (!_hasSession)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        l10n.openResetLinkMessage,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // Instructions
                  if (_hasSession)
                    Text(
                      l10n.enterNewPasswordBelow,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.slate500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 32),
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
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // Password fields
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    enabled: _hasSession,
                    decoration: InputDecoration(
                      labelText: l10n.newPassword,
                      hintText: '${l10n.passwordHint}',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.enterNewPassword;
                      }
                      final result = PasswordValidator.validatePolicy(value);
                      if (!result.isValid) {
                        return result.errorMessage;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    enabled: _hasSession,
                    decoration: InputDecoration(
                      labelText: l10n.confirmPassword,
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.confirmYourPassword;
                      }
                      if (value != _passwordController.text) {
                        return l10n.passwordsDoNotMatch;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _updatePassword(),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: (_isLoading || !_hasSession) ? null : _updatePassword,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.updatePassword),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _navigateToStart,
                    child: Text(l10n.backToSignIn),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
