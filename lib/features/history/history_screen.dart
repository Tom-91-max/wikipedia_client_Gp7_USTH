// lib/features/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../common/widgets/app_back_button_handler.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const _historyBoxName = 'history_box';

  @override
  Widget build(BuildContext context) {
    final box = Hive.box(_historyBoxName);

    return AppBackButtonHandler(
      fallbackRoute: '/search',
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reading History'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleBackPress(context),
            tooltip: 'Back',
          ),
          actions: [
            IconButton(
              tooltip: 'Clear all',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearAll(context, box),
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box b, _) {
            final items = _readHistory(b);

            if (items.isEmpty) {
              return _EmptyHistory(onGoSearch: () => context.go('/search'));
            }

            final grouped = _groupByDate(items);
            final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: dates.length,
              itemBuilder: (context, i) {
                final dateKey = dates[i];
                final dayItems = grouped[dateKey]!;
                return _HistorySection(
                  dateLabel: _prettyDate(dateKey),
                  entries: dayItems,
                  onRemove: (entry) => _removeEntry(b, entry),
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

  List<Map<String, dynamic>> _readHistory(Box box) {
    final list = box.values
        .where((e) => e is Map && e['title'] != null && e['openedAt'] != null)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    list.sort((a, b) {
      final da =
          DateTime.tryParse(a['openedAt'] as String? ?? '') ?? DateTime(1970);
      final db =
          DateTime.tryParse(b['openedAt'] as String? ?? '') ?? DateTime(1970);
      return db.compareTo(da);
    });
    return list;
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> items) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final e in items) {
      final openedAt =
          DateTime.tryParse(e['openedAt'] as String? ?? '') ?? DateTime(1970);
      final key = '${openedAt.year.toString().padLeft(4, '0')}-'
          '${openedAt.month.toString().padLeft(2, '0')}-'
          '${openedAt.day.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []).add(e);
    }
    return grouped;
  }

  String _prettyDate(String yyyymmdd) {
    final parts = yyyymmdd.split('-');
    if (parts.length != 3) return yyyymmdd;
    final y = parts[0], m = parts[1], d = parts[2];
    return '$d/$m/$y';
  }

  Future<void> _removeEntry(Box box, Map<String, dynamic> entry) async {
    final target = box.toMap().entries.firstWhere(
      (kv) {
        final v = kv.value;
        return v is Map &&
            v['title'] == entry['title'] &&
            v['openedAt'] == entry['openedAt'] &&
            v['lang'] == entry['lang'];
      },
      orElse: () => const MapEntry(null, null),
    );
    final key = target.key;
    if (key != null) {
      await box.delete(key);
    }
  }

  Future<void> _confirmClearAll(BuildContext context, Box box) async {
    if (box.isEmpty) return;

    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear history'),
        content: const Text('Remove all history entries?'),
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
      await box.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('History cleared')),
        );
      }
    }
  }
}

class _HistorySection extends StatelessWidget {
  final String dateLabel;
  final List<Map<String, dynamic>> entries;
  final Function(Map<String, dynamic> entry) onRemove;

  const _HistorySection({
    required this.dateLabel,
    required this.entries,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...entries
            .map((e) => _HistoryTile(entry: e, onRemove: onRemove))
            .toList(),
        const Divider(height: 0),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final Function(Map<String, dynamic>) onRemove;

  const _HistoryTile({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final title = entry['title']?.toString() ?? 'Untitled';
    final openedAt = DateTime.tryParse(entry['openedAt']?.toString() ?? '') ??
        DateTime(1970);
    final timeLabel =
        '${openedAt.hour.toString().padLeft(2, '0')}:${openedAt.minute.toString().padLeft(2, '0')}';
    final lang = entry['lang']?.toString();

    return Dismissible(
      key: ValueKey('${entry['title']}-${entry['openedAt']}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: Colors.redAccent,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        onRemove(entry);
        return true;
      },
      child: ListTile(
        title: Text(title),
        subtitle: Text(lang == null ? timeLabel : '$timeLabel • $lang'),
        leading: const Icon(Icons.history),
        trailing: IconButton(
          tooltip: 'Remove',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onRemove(entry),
        ),
        onTap: () {
          final qp = StringBuffer('title=${Uri.encodeComponent(title)}');
          if (lang != null && lang.isNotEmpty) {
            qp.write('&lang=$lang');
          }
          context.push('/article?$qp');
        },
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final VoidCallback onGoSearch;
  const _EmptyHistory({required this.onGoSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No history yet'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onGoSearch,
              icon: const Icon(Icons.search),
              label: const Text('Go to Search'),
            ),
          ],
        ),
      ),
    );
  }
}
