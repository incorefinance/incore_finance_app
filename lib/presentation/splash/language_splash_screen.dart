import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/locale/locale_store.dart';

/// First-launch language selection splash screen.
class LanguageSplashScreen extends StatefulWidget {
  final void Function(Locale locale) onLocaleSelected;

  const LanguageSplashScreen({
    super.key,
    required this.onLocaleSelected,
  });

  @override
  State<LanguageSplashScreen> createState() => _LanguageSplashScreenState();
}

class _LanguageSplashScreenState extends State<LanguageSplashScreen> {
  String _selectedCode = 'en';

  @override
  void initState() {
    super.initState();
    _autoDetectLocale();
  }

  /// Auto-detect device language and preselect accordingly.
  /// Uses platformDispatcher.locales (list) for resilient detection.
  /// Preselects Portuguese only if pt-PT is found in the list.
  void _autoDetectLocale() {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    final isPtPt = locales.any(
      (l) => l.languageCode == 'pt' && l.countryCode == 'PT',
    );
    setState(() => _selectedCode = isPtPt ? 'pt_PT' : 'en');
  }

  /// Returns the button label based on current selection.
  String get _buttonLabel {
    return _selectedCode == 'pt_PT' ? 'Começar' : 'Get Started';
  }

  Future<void> _onContinue() async {
    // Save selection
    await LocaleStore.saveLocaleCode(_selectedCode);

    // Parse to Locale and notify parent
    final locale = LocaleStore.parseToLocale(_selectedCode);
    if (locale != null) {
      widget.onLocaleSelected(locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Placeholder logo
              const Text(
                'LOGO',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),

              const SizedBox(height: 48),

              // Language dropdown selector with iOS frosted glass style
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCode,
                        dropdownColor: primaryBlue.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        selectedItemBuilder: (context) {
                          return [
                            _buildDropdownItem('\u{1F310}', 'English'),
                            _buildDropdownItem('\u{1F1F5}\u{1F1F9}', 'Português'),
                          ];
                        },
                        items: [
                          DropdownMenuItem(
                            value: 'en',
                            child: Row(
                              children: const [
                                Text(
                                  '\u{1F310}',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'English',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'pt_PT',
                            child: Row(
                              children: const [
                                Text(
                                  '\u{1F1F5}\u{1F1F9}',
                                  style: TextStyle(fontSize: 20),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Português',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCode = value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Primary button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _buttonLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownItem(String flag, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          flag,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
