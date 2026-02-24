// lib/services/biometric_auth_service.dart
//
// Service for managing biometric authentication (Face ID, fingerprint).
// Handles device capability checks, authentication, and preference storage.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/logging/app_logger.dart';

/// Result of biometric authentication attempt.
enum BiometricAuthResult {
  success,
  failed,
  notAvailable,
  lockedOut,
  error,
}

/// Type of biometric for UI display purposes.
enum BiometricDisplayType {
  face,
  fingerprint,
  unknown,
}

/// Service for managing biometric authentication.
/// Handles device capability checks, authentication, and preference storage.
class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric';

  /// Supported biometric types on this device.
  List<BiometricType> _availableBiometrics = [];

  /// Check if the device supports any form of biometric authentication.
  Future<bool> isDeviceSupported() async {
    if (kIsWeb) return false;

    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheckBiometrics && isDeviceSupported;
    } on PlatformException catch (e) {
      AppLogger.d('BiometricAuthService: isDeviceSupported error: $e');
      return false;
    }
  }

  /// Get the list of available biometric types on this device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];

    try {
      _availableBiometrics = await _localAuth.getAvailableBiometrics();
      return _availableBiometrics;
    } on PlatformException catch (e) {
      AppLogger.d('BiometricAuthService: getAvailableBiometrics error: $e');
      return [];
    }
  }

  /// Check if biometric authentication is enabled by the user.
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable or disable biometric authentication.
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Determine the primary biometric type for UI display.
  /// Keep it simple: face if contains face, fingerprint if contains fingerprint.
  BiometricDisplayType getPrimaryBiometricType() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return BiometricDisplayType.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricDisplayType.fingerprint;
    }
    return BiometricDisplayType.unknown;
  }

  /// Authenticate user with biometrics.
  /// Returns result indicating success, failure, or error state.
  Future<BiometricAuthResult> authenticate({
    required String localizedReason,
    bool biometricOnly = false,
  }) async {
    if (kIsWeb) {
      return BiometricAuthResult.notAvailable;
    }

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
        ),
      );
      return authenticated
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } on PlatformException catch (e) {
      AppLogger.d('BiometricAuthService: authenticate error: $e');
      if (e.code == 'NotAvailable' || e.code == 'NotEnrolled') {
        return BiometricAuthResult.notAvailable;
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        return BiometricAuthResult.lockedOut;
      }
      return BiometricAuthResult.error;
    }
  }

  /// Check if we should require biometric unlock.
  /// Only returns true if:
  /// 1. Device supports biometrics
  /// 2. User has enabled biometrics
  /// 3. Platform is mobile (not web)
  Future<bool> shouldRequireBiometricUnlock() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    final isSupported = await isDeviceSupported();
    if (!isSupported) return false;

    final isEnabled = await isBiometricEnabled();
    return isEnabled;
  }
}
