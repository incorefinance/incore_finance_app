import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Placeholder for the deep link scheme. Configure this in:
/// - Android: android/app/src/main/AndroidManifest.xml
/// - iOS: ios/Runner/Info.plist
/// See EMAIL_VERIFICATION.md for configuration instructions.
const String kDeepLinkScheme = 'incore-dev';

/// Actions emitted by DeepLinkService when specific link types are handled.
enum DeepLinkAction {
  /// A password recovery link was processed; navigate to reset password screen.
  recovery,

  /// A general auth update occurred (sign up confirmation, etc.).
  authUpdate,
}

/// Service for handling deep links, particularly Supabase auth callback links.
/// Listens for incoming links and processes auth tokens from verification emails
/// and password recovery links.
class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance => _instance ??= DeepLinkService._();

  DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  /// Stream controller to notify listeners when auth state may have changed
  /// due to deep link processing.
  final StreamController<void> _authUpdateController =
      StreamController<void>.broadcast();

  /// Stream controller for specific deep link actions (recovery, etc.).
  final StreamController<DeepLinkAction> _actionController =
      StreamController<DeepLinkAction>.broadcast();

  /// Stream that emits when a deep link has been processed and auth state
  /// may have changed. UI components can listen to this to refresh.
  Stream<void> get onAuthUpdate => _authUpdateController.stream;

  /// Stream that emits specific actions when certain link types are handled.
  /// Subscribe to this in main.dart to navigate on recovery links.
  Stream<DeepLinkAction> get onAction => _actionController.stream;

  /// Initializes the deep link service. Call this once during app startup.
  /// Handles both cold start (app opened via link) and warm start (app already
  /// running when link is clicked).
  Future<void> initialize() async {
    // Handle link that opened the app (cold start)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        await _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Failed to get initial link: $e');
    }

    // Handle links while app is running (warm start)
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (e) {
        debugPrint('DeepLinkService: Error in link stream: $e');
      },
    );
  }

  /// Disposes of resources. Call this when the app is being destroyed.
  void dispose() {
    _linkSubscription?.cancel();
    _authUpdateController.close();
    _actionController.close();
  }

  /// Processes an incoming deep link URI and lets Supabase parse it.
  /// This supports both implicit flow fragments and PKCE code flows.
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('DeepLinkService: Received deep link: $uri');

    final hasFragmentTokens = uri.fragment.isNotEmpty;
    final hasPkceCode = uri.queryParameters['code'] != null;

    if (!hasFragmentTokens && !hasPkceCode) {
      debugPrint('DeepLinkService: No auth tokens found in link');
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      // Let Supabase handle both:
      // - fragment tokens: #access_token=...&refresh_token=...
      // - PKCE codes: ?code=...
      // This avoids manual token parsing and stays compatible with auth updates.
      await supabase.auth.getSessionFromUrl(uri);

      if (_isRecoveryLink(uri)) {
        debugPrint('DeepLinkService: Emitting recovery action');
        _actionController.add(DeepLinkAction.recovery);
        return;
      }

      _authUpdateController.add(null);
      _actionController.add(DeepLinkAction.authUpdate);
    } catch (e, stackTrace) {
      debugPrint('DeepLinkService: Error processing deep link: $e');
      debugPrint('DeepLinkService: StackTrace: $stackTrace');
    }
  }

  bool _isRecoveryLink(Uri uri) {
    // Query parameter type=recovery
    final queryType = uri.queryParameters['type'];
    if (queryType == 'recovery') return true;

    // Fragment parameter type=recovery
    if (uri.fragment.isNotEmpty) {
      try {
        final fragParams = Uri.splitQueryString(uri.fragment);
        final fragType = fragParams['type'];
        if (fragType == 'recovery') return true;
      } catch (_) {
        // Ignore fragment parsing issues
      }
    }

    // Fallback: some flows may not include explicit type. This is a pragmatic
    // MVP safeguard to ensure recovery links still trigger the reset screen.
    return uri.toString().contains('recovery');
  }
}