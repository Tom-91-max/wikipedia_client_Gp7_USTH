import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/app_back_button_handler.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Màn này sẽ dùng Hive/Local DB sau để lưu bài viết
    return AppBackButtonHandler(
      fallbackRoute: '/search',
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Saved'),
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
      body: const Center(
        child: Text('No saved articles yet'),
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
