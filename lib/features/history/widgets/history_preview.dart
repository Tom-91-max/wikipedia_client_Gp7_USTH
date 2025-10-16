import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryPreview extends StatelessWidget {
  final int maxItems;
  const HistoryPreview({super.key, this.maxItems = 15});

  static const _boxName = 'history_box';

  Future<Box> _ensureBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return Hive.openBox(_boxName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Box>(
      future: _ensureBox(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final box = snap.data!;
        return ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, _, __) {
            final items = box.values
                .where((e) =>
                    e is Map && e['title'] != null && e['openedAt'] != null)
                .cast<Map>()
                .toList();

            if (items.isEmpty) return const SizedBox.shrink();

            items.sort((a, b) => (b['openedAt'] ?? '')
                .toString()
                .compareTo((a['openedAt'] ?? '').toString()));
            final display = items.take(maxItems).toList();

            return _Section(
              title: 'Lịch sử đọc gần đây',
              actionLabel: 'Xem tất cả',
              onAction: () => context.push('/history'),
              child: ListView.separated(
                shrinkWrap: true,
                primary: false,
                itemCount: display.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, i) {
                  final m = display[i];
                  final title = (m['title'] ?? '').toString();
                  final openedAt = (m['openedAt'] ?? '').toString();
                  final d = DateTime.tryParse(openedAt);
                  final label = d == null
                      ? ''
                      : '${d.day}/${d.month}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(label),
                    trailing: IconButton(
                      tooltip: 'Xoá',
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeOne(box, m),
                    ),
                    onTap: () => context
                        .push('/article?title=${Uri.encodeComponent(title)}'),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _removeOne(Box box, Map entry) async {
    final key = box.toMap().entries.firstWhere(
      (e) {
        final v = e.value;
        return v is Map &&
            v['title'] == entry['title'] &&
            v['openedAt'] == entry['openedAt'] &&
            v['lang'] == entry['lang'];
      },
      orElse: () => const MapEntry(null, null),
    ).key;
    if (key != null) await box.delete(key);
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget child;
  const _Section({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}
