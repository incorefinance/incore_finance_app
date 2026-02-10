import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../routes/app_routes.dart';
import '../../../services/password_validator.dart';
import '../../../theme/app_colors.dart';
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
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderGlass60Light),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderGlass60Light),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.blue600, width: 2),
                ),
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
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least 12 characters',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.slate400,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderGlass60Light),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderGlass60Light),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.blue600, width: 2),
                ),
              ),
              validator: (value) {
                if (_isSignUpMode) {
                  final result = PasswordValidator.validatePolicy(value ?? '');
                  return result.isValid ? null : result.errorMessage;
                } else {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
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
                  child: const Text('Forgot password?'),
                ),
              ),
            const SizedBox(height: 16),
            // Message text (non-error, e.g., email confirmation)
            if (_messageText != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.blueBg50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _messageText!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.blue600,
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
                  backgroundColor: AppColors.blue600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.blue600.withValues(alpha: 0.5),
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
