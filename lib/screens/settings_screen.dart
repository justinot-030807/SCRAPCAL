import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  final AppLanguage language;
  final bool isDarkMode;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onDarkModeChanged;

  const SettingsScreen({
    super.key,
    required this.language,
    required this.isDarkMode,
    required this.onLanguageChanged,
    required this.onDarkModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final s = AppStrings(language);

    return Scaffold(
      backgroundColor: p.scaffold,
      appBar: AppBar(
        backgroundColor: p.headerBg,
        foregroundColor: p.headerFg,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: p.headerBg,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        title: Text(
          s.settingsTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: p.headerFg,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  // Language Section (Wika / Language)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.translate_rounded,
                              size: 20,
                              color: p.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.languageLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: p.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SegmentChoiceButton(
                                key: const Key('lang_tagalog_btn'),
                                label: 'Tagalog',
                                selected: language == AppLanguage.tagalog,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onLanguageChanged(AppLanguage.tagalog);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SegmentChoiceButton(
                                key: const Key('lang_english_btn'),
                                label: 'English',
                                selected: language == AppLanguage.english,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onLanguageChanged(AppLanguage.english);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Theme Section (Tema / Theme)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.border, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDarkMode
                                  ? Icons.dark_mode_outlined
                                  : Icons.light_mode_outlined,
                              size: 20,
                              color: p.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.themeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: p.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _SegmentChoiceButton(
                                key: const Key('theme_light_btn'),
                                icon: Icons.light_mode_outlined,
                                label: s.lightModeLabel,
                                selected: !isDarkMode,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onDarkModeChanged(false);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SegmentChoiceButton(
                                key: const Key('theme_dark_btn'),
                                icon: Icons.dark_mode_outlined,
                                label: s.darkModeLabel,
                                selected: isDarkMode,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  onDarkModeChanged(true);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Developer Credit Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.appTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.developerCredit,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: p.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentChoiceButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentChoiceButton({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: selected ? p.primary : p.scaffold,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? p.primaryDark : p.border,
              width: 1.5,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? const Color(0xFFFFFFFF) : p.ink,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: selected ? const Color(0xFFFFFFFF) : p.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
