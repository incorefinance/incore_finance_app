import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:incore_finance/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

import '../core/app_export.dart';
import '../core/locale/locale_store.dart';
import '../core/navigation/route_observer.dart';
import '../presentation/splash/language_splash_screen.dart';
import '../widgets/custom_error_widget.dart';
import 'package:incore_finance/services/supabase_service.dart';
import 'package:incore_finance/services/deep_link_service.dart';
import '../widgets/biometric_gate.dart';

/// Global navigator key for app-level navigation from services.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Initialize deep link handling for auth callbacks
  try {
    await DeepLinkService.instance.initialize();
  } catch (e) {
    debugPrint('Failed to initialize DeepLinkService: $e');
  }

  // Initialize Superwall for paywall presentation
  try {
    const apiKey = 'pk_pTFQbyNsffC3d-FPC4-o7';
    Superwall.configure(apiKey);
  } catch (e) {
    debugPrint('Failed to initialize Superwall: $e');
  }

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(MyApp(key: myAppKey));
  });
}

final GlobalKey<_MyAppState> myAppKey = GlobalKey<_MyAppState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  /// Static method to change locale from anywhere in the app
  static void setLocale(BuildContext context, Locale newLocale) {
    myAppKey.currentState?.setLocale(newLocale);
  }

  /// Static method to change theme mode from anywhere in the app
  static void setThemeMode(ThemeMode mode) {
    myAppKey.currentState?.setThemeMode(mode);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  ThemeMode _themeMode = ThemeMode.light;
  StreamSubscription<DeepLinkAction>? _deepLinkSubscription;

  /// Tracks whether locale initialization is complete.
  bool _isLocaleInitialized = false;

  /// True if no saved locale exists (first launch) - show language splash.
  bool _showLanguageSplash = false;

  @override
  void initState() {
    super.initState();
    _loadLocalePreference();
    _loadThemePreference();
    _listenToDeepLinkActions();
  }

  /// Loads saved locale or flags first-launch splash screen.
  Future<void> _loadLocalePreference() async {
    final savedCode = await LocaleStore.loadLocaleCode();

    if (!mounted) return;

    if (savedCode != null) {
      // Locale exists - use it and proceed normally
      final locale = LocaleStore.parseToLocale(savedCode);
      setState(() {
        if (locale != null) _locale = locale;
        _isLocaleInitialized = true;
        _showLanguageSplash = false;
      });
    } else {
      // First launch - show language splash
      setState(() {
        _isLocaleInitialized = true;
        _showLanguageSplash = true;
      });
    }
  }

  /// Called when user selects a locale from the language splash.
  void _onLanguageSelected(Locale locale) {
    setState(() {
      _locale = locale;
      _showLanguageSplash = false;
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('darkMode') ?? false;
    if (isDark && mounted) {
      setState(() => _themeMode = ThemeMode.dark);
    }
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  /// Subscribes to deep link actions for recovery flow navigation.
  void _listenToDeepLinkActions() {
    _deepLinkSubscription = DeepLinkService.instance.onAction.listen((action) {
      if (action == DeepLinkAction.recovery) {
        // Navigate to reset password screen when recovery link is processed
        navigatorKey.currentState?.pushNamed(AppRoutes.resetPassword);
      }
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading placeholder while checking locale preference
    if (!_isLocaleInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          backgroundColor: Color(0xFF2563EB),
          body: Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    // Show language splash on first launch
    if (_showLanguageSplash) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: LanguageSplashScreen(
          onLocaleSelected: _onLanguageSelected,
        ),
      );
    }

    // Normal app flow with saved locale
    return Sizer(
      builder: (context, orientation, screenType) {
        return BiometricGate(
          child: MaterialApp(
          navigatorKey: navigatorKey,
          title: 'incore_finance',
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('pt'),
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: _themeMode,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          navigatorObservers: [AppRouteObserver.instance],
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
          ),
        );
      },
    );
  }
}
