import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../routes/app_routes.dart';
import '../../../services/password_validator.dart';
import '../../../theme/app_colors_ext.dart';
import 'password_strength_indicator.dart';

/// Minimal email/password auth form for sign in and sign up.
/// Does not handle navigation; parent widget is responsible for routing.
class AuthForm extends StatefulWidget {
  const AuthForm({super.key});

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isSignUpMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _messageText;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _messageText = null;
      _errorText = null;
    });

    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      if (_isSignUpMode) {
        await _handleSignUp(supabase, email, password);
      } else {
        await _handleSignIn(supabase, email, password);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorText = _mapAuthError(e);
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorText = l10n.authErrorGeneric;
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

  Future<void> _handleSignIn(
    SupabaseClient supabase,
    String email,
    String password,
  ) async {
    await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (supabase.auth.currentUser == null) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _errorText = l10n.authErrorSignInFailed;
      });
    }
    // Do not navigate or show SnackBar; StartupScreen handles routing via auth listener
  }

  Future<void> _handleSignUp(
    SupabaseClient supabase,
    String email,
    String password,
  ) async {
    final policy = PasswordValidator.validatePolicy(password);
    if (!policy.isValid) {
    setState(() {
    _errorText = policy.errorMessage;
    });
    return;
    }

    final response = await supabase.auth.signUp(
    email: email,
    password: password,
    );

    // Check if signed in immediately (no email confirmation required)
    if (response.session != null || supabase.auth.currentUser != null) {
      // Do not navigate or show SnackBar; StartupScreen handles routing via auth listener
      return;
    }

    // Email confirmation required - navigate to verification screen
    // Pass email as argument so resend works without active session
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.emailVerification,
        arguments: email,
      );
    }
  }

  String _mapAuthError(AuthException e) {
    final l10n = AppLocalizations.of(context)!;
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid')) {
      return l10n.authErrorInvalidCredentials;
    }
    if (msg.contains('email not confirmed')) {
      return l10n.authErrorEmailNotConfirmed;
    }
    if (msg.contains('rate') || msg.contains('too many')) {
      return l10n.authErrorTooManyAttempts;
    }
    if (msg.contains('already registered') || msg.contains('already been registered')) {
      return l10n.authErrorAlreadyRegistered;
    }
    return l10n.authErrorGeneric;
  }

  void _toggleMode() {
    setState(() {
      _isSignUpMode = !_isSignUpMode;
      _messageText = null;
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isSignUpMode ? l10n.signUp : l10n.signIn,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.email,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderGlass60),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderGlass60),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.blue600, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.enterYourEmail;
                }
                if (!value.contains('@')) {
                  return l10n.enterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.password,
                hintText: l10n.passwordHint,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: context.slate400,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderGlass60),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderGlass60),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.blue600, width: 2),
                ),
              ),
              validator: (value) {
                if (_isSignUpMode) {
                  final result = PasswordValidator.validatePolicy(value ?? '');
                  return result.isValid ? null : result.errorMessage;
                } else {
                  if (value == null || value.isEmpty) {
                    return l10n.enterPassword;
                  }
                  return null;
                }
              },
              onFieldSubmitted: (_) => _handleSubmit(),
              onChanged: (value) {
                setState(() {}); // Trigger rebuild for strength indicator
              },
            ),
            // Password strength indicator (only in sign up mode)
            if (_isSignUpMode && _passwordController.text.isNotEmpty)
              PasswordStrengthIndicator(password: _passwordController.text, email: _emailController.text.trim()),
            // Forgot password link (only in sign in mode)
            if (!_isSignUpMode)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                  child: Text(l10n.forgotPassword),
                ),
              ),
            const SizedBox(height: 16),
            // Message text (non-error, e.g., email confirmation)
            if (_messageText != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.blue50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _messageText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.blue600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Error text
            if (_errorText != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.blue600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: context.blue600.withValues(alpha: 0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isSignUpMode ? l10n.createAccount : l10n.signIn),
              ),
            ),
            const SizedBox(height: 12),
            // Toggle mode button
            TextButton(
              onPressed: _isLoading ? null : _toggleMode,
              child: Text(
                _isSignUpMode
                    ? l10n.alreadyHaveAccount
                    : l10n.needAccount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
