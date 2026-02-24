import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../core/logging/app_logger.dart';
import '../../domain/entitlements/entitlement_service.dart';
import '../../domain/entitlements/plan_type.dart';
import '../../domain/usage/limit_reached_exception.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../services/onboarding_status_repository.dart';
import '../../services/subscription/subscription_service.dart';
import '../../services/transaction_export_service.dart';
import '../../services/transaction_import_service.dart';
import '../../services/transactions_repository.dart';
import '../../services/user_settings_service.dart';
import '../../theme/app_colors_ext.dart';
import '../../services/biometric_auth_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/custom_bottom_bar.dart';
import './widgets/currency_selector_dialog.dart';
import './widgets/export_options_dialog.dart';
import './widgets/import_dialog.dart';
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
  final _biometricService = BiometricAuthService();

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
  bool _biometricSupported = false;
  BiometricDisplayType _biometricType = BiometricDisplayType.unknown;
  bool _notificationsEnabled = true;
  bool _diagnosticsEnabled = false;

  // Financial preferences
  double _taxPercent = 0.25;
  double _safetyPercent = 0.10;
  bool _taxExpanded = false;
  bool _safetyExpanded = false;

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
    final taxPercent = await _userSettingsService.getTaxShieldPercent();
    final safetyPercent = await _userSettingsService.getSafetyBufferPercent();

    // Check biometric support
    final isSupported = await _biometricService.isDeviceSupported();
    var biometricEnabled = prefs.getBool('biometric') ?? false;

    if (isSupported) {
      await _biometricService.getAvailableBiometrics();
    }

    // Handle: user enabled biometrics but later removed enrollment
    if (biometricEnabled && !isSupported) {
      await _biometricService.setBiometricEnabled(false);
      biometricEnabled = false;
    }

    if (!mounted) return;
    setState(() {
      _currentLanguage = prefs.getString('language') ?? 'en';
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _currentCurrency = currencySettings.currencyCode;
      _firstDayOfWeek = prefs.getInt('firstDayOfWeek') ?? 0;
      _biometricEnabled = biometricEnabled;
      _biometricSupported = isSupported;
      _biometricType = _biometricService.getPrimaryBiometricType();
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _diagnosticsEnabled = prefs.getBool('diagnostics') ?? false;
      _taxPercent = taxPercent;
      _safetyPercent = safetyPercent;
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
    MyApp.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context)!;

    if (value) {
      // Require biometric verification to enable (localized)
      final result = await _biometricService.authenticate(
        localizedReason: l10n.biometricVerifyToEnable,
        biometricOnly: true,
      );
      if (result != BiometricAuthResult.success) {
        if (mounted) {
          SnackbarHelper.showError(context, l10n.biometricVerificationFailed);
        }
        return;
      }
    }
    setState(() => _biometricEnabled = value);
    await _biometricService.setBiometricEnabled(value);
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

  // ── Export ──────────────────────────────────────────────────────────────────

  Future<void> _showExportOptions() async {
    if (kIsWeb) {
      SnackbarHelper.showInfo(context, 'Export is available on the mobile app.');
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => ExportOptionsDialog(
        onExportSelected: _handleExport,
      ),
    );
  }

  Future<void> _handleExport(String format) async {
    if (!mounted) return;

    // 1. Date range picker (defaults: Jan 1 this year → today)
    final now = DateTime.now();
    final defaultStart = DateTime(now.year, 1, 1);

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: defaultStart, end: now),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.blue600,
            onPrimary: Colors.white,
            surface: context.canvasFrosted,
            onSurface: context.slate900,
            surfaceContainerHighest: context.surfaceGlass80,
          ),
        ),
        child: child!,
      ),
    );

    if (range == null || !mounted) return;

    // 2. Loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Include the full last day of the selected range
      final endOfDay = DateTime(
        range.end.year, range.end.month, range.end.day, 23, 59, 59,
      );

      final transactions = await TransactionsRepository()
          .getTransactionsByDateRangeTyped(range.start, endOfDay);

      if (mounted) Navigator.pop(context); // close loading
      if (!mounted) return;

      if (transactions.isEmpty) {
        SnackbarHelper.showInfo(
          context,
          'No transactions found in the selected period.',
        );
        return;
      }

      // 3. Generate file and open share sheet
      final path = await TransactionExportService()
          .writeExportToDisk(transactions, format);

      final mimeType = format == 'csv'
          ? 'text/csv'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

      await Share.shareXFiles(
        [XFile(path, mimeType: mimeType)],
        subject: 'InCore Finance — Transaction Export',
      );
    } catch (e) {
      AppLogger.w('[Settings] Export failed', error: e);
      if (mounted) {
        // Close loading dialog if still open
        Navigator.of(context, rootNavigator: true).popUntil(
          (route) => route.settings.name != null || route.isFirst,
        );
        SnackbarHelper.showError(context, 'Export failed. Please try again.');
      }
    }
  }

  // ── End Export ──────────────────────────────────────────────────────────────

  // ── Import ──────────────────────────────────────────────────────────────────

  Future<void> _showImportOptions() async {
    await showDialog(
      context: context,
      builder: (_) => ImportDialog(
        onFormatSelected: _handleImportFile,
        onDownloadTemplate: _downloadTemplate,
      ),
    );
  }

  Future<void> _handleImportFile(String format) async {
    final extensions = format == 'csv' ? ['csv'] : ['xlsx'];
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true, // load bytes in memory (works on iOS/Android)
    );
    if (result == null || result.files.isEmpty || !mounted) return;

    final file = result.files.first;
    final service = TransactionImportService();
    List<TransactionImportRow> rows;

    try {
      if (format == 'csv') {
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }
        if (bytes == null) throw Exception('Could not read file');
        rows = service.parseCSV(String.fromCharCodes(bytes));
      } else {
        Uint8List? bytes = file.bytes;
        if (bytes == null && file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }
        if (bytes == null) throw Exception('Could not read file');
        rows = service.parseExcel(bytes);
      }
    } catch (_) {
      if (mounted) SnackbarHelper.showError(context, AppLocalizations.of(context)!.importFailed);
      return;
    }

    if (!mounted) return;
    await _showImportPreview(rows, service);
  }

  Future<void> _showImportPreview(
    List<TransactionImportRow> rows,
    TransactionImportService service,
  ) async {
    final valid = service.validRows(rows);
    final invalid = service.invalidRows(rows);

    // File-level structural error (e.g. missing column)
    if (rows.length == 1 && rows.first.rowNumber == 0 && !rows.first.isValid) {
      SnackbarHelper.showError(context, rows.first.validationError ?? AppLocalizations.of(context)!.importFailed);
      return;
    }

    if (rows.isEmpty || (valid.isEmpty && invalid.isEmpty)) {
      SnackbarHelper.showError(context, 'No transactions found in the file.');
      return;
    }

    final dateRange = service.detectDateRange(rows);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _ImportPreviewSheet(
        validRows: valid,
        invalidRows: invalid,
        dateRange: dateRange,
        onConfirm: () {
          Navigator.pop(sheetCtx);
          _runImport(valid);
        },
      ),
    );
  }

  Future<void> _runImport(List<TransactionImportRow> rows) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;

    // Loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final result = await TransactionsRepository().importTransactions(rows);
      if (mounted) Navigator.pop(context); // close loading
      if (!mounted) return;

      if (!result.hasErrors) {
        SnackbarHelper.showSuccess(context, l10n.importSuccess(result.imported));
      } else if (result.imported > 0) {
        SnackbarHelper.showWarning(
          context,
          l10n.importPartialSuccess(result.imported, result.failed),
        );
        _showImportErrors(result.rowErrors);
      } else {
        SnackbarHelper.showError(context, l10n.importFailed);
        _showImportErrors(result.rowErrors);
      }
    } on LimitReachedException {
      if (mounted) Navigator.pop(context); // paywall already shown
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        SnackbarHelper.showError(context, AppLocalizations.of(context)!.importFailed);
      }
    }
  }

  void _showImportErrors(List<ImportRowError> errors) {
    if (!mounted || errors.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Skipped Rows'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: errors.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = errors[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Row ${e.rowNumber}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        e.reason,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _downloadTemplate() async {
    if (kIsWeb) {
      if (mounted) {
        SnackbarHelper.showInfo(
          context,
          'Template download is available on the mobile app.',
        );
      }
      return;
    }

    try {
      final path = await TransactionImportService().writeTemplateToDisk();
      await Share.shareXFiles(
        [
          XFile(
            path,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'InCore Finance — Import Template',
      );
    } catch (e) {
      AppLogger.w('[Settings] Template download failed', error: e);
      if (mounted) {
        SnackbarHelper.showError(context, 'Could not prepare the template. Please try again.');
      }
    }
  }

  // ── End Import ──────────────────────────────────────────────────────────────

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
                  foregroundColor: context.error,
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
      backgroundColor: context.canvasFrosted,
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
                    iconColor: context.error,
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
                      activeThumbColor: context.blue600,
                      activeTrackColor: context.blue50,
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

              // Section 4: Financial Preferences
              _SectionCard(
                title: l10n.financialPreferencesTitle,
                children: [
                  _PercentSliderTile(
                    title: l10n.taxReserveTitle,
                    subtitle: l10n.taxReserveBody,
                    value: _taxPercent,
                    isExpanded: _taxExpanded,
                    onExpandToggle: () {
                      setState(() => _taxExpanded = !_taxExpanded);
                    },
                    onChanged: (value) {
                      setState(() => _taxPercent = value);
                    },
                    onChangeEnd: (value) async {
                      await _userSettingsService.setTaxShieldPercent(value);
                      if (mounted) {
                        SnackbarHelper.showSuccess(
                          context,
                          l10n.taxReserveUpdatedSnack,
                        );
                      }
                    },
                    showDivider: true,
                  ),
                  _PercentSliderTile(
                    title: l10n.safetyBufferPercentLabel,
                    subtitle: l10n.safetyBufferPercentHelper,
                    value: _safetyPercent,
                    isExpanded: _safetyExpanded,
                    onExpandToggle: () {
                      setState(() => _safetyExpanded = !_safetyExpanded);
                    },
                    onChanged: (value) {
                      setState(() => _safetyPercent = value);
                    },
                    onChangeEnd: (value) async {
                      await _userSettingsService.setSafetyBufferPercent(value);
                      if (mounted) {
                        SnackbarHelper.showSuccess(
                          context,
                          l10n.safetyBufferUpdatedSnack,
                        );
                      }
                    },
                    showDivider: false,
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Section 5: Privacy and Security
              _SectionCard(
                title: l10n.privacySecurity,
                children: [
                  if (_isMobilePlatform)
                    SettingTile(
                      iconName: _biometricType == BiometricDisplayType.face
                          ? 'face_unlock'
                          : 'fingerprint',
                      title: l10n.biometricAuth,
                      subtitle: _biometricEnabled
                          ? l10n.biometricEnabled
                          : l10n.biometricDisabled,
                      enabled: _biometricSupported,
                      trailing: _biometricSupported
                          ? Switch(
                              value: _biometricEnabled,
                              onChanged: _toggleBiometric,
                              activeThumbColor: context.blue600,
                              activeTrackColor: context.blue50,
                            )
                          : null,
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
                      activeThumbColor: context.blue600,
                      activeTrackColor: context.blue50,
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
                  SettingTile(
                    iconName: 'file_download',
                    title: l10n.importData,
                    subtitle: l10n.importDataDescription,
                    onTap: _showImportOptions,
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
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
              color: context.slate500,
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
                color: context.surfaceGlass80,
                borderRadius: BorderRadius.circular(AppTheme.radiusCardXL),
                border: Border.all(
                  color: context.borderGlass60,
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
          color: context.blue600,
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

/// Expandable percent slider tile for financial preferences
class _PercentSliderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double value;
  final bool isExpanded;
  final VoidCallback onExpandToggle;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final bool showDivider;

  const _PercentSliderTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isExpanded,
    required this.onExpandToggle,
    required this.onChanged,
    required this.onChangeEnd,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percentDisplay = '${(value * 100).round()}%';

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onExpandToggle,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Row(
                children: [
                  Container(
                    width: 10.w,
                    height: 10.w,
                    decoration: BoxDecoration(
                      color: context.blue50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.percent,
                        size: 5.w,
                        color: context.blue600,
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.blue50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      percentDisplay,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: context.blue600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Expandable slider section
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(
              left: 4.w,
              right: 4.w,
              bottom: 2.h,
            ),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: context.blue600,
                    inactiveTrackColor: context.blue50,
                    thumbColor: context.blue600,
                    overlayColor: context.blue600.withValues(alpha: 0.12),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 10,
                    ),
                  ),
                  child: Slider(
                    value: value,
                    min: 0.0,
                    max: 0.50,
                    divisions: 50,
                    onChanged: onChanged,
                    onChangeEnd: onChangeEnd,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '50%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 17.w),
            child: Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
      ],
    );
  }
}

// ── Import preview bottom sheet ───────────────────────────────────────────────

class _ImportPreviewSheet extends StatefulWidget {
  final List<TransactionImportRow> validRows;
  final List<TransactionImportRow> invalidRows;
  final ({DateTime min, DateTime max})? dateRange;
  final VoidCallback onConfirm;

  const _ImportPreviewSheet({
    required this.validRows,
    required this.invalidRows,
    required this.dateRange,
    required this.onConfirm,
  });

  @override
  State<_ImportPreviewSheet> createState() => _ImportPreviewSheetState();
}

class _ImportPreviewSheetState extends State<_ImportPreviewSheet> {
  bool _showErrors = false;

  String _formatDate(DateTime d) =>
      '${_monthAbbr(d.month)} ${d.year}';

  String _monthAbbr(int m) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasErrors = widget.invalidRows.isNotEmpty;
    final hasValid = widget.validRows.isNotEmpty;
    final dr = widget.dateRange;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Padding(
        padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 10.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            SizedBox(height: 2.h),

            Text(
              'Ready to Import',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.5.h),

            // Valid count
            _SummaryRow(
              icon: Icons.check_circle,
              iconColor: const Color(0xFF14B8A6),
              text: '${widget.validRows.length} transaction${widget.validRows.length == 1 ? '' : 's'} ready',
            ),

            // Error count
            if (hasErrors) ...[
              SizedBox(height: 0.8.h),
              _SummaryRow(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFE0A458),
                text: '${widget.invalidRows.length} row${widget.invalidRows.length == 1 ? '' : 's'} with errors (will be skipped)',
              ),
            ],

            // Date range
            if (dr != null) ...[
              SizedBox(height: 0.8.h),
              _SummaryRow(
                icon: Icons.date_range,
                iconColor: colorScheme.onSurfaceVariant,
                text: '${_formatDate(dr.min)} → ${_formatDate(dr.max)}',
              ),
            ],

            // Error detail toggle
            if (hasErrors) ...[
              SizedBox(height: 1.5.h),
              GestureDetector(
                onTap: () => setState(() => _showErrors = !_showErrors),
                child: Row(
                  children: [
                    Text(
                      _showErrors ? 'Hide errors' : 'View errors',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      _showErrors ? Icons.expand_less : Icons.expand_more,
                      size: 4.w,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
              if (_showErrors)
                Container(
                  margin: EdgeInsets.only(top: 1.h),
                  constraints: BoxConstraints(maxHeight: 20.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    controller: controller,
                    shrinkWrap: true,
                    padding: EdgeInsets.all(2.w),
                    itemCount: widget.invalidRows.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.15),
                    ),
                    itemBuilder: (_, i) {
                      final row = widget.invalidRows[i];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Row ${row.rowNumber}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 0.3.h),
                            Text(
                              row.validationError ?? '',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],

            const Spacer(),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasValid ? widget.onConfirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Import ${widget.validRows.length} Transaction${widget.validRows.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 18),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
