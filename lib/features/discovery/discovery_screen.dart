// lib/features/discovery/discovery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'featured_section.dart';
import 'random_article_section.dart';
import 'on_this_day_section.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => context.go('/search'),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Saved',
            onPressed: () => context.go('/saved'),
            icon: const Icon(Icons.bookmark_border),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Explore Wikipedia',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Featured feed, random articles, related topics…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Featured of the day
          Text(
            "Today's featured • ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}",
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          const FeaturedSection(),
          const SizedBox(height: 16),

          // Random article
          Text(
            'Discover something new',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          const RandomArticleSection(),
          const SizedBox(height: 16),

          // On this day (events)
          Text(
            'On this day',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          const OnThisDaySection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
