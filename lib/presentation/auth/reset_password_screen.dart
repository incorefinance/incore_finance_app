import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/password_validator.dart';

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

    // Check passwords match
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
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
          _errorMessage = 'Your session has expired. Please open the reset link again.';
        });
        return;
      }

      await supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );

      // Optionally refresh session
      try {
        await supabase.auth.refreshSession();
      } catch (_) {
        // Ignore refresh errors
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
          _errorMessage = 'Something went wrong. Please try again.';
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
    if (message == null) return 'Something went wrong. Please try again.';

    final lower = message.toLowerCase();

    if (lower.contains('session') || lower.contains('not authenticated')) {
      return 'Your session has expired. Please open the reset link again.';
    }

    if (lower.contains('same password') || lower.contains('different')) {
      return 'Please choose a different password than your current one.';
    }

    if (lower.contains('rate') || lower.contains('too many')) {
      return 'Too many attempts. Please wait a moment before trying again.';
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
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
                  color: _passwordUpdated ? colorScheme.primary : colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  _passwordUpdated ? 'Password Updated' : 'Set New Password',
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
                      'Password updated. You can sign in now.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _navigateToStart,
                    child: const Text('Continue to Sign In'),
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
                        'Open the reset link from your email, then return to the app to set your new password.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  // Instructions
                  if (_hasSession)
                    Text(
                      'Enter your new password below.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                      labelText: 'New Password',
                      hintText: 'At least ${PasswordValidator.minLength} characters',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
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
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
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
                        : const Text('Update Password'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _navigateToStart,
                    child: const Text('Back to Sign In'),
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
