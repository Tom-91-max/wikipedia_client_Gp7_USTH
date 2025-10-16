import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../common/widgets/app_back_button_handler.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => _confirmClearAll(context),
            ),
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box('history_box').listenable(),
          builder: (context, Box box, _) {
            final items = _readHistory(box);

            if (items.isEmpty) {
              return const Center(child: Text('No history yet'));
            }

            // Group by yyyy-mm-dd
            final grouped = _groupByDate(items);
            final dates = grouped.keys.toList()
              ..sort((a, b) => b.compareTo(a)); // newest day first

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: dates.length,
              itemBuilder: (context, i) {
                final dateKey = dates[i];
                final dayItems = grouped[dateKey]!;
                return _HistorySection(
                  dateLabel: _prettyDate(dateKey),
                  entries: dayItems,
                  onRemove: (entry) => _removeEntry(box, entry),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ───────────────── helpers ─────────────────

  void _handleBackPress(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/search');
    }
  }

  List<Map<String, dynamic>> _readHistory(Box box) {
    // Normalize to Map<String,dynamic> & sort DESC by openedAt
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
    // yyy-mm-dd -> dd/MM/yyyy
    final parts = yyyymmdd.split('-');
    if (parts.length != 3) return yyyymmdd;
    final y = parts[0], m = parts[1], d = parts[2];
    return '$d/$m/$y';
  }

  Future<void> _removeEntry(Box box, Map<String, dynamic> entry) async {
    // history_box là box.add({...}) → không biết key trực tiếp,
    // ta tìm entry theo tất cả trường chính để xoá đúng dòng.
    final targetKey = box.toMap().entries.firstWhere(
      (kv) {
        final v = kv.value;
        return v is Map &&
            v['title'] == entry['title'] &&
            v['openedAt'] == entry['openedAt'] &&
            v['lang'] == entry['lang'];
      },
      orElse: () => const MapEntry(null, null),
    ).key;

    if (targetKey != null) {
      await box.delete(targetKey);
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final box = Hive.box('history_box');
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
        subtitle: Text(timeLabel),
        leading: const Icon(Icons.history),
        trailing: IconButton(
          tooltip: 'Remove',
          icon: const Icon(Icons.delete_outline),
          onPressed: () => onRemove(entry),
        ),
        onTap: () {
          context.push('/article?title=${Uri.encodeComponent(title)}');
        },
      ),
    );
  }
}
