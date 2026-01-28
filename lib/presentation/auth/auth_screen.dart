import 'package:flutter/material.dart';

import './widgets/auth_form.dart';

/// Standalone authentication screen that wraps AuthForm.
/// Use this for direct route navigation (e.g., /auth).
/// For embedded auth UI, use AuthForm directly (as StartupScreen does).
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: const SafeArea(child: AuthForm()),
    );
  }
}
