import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'discovery_providers.dart';
import 'discovery_service.dart';

class OnThisDaySection extends ConsumerWidget {
  const OnThisDaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onThisDayAsync = ref.watch(onThisDayProvider);

    return onThisDayAsync.when(
      loading: () => _buildSkeleton(),
      error: (error, stack) => _buildError(context, error.toString()),
      data: (events) {
        if (events.isEmpty) {
          return _buildEmpty();
        }
        return _buildEventsList(context, events);
      },
    );
  }

  Widget _buildEventsList(BuildContext context, List<OnThisDayEvent> events) {
    return Column(
      children: events.map((event) => _buildEventCard(context, event)).toList(),
    );
  }

  Widget _buildEventCard(BuildContext context, OnThisDayEvent event) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.text,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (event.pages.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRelatedPages(context, event.pages),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedPages(BuildContext context, List<WikipediaPage> pages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Articles:',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pages.take(3).map((page) {
            return GestureDetector(
              onTap: () {
                _openArticle(context, page.title, page.contentUrl);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  page.title,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        _buildSkeletonCard(),
        const SizedBox(height: 12),
        _buildSkeletonCard(),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 16,
              child: LinearProgressIndicator(),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 16,
              child: LinearProgressIndicator(),
            ),
            SizedBox(height: 8),
            SizedBox(
              height: 16,
              child: LinearProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Failed to load historical events',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.history_rounded,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No historical events for today',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _openArticle(BuildContext context, String title, String contentUrl) {
    // Navigate to article detail page
    context.push('/article?title=${Uri.encodeComponent(title)}&url=${Uri.encodeComponent(contentUrl)}');
  }
}