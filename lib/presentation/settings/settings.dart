import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../domain/entitlements/entitlement_service.dart';
import '../../domain/entitlements/plan_type.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../services/onboarding_status_repository.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/user_settings_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/currency_selector_dialog.dart';
import './widgets/export_options_dialog.dart';
import './widgets/language_selector_dialog.dart';
import './widgets/setting_tile.dart';

/// Platform detection - true only on iOS/Android native
bool get _isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android);

/// Settings screen for app configuration and preferences
class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _userSettingsService = UserSettingsService();
  final _subscriptionService = SubscriptionService();
  final _entitlementService = EntitlementService();
  final _onboardingRepo = OnboardingStatusRepository();

  // User profile
  String? _userName;
  String? _userEmail;

  // Plan
  PlanType _currentPlan = PlanType.free;

  // Settings
  String _currentLanguage = 'en';
  bool _isDarkMode = false;
  String? _currentCurrency;
  int _firstDayOfWeek = 0; // 0 = Sunday, 1 = Monday
  bool _biometricEnabled = false;
  bool _notificationsEnabled = true;
  bool _diagnosticsEnabled = false;

  // Loading states
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadPlanStatus();
    _loadSettings();
  }

  void _loadUserProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
        _userName = user.userMetadata?['display_name'] as String? ??
            user.userMetadata?['full_name'] as String? ??
            user.userMetadata?['name'] as String?;
      });
    }
  }

  Future<void> _loadPlanStatus() async {
    final plan = await _subscriptionService.getCurrentPlan();
    if (mounted) {
      setState(() => _currentPlan = plan);
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currencySettings = await _userSettingsService.getCurrencySettings();

    if (!mounted) return;
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'en';
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _currentCurrency = currencySettings.currencyCode;
      _firstDayOfWeek = prefs.getInt('firstDayOfWeek') ?? 0;
      _biometricEnabled = prefs.getBool('biometric') ?? false;
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _diagnosticsEnabled = prefs.getBool('diagnostics') ?? false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _currentLanguage);
    await prefs.setBool('darkMode', _isDarkMode);
    await prefs.setInt('firstDayOfWeek', _firstDayOfWeek);
    await prefs.setBool('biometric', _biometricEnabled);
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setBool('diagnostics', _diagnosticsEnabled);
  }

  // ---------------------------------------------------------------------------
  // Settings Actions
  // ---------------------------------------------------------------------------

  void _toggleDarkMode(bool value) {
    setState(() => _isDarkMode = value);
    _saveSettings();
    MyApp.setLocale(context, Locale(_currentLanguage));
  }

  void _toggleBiometric(bool value) {
    setState(() => _biometricEnabled = value);
    _saveSettings();
  }

  void _toggleNotifications(bool value) {
    setState(() => _notificationsEnabled = value);
    _saveSettings();
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (_) => LanguageSelectorDialog(
        currentLanguage: _currentLanguage,
        onLanguageSelected: (language) {
          setState(() => _currentLanguage = language);
          _saveSettings();
          MyApp.setLocale(context, Locale(language));
          SnackbarHelper.showSuccess(
            context,
            AppLocalizations.of(context)!.languageUpdated,
          );
        },
      ),
    );
  }

  void _showCurrencySelector() {
    if (_currentCurrency == null) return;
    showDialog(
      context: context,
      builder: (_) => CurrencySelectorDialog(
        currentCurrency: _currentCurrency!,
        onCurrencySelected: (currency) async {
          setState(() => _currentCurrency = currency);
          await _userSettingsService.saveCurrencyCode(currency);
          if (!mounted) return;
          SnackbarHelper.showSuccess(
            context,
            AppLocalizations.of(context)!.currencyUpdated(currency),
          );
        },
      ),
    );
  }

  void _showFirstDayOfWeekDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.firstDayOfWeek),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _firstDayOfWeek = 0);
              _saveSettings();
            },
            child: ListTile(
              leading: Icon(
                _firstDayOfWeek == 0 ? Icons.check_circle : Icons.circle_outlined,
                color: _firstDayOfWeek == 0
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(l10n.sunday),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _firstDayOfWeek = 1);
              _saveSettings();
            },
            child: ListTile(
              leading: Icon(
                _firstDayOfWeek == 1 ? Icons.check_circle : Icons.circle_outlined,
                color: _firstDayOfWeek == 1
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(l10n.monday),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportOptions() async {
    await showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        onExportSelected: (format) {
          SnackbarHelper.showSuccess(
            context,
            AppLocalizations.of(context)!.exportStarted(format),
          );
        },
      ),
    );
  }

  Future<void> _handleResetOnboarding() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetOnboarding),
        content: Text(l10n.resetOnboardingDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _onboardingRepo.resetOnboardingStatus();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.onboarding,
          (route) => false,
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canDelete = controller.text.toUpperCase() == 'DELETE';
          return AlertDialog(
            title: Text(l10n.deleteAccount),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.deleteAccountDesc),
                SizedBox(height: 2.h),
                Text(
                  l10n.deleteAccountConfirm,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: controller,
                  onChanged: (_) => setDialogState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: canDelete
                    ? () {
                        Navigator.pop(context);
                        SnackbarHelper.showInfo(
                          context,
                          'Account deletion is not yet implemented',
                        );
                      }
                    : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
                child: Text(l10n.delete),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDiagnosticsSheet() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.diagnostics,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2.h),
              _DiagnosticRow(
                label: l10n.buildVersion,
                value: '1.0.0',
              ),
              _DiagnosticRow(
                label: l10n.lastSync,
                value: l10n.notAvailable,
              ),
              _DiagnosticRow(
                label: l10n.lastError,
                value: l10n.none,
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.ok),
                ),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleRestorePurchases() async {
    setState(() => _isRestoring = true);
    try {
      await _subscriptionService.restorePurchases();
      await _loadPlanStatus();
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
    await _loadPlanStatus();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final canExport = _entitlementService.canExportData(_currentPlan);

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvasFrostedLight,
      bottomNavigationBar: CustomBottomBar(
        currentItem: BottomBarItem.settings,
        onItemSelected: (_) {},
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2.h),

              // Upgrade Banner (Free users only)
              if (_currentPlan == PlanType.free) ...[
                _UpgradeBanner(onTap: _handleUpgrade),
                SizedBox(height: 2.h),
              ],

              // Section 1: Account
              _SectionCard(
                title: l10n.account,
                children: [
                  SettingTile(
                    iconName: 'person',
                    title: l10n.name,
                    subtitle: _userName ?? '-',
                    enabled: false,
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'email',
                    title: l10n.email,
                    subtitle: _userEmail ?? '-',
                    enabled: false,
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'delete_outline',
                    title: l10n.deleteAccount,
                    subtitle: l10n.deleteAccountDesc,
                    onTap: _showDeleteAccountDialog,
                    iconColor: AppColors.error,
                    showDivider: false,
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Section 2: Subscription
              _SectionCard(
                title: l10n.subscription,
                children: [
                  SettingTile(
                    iconName: 'card_membership',
                    title: l10n.currentPlan,
                    subtitle: _currentPlan == PlanType.premium
                        ? l10n.premiumPlan
                        : l10n.freePlan,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.subscriptionScreen,
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'settings',
                    title: l10n.manageSubscription,
                    subtitle: _isMobilePlatform
                        ? l10n.manageSubscriptionHint
                        : l10n.availableOnMobileOnly,
                    enabled: _isMobilePlatform,
                    onTap: _isMobilePlatform
                        ? () {
                            SnackbarHelper.showInfo(
                                context, l10n.manageSubscriptionHint);
                          }
                        : null,
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'refresh',
                    title: l10n.restorePurchases,
                    subtitle: _isMobilePlatform
                        ? l10n.restorePurchasesDesc
                        : l10n.availableOnMobileOnly,
                    enabled: _isMobilePlatform && !_isRestoring,
                    onTap: _isMobilePlatform ? _handleRestorePurchases : null,
                    trailing: _isRestoring
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : null,
                    showDivider: false,
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Section 3: General Settings
              _SectionCard(
                title: l10n.generalSettings,
                children: [
                  SettingTile(
                    iconName: 'language',
                    title: l10n.language,
                    subtitle: _currentLanguage == 'en'
                        ? l10n.languageEnglish
                        : l10n.languagePortuguese,
                    onTap: _showLanguageSelector,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'dark_mode',
                    title: l10n.darkMode,
                    subtitle:
                        _isDarkMode ? l10n.darkModeEnabled : l10n.darkModeDisabled,
                    trailing: Switch(
                      value: _isDarkMode,
                      onChanged: _toggleDarkMode,
                      activeThumbColor: AppColors.blue600,
                      activeTrackColor: AppColors.blueBg50,
                    ),
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'attach_money',
                    title: l10n.currency,
                    subtitle: _currentCurrency ?? '...',
                    onTap: _currentCurrency != null ? _showCurrencySelector : null,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'calendar_today',
                    title: l10n.firstDayOfWeek,
                    subtitle: _firstDayOfWeek == 0 ? l10n.sunday : l10n.monday,
                    onTap: _showFirstDayOfWeekDialog,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    showDivider: false,
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Section 4: Privacy and Security
              _SectionCard(
                title: l10n.privacySecurity,
                children: [
                  SettingTile(
                    iconName: 'fingerprint',
                    title: l10n.biometricAuth,
                    subtitle: _biometricEnabled
                        ? l10n.biometricEnabled
                        : l10n.biometricDisabled,
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                      activeThumbColor: AppColors.blue600,
                      activeTrackColor: AppColors.blueBg50,
                    ),
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'notifications',
                    title: l10n.notifications,
                    subtitle: _notificationsEnabled
                        ? l10n.notificationsEnabled
                        : l10n.notificationsDisabled,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeThumbColor: AppColors.blue600,
                      activeTrackColor: AppColors.blueBg50,
                    ),
                    showDivider: false,
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Section 5: Data
              _SectionCard(
                title: l10n.dataAndExport,
                children: [
                  SettingTile(
                    iconName: 'upload_file',
                    title: l10n.exportData,
                    subtitle: canExport
                        ? l10n.exportDataDescription
                        : l10n.upgradeForExport,
                    enabled: canExport,
                    onTap: canExport ? _showExportOptions : null,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: canExport
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                    showDivider: true,
                  ),
                  // Reset Onboarding - Debug only
                  if (kDebugMode)
                    SettingTile(
                      iconName: 'restart_alt',
                      title: l10n.resetOnboarding,
                      subtitle: l10n.resetOnboardingDesc,
                      onTap: _handleResetOnboarding,
                      showDivider: true,
                    ),
                  SettingTile(
                    iconName: 'cached',
                    title: l10n.clearCache,
                    subtitle: l10n.clearCacheDesc,
                    enabled: false, // No cache service exists
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'bug_report',
                    title: l10n.diagnostics,
                    subtitle: l10n.diagnosticsDesc,
                    onTap: _showDiagnosticsSheet,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    showDivider: false,
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Section 6: Support
              _SectionCard(
                title: l10n.support,
                children: [
                  SettingTile(
                    iconName: 'help_outline',
                    title: l10n.contactSupport,
                    subtitle: l10n.contactSupportDesc,
                    onTap: () {
                      SnackbarHelper.showInfo(context, l10n.openingSupport);
                    },
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'privacy_tip',
                    title: l10n.privacyPolicy,
                    subtitle: l10n.privacyPolicyDesc,
                    onTap: () {
                      SnackbarHelper.showInfo(context, l10n.openingPrivacyPolicy);
                    },
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    showDivider: true,
                  ),
                  SettingTile(
                    iconName: 'description',
                    title: l10n.termsOfService,
                    subtitle: l10n.termsOfServiceDesc,
                    onTap: () {
                      SnackbarHelper.showInfo(context, 'Opening terms...');
                    },
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    showDivider: false,
                  ),
                ],
              ),

              SizedBox(height: kBottomNavClearance),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Private Widgets
// =============================================================================

/// Card wrapper for settings sections with frosted glass styling
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 2.w, bottom: 1.h),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.slate500,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.zero,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
            boxShadow: AppShadows.cardLight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceGlass80Light,
                borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
                border: Border.all(
                  color: AppColors.borderGlass60Light,
                  width: 1,
                ),
              ),
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }
}

/// Upgrade banner for free users with frosted glass styling
class _UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _UpgradeBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        boxShadow: AppShadows.cardLight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
        child: Material(
          color: AppColors.blue600,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppTheme.radiusIconBox),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.upgradeToPremium,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          l10n.premiumDescription,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Diagnostic info row
class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;

  const _DiagnosticRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
