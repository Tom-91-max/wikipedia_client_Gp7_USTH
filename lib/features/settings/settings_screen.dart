import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _lang = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Language (domain)'),
            subtitle: Text('$_lang.wikipedia.org'),
            trailing: DropdownButton<String>(
              value: _lang,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English (en)')),
                DropdownMenuItem(value: 'vi', child: Text('Vietnamese (vi)')),
                DropdownMenuItem(value: 'fr', child: Text('French (fr)')),
                DropdownMenuItem(value: 'ja', child: Text('Japanese (ja)')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _lang = v);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Not applied to API yet: $_lang')),
                );
              },
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Dark mode (system)'),
            subtitle: const Text('Follows system theme'),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Use system theme — change in OS settings')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('About'),
            subtitle: const Text('Data from Wikipedia (CC BY-SA 4.0)'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Wikipedia Client',
                applicationVersion: '1.0.0',
                applicationLegalese:
                'This app uses Wikipedia APIs. Content is available under CC BY-SA 4.0.',
              );
            },
          ),
        ],
      ),
    );
  }
}
