import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'discovery_providers.dart';
import 'discovery_service.dart';

class RandomArticleSection extends ConsumerWidget {
  const RandomArticleSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final randomArticleAsync = ref.watch(randomArticleProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.shuffle_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Discover Something New',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            randomArticleAsync.when(
              loading: () => _buildSkeleton(),
              error: (error, stack) => _buildError(context, ref),
              data: (article) {
                if (article == null) {
                  return _buildEmpty(ref);
                }
                return _buildRandomArticle(context, article, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRandomArticle(BuildContext context, WikipediaPage article, WidgetRef ref) {
    return Column(
      children: [
        if (article.thumbnailUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              article.thumbnailUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 120,
                color: Colors.grey[200],
                child: const Icon(Icons.article, size: 48, color: Colors.grey),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          article.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (article.description != null) ...[
          const SizedBox(height: 8),
          Text(
            article.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  ref.invalidate(randomArticleProvider);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('Another Random'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () {
                  _openArticle(context, article.title, article.contentUrl);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Read Article'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        Container(
          height: 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(
          height: 24,
          child: LinearProgressIndicator(),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          height: 16,
          child: LinearProgressIndicator(),
        ),
        const SizedBox(height: 8),
        const SizedBox(
          height: 16,
          child: LinearProgressIndicator(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(
          'Failed to load random article',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            ref.invalidate(randomArticleProvider);
          },
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  Widget _buildEmpty(WidgetRef ref) {
    return Column(
      children: [
        Icon(
          Icons.article_outlined,
          size: 64,
          color: Colors.grey[400],
        ),
        const SizedBox(height: 12),
        Text(
          'No random article available',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () {
            ref.invalidate(randomArticleProvider);
          },
          child: const Text('Try Again'),
        ),
      ],
    );
  }

  void _openArticle(BuildContext context, String title, String contentUrl) {
    // Navigate to article detail page
    context.push('/article?title=${Uri.encodeComponent(title)}&url=${Uri.encodeComponent(contentUrl)}');
  }
}