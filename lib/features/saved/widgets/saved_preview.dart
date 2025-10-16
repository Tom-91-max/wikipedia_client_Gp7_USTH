import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SavedPreview extends StatelessWidget {
  final int maxItems;
  const SavedPreview({super.key, this.maxItems = 10});

  static const _boxName = 'articles_box';

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
            final savedArticles = box.values
                .where((e) => e is Map && e['savedOffline'] == true)
                .cast<Map>()
                .toList();

            if (savedArticles.isEmpty) return const SizedBox.shrink();

            savedArticles.sort((a, b) => (b['cachedAt'] ?? '')
                .toString()
                .compareTo((a['cachedAt'] ?? '').toString()));

            final display = savedArticles.take(maxItems).toList();

            return _Section(
              title: 'Đã lưu để đọc offline',
              actionLabel: 'Xem tất cả',
              onAction: () => context.push('/saved'),
              child: ListView.separated(
                shrinkWrap: true,
                primary: false,
                itemCount: display.length,
                separatorBuilder: (_, __) => const Divider(height: 0),
                itemBuilder: (context, i) {
                  final m = display[i];
                  final title = (m['title'] ?? '').toString();
                  final cachedAt = (m['cachedAt'] ?? '').toString();
                  final d = DateTime.tryParse(cachedAt);
                  final label = d == null
                      ? ''
                      : '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';

                  return ListTile(
                    leading: const Icon(Icons.bookmark),
                    title: Text(title,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: label.isNotEmpty
                        ? Text('Lưu: $label',
                            style: const TextStyle(fontSize: 12))
                        : null,
                    trailing: IconButton(
                      tooltip: 'Gỡ lưu',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _unsave(box, title),
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

  Future<void> _unsave(Box box, String title) async {
    final entry = box.toMap().entries.firstWhere(
          (e) => e.value is Map && e.value['title'] == title,
          orElse: () => const MapEntry(null, null),
        );
    if (entry.key == null) return;
    final rec = Map<String, dynamic>.from(entry.value as Map);
    await box.put(entry.key, {...rec, 'savedOffline': false});
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
