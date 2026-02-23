import 'package:flutter/material.dart';

import '../../theme/app_colors_ext.dart';
import './widgets/auth_form.dart';

/// Standalone authentication screen that wraps AuthForm.
/// Use this for direct route navigation (e.g., /auth).
/// For embedded auth UI, use AuthForm directly (as StartupScreen does).
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasFrosted,
      body: const SafeArea(child: AuthForm()),
    );
  }
}
