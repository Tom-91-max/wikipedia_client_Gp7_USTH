import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/app_back_button_handler.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return AppBackButtonHandler(
      fallbackRoute: '/search',
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Discovery'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Explore Wikipedia', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Featured feed, random articles, related topics…',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Today\'s featured'),
              subtitle: Text('${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Chỗ này bạn có thể cài feed/featured sau
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Implement featured feed later')),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text('Random article'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Implement random article later')),
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _handleBackPress(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/search');
    }
  }
}
