// lib/features/settings/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../common/providers/theme_provider.dart';
import '../../common/providers/language_provider.dart';
import '../../common/providers/app_language_provider.dart';
import '../../common/services/settings_service.dart';
import '../../common/widgets/app_back_button_handler.dart';
import '../../common/network/api_client.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _articlesBox = 'articles_box';
  static const _historyBox = 'history_box';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);
    final appLocale = ref.watch(appLanguageProvider);

    return AppBackButtonHandler(
      fallbackRoute: '/search',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBackPress(context),
            tooltip: 'Back',
          ),
          actions: [
            IconButton(
              onPressed: () => context.go('/search'),
              icon: const Icon(Icons.search),
              tooltip: 'Search',
            ),
          ],
        ),
        body: ListView(
          children: [
            _buildSectionHeader(context, 'Appearance', Icons.palette_outlined),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildThemeOption(
                    context,
                    ref,
                    'Light',
                    Icons.light_mode_outlined,
                    ThemeMode.light,
                    themeMode,
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    context,
                    ref,
                    'Dark',
                    Icons.dark_mode_outlined,
                    ThemeMode.dark,
                    themeMode,
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    context,
                    ref,
                    'System',
                    Icons.brightness_auto_outlined,
                    ThemeMode.system,
                    themeMode,
                  ),
                ],
              ),
            ),
            _buildSectionHeader(
                context, 'Language Settings', Icons.language_outlined),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.public_outlined),
                    title: const Text('Wikipedia Domain'),
                    subtitle: Text('$language.wikipedia.org'),
                    trailing: DropdownButton<String>(
                      value: language,
                      items: SettingsService.supportedLanguages.entries
                          .map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text('${entry.value} (${entry.key})'),
                        );
                      }).toList(),
                      onChanged: (newLanguage) async {
                        if (newLanguage != null) {
                          ref
                              .read(languageProvider.notifier)
                              .setLanguage(newLanguage);
                          await ApiClient().updateLanguage(newLanguage);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Wikipedia language changed to ${SettingsService.supportedLanguages[newLanguage]}',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.translate_outlined),
                    title: const Text('App Interface Language'),
                    subtitle: Text(
                      '${SettingsService.appLanguages[appLocale.languageCode] ?? 'English'} (${appLocale.languageCode})',
                    ),
                    trailing: DropdownButton<String>(
                      value: appLocale.languageCode,
                      items: SettingsService.appLanguages.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text('${entry.value} (${entry.key})'),
                        );
                      }).toList(),
                      onChanged: (newLanguage) {
                        if (newLanguage != null) {
                          ref
                              .read(appLanguageProvider.notifier)
                              .setLanguage(newLanguage);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'App language changed to ${SettingsService.appLanguages[newLanguage]}',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionHeader(context, 'Reading', Icons.history),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Reading History'),
                    subtitle:
                        const Text('See the articles you opened recently'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/history'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bookmark_outline),
                    title: const Text('Saved Articles'),
                    subtitle: const Text('Manage your offline saved articles'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/saved'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_outlined),
                    title: const Text('Clear reading history'),
                    subtitle: const Text('Remove all items from history'),
                    onTap: () async => _confirmAndClear(
                      context: context,
                      title: 'Clear history?',
                      body:
                          'This will permanently remove your reading history. This action cannot be undone.',
                      onConfirm: () async {
                        await Hive.box(_historyBox).clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Reading history cleared')),
                          );
                        }
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_sweep_outlined),
                    title: const Text('Clear cached articles'),
                    subtitle:
                        const Text('Free up space by clearing HTML cache'),
                    onTap: () async => _confirmAndClear(
                      context: context,
                      title: 'Clear cached articles?',
                      body:
                          'This will remove cached article HTML. Saved (offline) flags will also be removed.',
                      onConfirm: () async {
                        await Hive.box(_articlesBox).clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Article cache cleared')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            _buildSectionHeader(
                context, 'Data & Privacy', Icons.security_outlined),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About Wikipedia Client'),
                    subtitle: const Text('Version 1.0.0'),
                    onTap: () => _showAboutDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.copyright_outlined),
                    title: const Text('Content License'),
                    subtitle: const Text('CC BY-SA 4.0'),
                    onTap: () => _showLicenseDialog(context),
                  ),
                ],
              ),
            ),
            _buildSectionHeader(context, 'Support', Icons.help_outline),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.bug_report_outlined),
                    title: const Text('Report Issue'),
                    subtitle: const Text('Found a bug? Let us know'),
                    onTap: () => _showReportDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.school_outlined),
                    title: const Text('Developed by'),
                    subtitle: const Text('USTH Group 7'),
                    onTap: () => _showDeveloperDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    ThemeMode mode,
    ThemeMode currentMode,
  ) {
    final isSelected = currentMode == mode;

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(_getThemeDescription(mode)),
      trailing: isSelected
          ? Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () => ref.read(themeProvider.notifier).setTheme(mode),
    );
  }

  String _getThemeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system setting';
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Wikipedia Client',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.public, size: 48),
      applicationLegalese:
          'A Flutter app for browsing Wikipedia articles with a clean, modern interface.',
      children: const [
        SizedBox(height: 16),
        Text(
          'This application uses Wikipedia APIs to provide access to Wikipedia content. '
          'All content is available under Creative Commons Attribution-ShareAlike 4.0 International License.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Content License'),
        content: const SingleChildScrollView(
          child: Text(
            'Wikipedia content is available under the Creative Commons Attribution-ShareAlike 4.0 International License (CC BY-SA 4.0).\n\n'
            'This means you are free to:\n'
            '• Share — copy and redistribute the material\n'
            '• Adapt — remix, transform, and build upon the material\n\n'
            'Under the following terms:\n'
            '• Attribution — You must give appropriate credit\n'
            '• ShareAlike — If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original.\n\n'
            'For more information, visit: https://creativecommons.org/licenses/by-sa/4.0/',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: const Text(
          'If you encounter any bugs or have suggestions for improvement, '
          'please contact the development team at USTH Group 7.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showDeveloperDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Development Team'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wikipedia Client',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Text('Developed by USTH Group 7'),
            Text('University of Science and Technology of Hanoi'),
            SizedBox(height: 16),
            Text('Built with Flutter and Wikipedia APIs',
                style: TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _confirmAndClear({
    required BuildContext context,
    required String title,
    required String body,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) {
      await onConfirm();
    }
  }

  void _handleBackPress(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/search');
    }
  }
}
