// lib/presentation/analytics_dashboard/analytics_gate_screen.dart
//
// Gate screen that checks entitlement before showing Analytics.
// Presents paywall for free users, then rechecks access.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/entitlements/entitlement_service.dart';
import '../../routes/app_routes.dart';
import '../../services/subscription/subscription_service.dart';
import 'analytics_dashboard.dart';

/// Whether Superwall SDK is available on this platform.
/// Superwall only works on iOS and Android native apps.
bool get _superwallSupportedPlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Gate screen that checks entitlement before showing Analytics.
///
/// Flow:
/// 1. If user has premium: immediately shows [AnalyticsDashboard]
/// 2. If user is free: presents paywall, then rechecks
/// 3. If still free after paywall: navigates back
///
/// This approach avoids async issues in navigation and keeps
/// the bottom bar synchronous.
class AnalyticsGateScreen extends StatefulWidget {
  const AnalyticsGateScreen({super.key});

  @override
  State<AnalyticsGateScreen> createState() => _AnalyticsGateScreenState();
}

class _AnalyticsGateScreenState extends State<AnalyticsGateScreen> {
  final _entitlementService = EntitlementService();
  final _subscriptionService = SubscriptionService();

  bool _isChecking = true;
  bool _hasAccess = false;

  @override
  void initState() {
    super.initState();
    _checkAccessAndGate();
  }

  Future<void> _checkAccessAndGate() async {
    // Allow Analytics in debug or on unsupported platforms (desktop/web)
    // to avoid Superwall channel crashes
    if (kDebugMode || !_superwallSupportedPlatform) {
      if (!mounted) return;
      setState(() {
        _hasAccess = true;
        _isChecking = false;
      });
      return;
    }

    final plan = await _subscriptionService.getCurrentPlan();

    // Check if user already has access
    if (_entitlementService.canAccessAnalytics(plan)) {
      if (mounted) {
        setState(() {
          _hasAccess = true;
          _isChecking = false;
        });
      }
      return;
    }

    // Show paywall for free users
    await _subscriptionService.presentPaywall('analytics_gate');

    // Re-check after paywall (user may have subscribed)
    final newPlan = await _subscriptionService.getCurrentPlan();

    if (!mounted) return;

    if (_entitlementService.canAccessAnalytics(newPlan)) {
      setState(() {
        _hasAccess = true;
        _isChecking = false;
      });
    } else {
      // Still no access, safely return to previous screen or dashboard
      // Try maybePop first, fallback to dashboard if pop fails
      final didPop = await Navigator.of(context).maybePop();
      if (!didPop && mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.dashboardHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isChecking) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_hasAccess) {
      return const AnalyticsDashboard();
    }

    // Fallback - shouldn't reach here due to pop in _checkAccessAndGate
    return const SizedBox.shrink();
  }
}
