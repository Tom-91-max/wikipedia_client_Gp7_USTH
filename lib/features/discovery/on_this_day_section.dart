import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'discovery_models.dart';
import 'discovery_providers.dart';

class OnThisDaySection extends ConsumerWidget {
  const OnThisDaySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(onThisDayProvider);
    return async.when(
      loading: () => const _Skeleton(),
      error: (e, _) => _ErrorTile(message: e.toString()),
      data: (events) => _buildEventsList(context, events),
    );
  }

  Widget _buildEventsList(BuildContext context, List<OnThisDayEvent> events) {
    return Column(
      children: events.map((e) => _buildEventCard(context, e)).toList(),
    );
  }

  Widget _buildEventCard(BuildContext context, OnThisDayEvent event) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${event.year}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 6),
            Text(event.text),
            if (event.pages.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildRelatedPages(context, event.pages),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedPages(BuildContext context, List<WikipediaPage> pages) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pages.map((page) {
        return ActionChip(
          label: Text(page.title, overflow: TextOverflow.ellipsis),
          onPressed: () => context.push(
            '/article?title=${Uri.encodeQueryComponent(page.title)}',
          ),
        );
      }).toList(),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _SkeletonCard(),
        SizedBox(height: 8),
        _SkeletonCard(),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const SizedBox(height: 120),
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
