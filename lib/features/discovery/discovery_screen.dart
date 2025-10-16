// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
//
// class DiscoveryScreen extends StatelessWidget {
//   const DiscoveryScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final today = DateTime.now();
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Discovery'),
//         actions: [
//           IconButton(
//             onPressed: () => context.go('/search'),
//             icon: const Icon(Icons.search),
//           ),
//         ],
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           Text('Explore Wikipedia', style: Theme.of(context).textTheme.headlineSmall),
//           const SizedBox(height: 8),
//           Text(
//             'Featured feed, random articles, related topics…',
//             style: Theme.of(context).textTheme.bodyMedium,
//           ),
//           const SizedBox(height: 16),
//           Card(
//             child: ListTile(
//               leading: const Icon(Icons.today),
//               title: const Text('Today\'s featured'),
//               subtitle: Text('${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}'),
//               trailing: const Icon(Icons.chevron_right),
//               onTap: () {
//                 // Chỗ này bạn có thể cài feed/featured sau
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Implement featured feed later')),
//                 );
//               },
//             ),
//           ),
//           const SizedBox(height: 12),
//           Card(
//             child: ListTile(
//               leading: const Icon(Icons.shuffle),
//               title: const Text('Random article'),
//               trailing: const Icon(Icons.chevron_right),
//               onTap: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Implement random article later')),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }



// lib/features/discovery/discovery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// GHÉP CÁC SECTION ĐÃ VIẾT
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

          // 1) Featured of the day (từ API feed featured)
          Text(
            "Today's featured • ${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}",
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          const FeaturedSection(),
          const SizedBox(height: 16),

          // 2) Random article
          Text(
            'Discover something new',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          const RandomArticleSection(),
          const SizedBox(height: 16),

          // 3) On this day (events)
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
