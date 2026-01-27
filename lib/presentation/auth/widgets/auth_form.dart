import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _messageText;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
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
    } on AuthException catch (e, stackTrace) {
      // ignore: avoid_print
      print('AuthException: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorText = e.message;
        });
      }
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('Auth error: $e');
      // ignore: avoid_print
      print('StackTrace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorText = 'Something went wrong. Please try again.';
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
      setState(() {
        _errorText = 'Sign in failed. Please try again.';
      });
    }
    // Do not navigate or show SnackBar; StartupScreen handles routing via auth listener
  }

  Future<void> _handleSignUp(
    SupabaseClient supabase,
    String email,
    String password,
  ) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    // Check if signed in immediately (no email confirmation required)
    if (response.session != null || supabase.auth.currentUser != null) {
      // Do not navigate or show SnackBar; StartupScreen handles routing via auth listener
      return;
    }

    // Email confirmation required - show inline message
    setState(() {
      _messageText =
          'Account created. Check your email to confirm before signing in.';
    });
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              _isSignUpMode ? 'Create account' : 'Sign in',
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
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleSubmit(),
            ),
            const SizedBox(height: 24),
            // Message text (non-error, e.g., email confirmation)
            if (_messageText != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _messageText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
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
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isSignUpMode ? 'Create Account' : 'Sign In'),
              ),
            ),
            const SizedBox(height: 12),
            // Toggle mode button
            TextButton(
              onPressed: _isLoading ? null : _toggleMode,
              child: Text(
                _isSignUpMode
                    ? 'Already have an account? Sign in'
                    : 'Need an account? Create one',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
