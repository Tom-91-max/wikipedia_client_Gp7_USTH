import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import 'discovery_models.dart';
import 'discovery_providers.dart';

class FeaturedSection extends ConsumerWidget {
  const FeaturedSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(featuredContentProvider);
    return async.when(
      loading: () => const _Skeleton(),
      error: (e, _) => _ErrorTile(message: e.toString()),
      data: (article) {
        if (article == null)
          return const _ErrorTile(message: 'No featured today');
        return _buildFeaturedCard(context, article);
      },
    );
  }

  Widget _buildFeaturedCard(BuildContext context, FeaturedArticle article) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: article.thumbnailUrl!,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                if (article.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(
                    article.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Read'),
                    onPressed: () {
                      final title = article.title;
                      context
                          .push('/article?title=${Uri.encodeComponent(title)}');
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const SizedBox(height: 180),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String message;
  const _ErrorTile({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}
