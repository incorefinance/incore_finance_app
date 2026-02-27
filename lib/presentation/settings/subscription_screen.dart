// lib/presentation/settings/subscription_screen.dart
//
// Subscription management screen showing current plan status.
// Allows users to upgrade, manage, or restore purchases.

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../domain/entitlements/plan_type.dart';
import '../../l10n/app_localizations.dart';
import '../../services/subscription/subscription_service.dart';
import '../../theme/app_colors_ext.dart';
import '../../utils/snackbar_helper.dart';

/// Subscription management screen showing current plan status.
///
/// Features:
/// - Current plan display (Free or Premium)
/// - Manage subscription button (opens platform management)
/// - Restore purchases button
/// - Upgrade button for free users
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();

  PlanType _currentPlan = PlanType.free;
  bool _isLoading = true;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    final plan = await _subscriptionService.getCurrentPlan();
    if (mounted) {
      setState(() {
        _currentPlan = plan;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isRestoring = true);

    try {
      await _subscriptionService.restorePurchases();
      await _loadSubscriptionStatus();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showSuccess(context, l10n.purchasesRestored);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarHelper.showError(context, l10n.restoreFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<void> _handleUpgrade() async {
    await _subscriptionService.presentPaywall('settings_upgrade');
    // Re-check plan after paywall
    await _loadSubscriptionStatus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.canvasFrosted,
      appBar: AppBar(
        title: Text(l10n.subscription),
        centerTitle: true,
        elevation: 0,
        backgroundColor: context.canvasFrosted,
        foregroundColor: context.slate900,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Plan Status Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: context.borderGlass60,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(6.w),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _currentPlan == PlanType.premium
                                  ? context.blue50
                                  : context.surfaceGlass80,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _currentPlan == PlanType.premium
                                  ? Icons.workspace_premium
                                  : Icons.account_circle_outlined,
                              size: 48,
                              color: _currentPlan == PlanType.premium
                                  ? context.blue600
                                  : context.slate400,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _currentPlan == PlanType.premium
                                ? l10n.premiumPlan
                                : l10n.freePlan,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            _currentPlan == PlanType.premium
                                ? l10n.premiumDescription
                                : l10n.freeDescription,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: context.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Features List for Free Plan
                  if (_currentPlan == PlanType.free) ...[
                    _buildFeaturesList(context, l10n),
                    SizedBox(height: 3.h),
                  ],

                  // Upgrade Button (only for free)
                  if (_currentPlan == PlanType.free)
                    ElevatedButton.icon(
                      onPressed: _handleUpgrade,
                      icon: const Icon(Icons.rocket_launch_outlined),
                      label: Text(l10n.upgradeToPremium),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.blue600,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 1.5.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                  SizedBox(height: 2.h),

                  // Restore Purchases Button
                  TextButton.icon(
                    onPressed: _isRestoring ? null : _handleRestorePurchases,
                    icon: _isRestoring
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.blue600,
                            ),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(l10n.restorePurchases),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildFeaturesList(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);

    final features = [
      (Icons.analytics, l10n.featureAnalytics),
      (Icons.history, l10n.featureHistoricalData),
      (Icons.download, l10n.featureExportData),
      (Icons.all_inclusive, l10n.featureUnlimitedEntries),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.borderGlass60,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.premiumFeatures,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ...features.map(
              (feature) => Padding(
                padding: EdgeInsets.only(bottom: 1.5.h),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.blue50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        feature.$1,
                        size: 20,
                        color: context.blue600,
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        feature.$2,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
