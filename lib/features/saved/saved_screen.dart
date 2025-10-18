// lib/features/saved/saved_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../common/widgets/app_back_button_handler.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  static const _articlesBoxName = 'articles_box';

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(_articlesBoxName);

    return AppBackButtonHandler(
      fallbackRoute: '/search',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saved Articles'),
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
            IconButton(
              tooltip: 'Clear all saved',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearAllSaved(context, box),
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box b, _) {
            final saved = _readSaved(b);

            if (saved.isEmpty) {
              return const Center(child: Text('No saved articles yet'));
            }

            return ListView.separated(
              itemCount: saved.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final e = saved[i];
                final title = e.title;
                final cachedAt = e.cachedAt;
                final formatted = cachedAt == null
                    ? ''
                    : '${cachedAt.day.toString().padLeft(2, '0')}/'
                        '${cachedAt.month.toString().padLeft(2, '0')}/'
                        '${cachedAt.year} '
                        '${cachedAt.hour.toString().padLeft(2, '0')}:'
                        '${cachedAt.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  leading: const Icon(Icons.bookmark),
                  title: Text(title),
                  subtitle: formatted.isEmpty
                      ? null
                      : Text('Saved: $formatted',
                          style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _unsetSavedFlag(b, e.key),
                  ),
                  onTap: () {
                    final qp =
                        StringBuffer('title=${Uri.encodeComponent(title)}');
                    if (e.lang != null && e.lang!.isNotEmpty) {
                      qp.write('&lang=${e.lang}');
                    }
                    context.push('/article?$qp');
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _handleBackPress(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/search');
    }
  }

  Future<void> _unsetSavedFlag(Box box, dynamic key) async {
    final rec = box.get(key);
    if (rec is Map) {
      await box.put(key, {
        ...rec,
        'savedOffline': false,
      });
    }
  }

  Future<void> _confirmClearAllSaved(BuildContext context, Box box) async {
    final hasAny = box.values.any((v) => v is Map && v['savedOffline'] == true);
    if (!hasAny) return;

    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all saved?'),
        content: const Text(
            'This will remove the “saved offline” flag from all articles.'),
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

    if (yes == true) {
      final map = box.toMap();
      for (final entry in map.entries) {
        final v = entry.value;
        if (v is Map && v['savedOffline'] == true) {
          await box.put(entry.key, {...v, 'savedOffline': false});
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All saved flags removed')),
        );
      }
    }
  }

  /// Read the list of saved articles, with key + language inferred from the Hive key, sorted by cachedAt (descending).
  List<_SavedItem> _readSaved(Box box) {
    final List<_SavedItem> out = [];
    final map = box.toMap();

    for (final entry in map.entries) {
      final key = entry.key;
      final v = entry.value;

      if (v is! Map || v['savedOffline'] != true) continue;

      final title = (v['title'] ?? '').toString();
      final cachedAtStr = (v['cachedAt'] ?? '').toString();
      final cachedAt = DateTime.tryParse(cachedAtStr);

      String? lang;
      if (key is String && key.startsWith('article:')) {
        final parts = key.split(':');
        if (parts.length >= 3) {
          lang = parts[1];
        }
      }

      out.add(
          _SavedItem(key: key, title: title, cachedAt: cachedAt, lang: lang));
    }

    out.sort((a, b) {
      final da = a.cachedAt ?? DateTime(1970);
      final db = b.cachedAt ?? DateTime(1970);
      return db.compareTo(da);
    });

    return out;
  }
}

class _SavedItem {
  final dynamic key;
  final String title;
  final DateTime? cachedAt;
  final String? lang;

  _SavedItem({
    required this.key,
    required this.title,
    required this.cachedAt,
    required this.lang,
  });
}
