import 'package:flutter/material.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Màn này sẽ dùng Hive/Local DB sau để lưu bài viết
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: const Center(
        child: Text('No saved articles yet'),
      ),
    );
  }
}
