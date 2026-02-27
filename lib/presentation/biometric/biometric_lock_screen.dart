// lib/presentation/biometric/biometric_lock_screen.dart
//
// Full-screen lock overlay shown when app requires biometric unlock.
// Displays appropriate icon based on biometric type and provides retry button.

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../l10n/app_localizations.dart';
import '../../services/biometric_auth_service.dart';
import '../../theme/app_colors_ext.dart';

/// Full-screen lock overlay shown when app requires biometric unlock.
class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const BiometricLockScreen({
    super.key,
    required this.onUnlocked,
  });

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final BiometricAuthService _biometricService = BiometricAuthService();
  BiometricDisplayType _biometricType = BiometricDisplayType.unknown;
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    await _biometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _biometricType = _biometricService.getPrimaryBiometricType();
      });
    }
    // Auto-trigger authentication on first load
    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context);
    final reason = l10n?.biometricUnlockSubtitle(_getBiometricLabel(l10n)) ??
        'Authenticate to access InCore Finance';

    final result = await _biometricService.authenticate(
      localizedReason: reason,
      biometricOnly: false, // Allow PIN/password fallback
    );

    if (!mounted) return;

    setState(() {
      _isAuthenticating = false;
    });

    switch (result) {
      case BiometricAuthResult.success:
        widget.onUnlocked();
        break;
      case BiometricAuthResult.failed:
        final l10n = AppLocalizations.of(context);
        setState(() {
          _errorMessage = l10n?.biometricAuthFailed ?? 'Authentication failed. Try again.';
        });
        break;
      case BiometricAuthResult.lockedOut:
        final l10n = AppLocalizations.of(context);
        setState(() {
          _errorMessage = l10n?.biometricLockedOut ?? 'Too many attempts. Try again later.';
        });
        break;
      case BiometricAuthResult.notAvailable:
      case BiometricAuthResult.error:
        // Biometrics not available, auto-unlock
        widget.onUnlocked();
        break;
    }
  }

  IconData _getBiometricIcon() {
    switch (_biometricType) {
      case BiometricDisplayType.face:
        return Icons.face;
      case BiometricDisplayType.fingerprint:
        return Icons.fingerprint;
      case BiometricDisplayType.unknown:
        return Icons.lock_outline;
    }
  }

  String _getBiometricLabel(AppLocalizations? l10n) {
    switch (_biometricType) {
      case BiometricDisplayType.face:
        return l10n?.biometricFaceId ?? 'Face ID';
      case BiometricDisplayType.fingerprint:
        return l10n?.biometricTouchId ?? 'Touch ID';
      case BiometricDisplayType.unknown:
        return l10n?.biometricAuth ?? 'Biometric';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.canvasFrosted,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Biometric Icon
                Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    color: context.blue50,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _getBiometricIcon(),
                      size: 12.w,
                      color: context.blue600,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),

                // Title
                Text(
                  l10n?.biometricUnlockTitle ?? 'App Locked',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: context.slate900,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 1.5.h),

                // Subtitle
                Text(
                  l10n?.biometricUnlockSubtitle(_getBiometricLabel(l10n)) ??
                      'Use ${_getBiometricLabel(l10n)} to unlock',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: context.slate500,
                  ),
                  textAlign: TextAlign.center,
                ),

                // Error message
                if (_errorMessage != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    _errorMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.rose600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                SizedBox(height: 4.h),

                // Unlock Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _authenticate,
                    icon: _isAuthenticating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(_getBiometricIcon(), size: 20),
                    label: Text(
                      _isAuthenticating
                          ? (l10n?.biometricAuthenticating ?? 'Authenticating...')
                          : (l10n?.biometricUnlockButton ?? 'Unlock'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.blue600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
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
}
