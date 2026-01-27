import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Placeholder for the deep link scheme. Configure this in:
/// - Android: android/app/src/main/AndroidManifest.xml
/// - iOS: ios/Runner/Info.plist
/// See EMAIL_VERIFICATION.md for configuration instructions.
const String kDeepLinkScheme = 'incore-dev';

/// Service for handling deep links, particularly Supabase auth callback links.
/// Listens for incoming links and processes auth tokens from verification emails.
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

  /// Stream that emits when a deep link has been processed and auth state
  /// may have changed. UI components can listen to this to refresh.
  Stream<void> get onAuthUpdate => _authUpdateController.stream;

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
  }

  /// Processes an incoming deep link URI.
  /// Extracts auth tokens from Supabase style URLs and sets the session.
  Future<void> _handleDeepLink(Uri uri) async {
    debugPrint('DeepLinkService: Received deep link: $uri');

    // Supabase auth links come in formats like:
    // - incore://auth-callback#access_token=...&refresh_token=...&type=signup
    // - incore://auth-callback?code=...
    // - https://yourapp.com/auth-callback#access_token=...
    //
    // The fragment (#...) contains the tokens for implicit flow.
    // Query parameters (?...) may contain a code for PKCE flow.

    try {
      // Check for fragment-based tokens (implicit flow)
      if (uri.fragment.isNotEmpty) {
        await _handleFragmentTokens(uri);
        return;
      }

      // Check for code-based auth (PKCE flow)
      final code = uri.queryParameters['code'];
      if (code != null) {
        await _handleCodeExchange(uri);
        return;
      }

      debugPrint('DeepLinkService: No auth tokens found in link');
    } catch (e, stackTrace) {
      debugPrint('DeepLinkService: Error processing deep link: $e');
      debugPrint('DeepLinkService: StackTrace: $stackTrace');
    }
  }

  /// Handles fragment-based tokens from implicit auth flow.
  /// Parses the fragment to extract access_token and refresh_token.
  Future<void> _handleFragmentTokens(Uri uri) async {
    final fragment = uri.fragment;
    final params = Uri.splitQueryString(fragment);

    final accessToken = params['access_token'];
    final refreshToken = params['refresh_token'];

    if (accessToken == null) {
      debugPrint('DeepLinkService: No access_token in fragment');
      return;
    }

    debugPrint('DeepLinkService: Processing auth tokens from fragment');

    final supabase = Supabase.instance.client;

    // Set the session using the tokens from the URL
    await supabase.auth.setSession(accessToken);

    // If we have a refresh token, the session is fully established
    // The setSession call above should handle this, but we can also
    // try to recover the session to ensure it is fresh.
    if (refreshToken != null) {
      try {
        await supabase.auth.refreshSession();
      } catch (e) {
        // Session refresh failed, but we may still have a valid session
        debugPrint('DeepLinkService: Session refresh after token set failed: $e');
      }
    }

    // Notify listeners that auth state may have changed
    _authUpdateController.add(null);
  }

  /// Handles PKCE flow code exchange.
  /// Exchanges the authorization code for a session.
  Future<void> _handleCodeExchange(Uri uri) async {
    debugPrint('DeepLinkService: Processing PKCE code exchange');

    final supabase = Supabase.instance.client;

    // Exchange the code for a session
    // The Supabase client handles this via the URI
    await supabase.auth.getSessionFromUrl(uri);

    // Notify listeners that auth state may have changed
    _authUpdateController.add(null);
  }
}
