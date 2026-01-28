import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:incore_finance/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../core/navigation/route_observer.dart';
import '../widgets/custom_error_widget.dart';
import 'package:incore_finance/services/supabase_service.dart';
import 'package:incore_finance/services/deep_link_service.dart';

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
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en');
  StreamSubscription<DeepLinkAction>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();
    _listenToDeepLinkActions();
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

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'incore_finance',
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('pt'),
          ],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
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
        );
      },
    );
  }
}
