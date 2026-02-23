// lib/widgets/biometric_gate.dart
//
// Wraps the app to show biometric lock screen when app resumes from background.
// Uses WidgetsBindingObserver to detect app lifecycle changes.
//
// Key design decisions:
// 1. No lock on cold start - Only lock on resume from background, not first launch
// 2. Last unlock timestamp - Use successful unlock time for grace period
// 3. True overlay - Returns lock screen widget directly, no route pushing

import 'package:flutter/material.dart';

import '../presentation/biometric/biometric_lock_screen.dart';
import '../services/biometric_auth_service.dart';

/// Wraps the app to show biometric lock screen when app resumes from background.
class BiometricGate extends StatefulWidget {
  final Widget child;

  const BiometricGate({super.key, required this.child});

  @override
  State<BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<BiometricGate>
    with WidgetsBindingObserver {
  final BiometricAuthService _biometricService = BiometricAuthService();

  bool _isLocked = false;

  /// Prevents lock on cold start - only lock after first resume
  bool _hasEverResumed = false;

  /// Track last successful unlock for grace period
  DateTime? _lastUnlockAt;

  /// Grace period: don't lock if unlocked recently
  static const Duration _gracePeriod = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Note: We do NOT check lock state on init - no lock on cold start
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App coming to foreground
        if (_hasEverResumed) {
          _handleAppResumed();
        }
        _hasEverResumed = true; // Set after first resume
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App going to background or being destroyed
        break;
    }
  }

  Future<void> _handleAppResumed() async {
    // Skip lock if within grace period of last unlock
    if (_lastUnlockAt != null) {
      final elapsed = DateTime.now().difference(_lastUnlockAt!);
      if (elapsed < _gracePeriod) {
        return;
      }
    }

    final shouldLock = await _biometricService.shouldRequireBiometricUnlock();
    if (shouldLock && mounted) {
      setState(() => _isLocked = true);
    }
  }

  void _handleUnlocked() {
    _lastUnlockAt = DateTime.now(); // Record unlock time
    if (mounted) {
      setState(() => _isLocked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return BiometricLockScreen(
        onUnlocked: _handleUnlocked,
      );
    }
    return widget.child;
  }
}
