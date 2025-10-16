import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../common/widgets/app_back_button_handler.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
        body: ValueListenableBuilder(
          valueListenable: Hive.box('articles_box').listenable(),
          builder: (context, Box box, _) {
            // Lọc các bài được savedOffline = true
            final savedArticles = box.values
                .where((e) => e is Map && e['savedOffline'] == true)
                .toList();

            if (savedArticles.isEmpty) {
              return const Center(
                child: Text('No saved articles yet'),
              );
            }

            return ListView.separated(
              itemCount: savedArticles.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (context, i) {
                final a = savedArticles[i] as Map;
                final title = a['title'] ?? 'Untitled';
                final cachedAt = a['cachedAt'] ?? '';
                final date =
                    cachedAt.isNotEmpty ? DateTime.tryParse(cachedAt) : null;
                final formatted = date != null
                    ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
                    : '';

                return ListTile(
                  title: Text(title),
                  subtitle: formatted.isNotEmpty
                      ? Text('Saved: $formatted',
                          style: const TextStyle(fontSize: 12))
                      : null,
                  leading: const Icon(Icons.bookmark),
                  trailing: IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeSaved(box, title),
                  ),
                  onTap: () => context.push(
                    '/article?title=${Uri.encodeComponent(title)}',
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _removeSaved(Box box, String title) async {
    // tìm key trong box theo title
    final entry = box.toMap().entries.firstWhere(
          (e) => e.value is Map && e.value['title'] == title,
          orElse: () => const MapEntry(null, null),
        );
    if (entry.key == null) return;
    final rec = entry.value as Map;
    await box.put(entry.key, {
      ...rec,
      'savedOffline': false,
    });
  }

  void _handleBackPress(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/search');
    }
  }
}
