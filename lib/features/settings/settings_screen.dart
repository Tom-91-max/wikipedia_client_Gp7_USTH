import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/providers/theme_provider.dart';
import '../../common/providers/language_provider.dart';
import '../../common/services/settings_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
          // Theme Section
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

          // Language Section
          _buildSectionHeader(context, 'Wikipedia Language', Icons.language_outlined),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.public_outlined),
              title: const Text('Wikipedia Domain'),
              subtitle: Text('${language}.wikipedia.org'),
              trailing: DropdownButton<String>(
                value: language,
                items: SettingsService.supportedLanguages.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${entry.value} (${entry.key})'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newLanguage) {
                  if (newLanguage != null) {
                    ref.read(languageProvider.notifier).setLanguage(newLanguage);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Language changed to ${SettingsService.supportedLanguages[newLanguage]}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          // Data Section
          _buildSectionHeader(context, 'Data & Privacy', Icons.security_outlined),
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

          // Support Section
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
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
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
      trailing: isSelected ? Icon(
        Icons.check_circle,
        color: Theme.of(context).colorScheme.primary,
      ) : null,
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(mode);
      },
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
      applicationLegalese: 'A Flutter app for browsing Wikipedia articles with a clean, modern interface.',
      children: [
        const SizedBox(height: 16),
        const Text(
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
            child: const Text('Close'),
          ),
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
            child: const Text('Close'),
          ),
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
            Text(
              'Wikipedia Client',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text('Developed by USTH Group 7'),
            Text('University of Science and Technology of Hanoi'),
            SizedBox(height: 16),
            Text(
              'Built with Flutter and Wikipedia APIs',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
