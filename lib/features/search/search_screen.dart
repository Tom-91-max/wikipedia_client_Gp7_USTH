import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../common/network/api_client.dart';
import '../../common/utils/debouncer.dart';
import '../../common/widgets/app_error.dart';
import '../../common/widgets/app_skeleton.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer();
  CancelToken? _cancelToken;

  bool _loading = false;
  String? _error;
  List<_SearchItem> _items = [];

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    _cancelToken?.cancel('dispose');
    super.dispose();
  }

  Future<void> _performSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = null;
        _items = [];
      });
      return;
    }
    _cancelToken?.cancel('new search');
    _cancelToken = CancelToken();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await ApiClient().searchTitle(q.trim());
      final data = res.data as Map<String, dynamic>?;

      // Action API shape: { query: { search: [ { title, snippet, ... }, ... ] } }
      final List results = data?['query']?['search'] ?? [];
      final parsed = results.map((e) => _SearchItem.fromActionApi(e)).toList();

      setState(() {
        _items = parsed;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _onChanged(String value) {
    _debouncer.run(() => _performSearch(value));
  }

  @override
  Widget build(BuildContext context) {
    final canSearch = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: false, // Hide back button on home screen
        actions: [
          IconButton(
            tooltip: 'Discovery',
            onPressed: () => context.go('/discovery'),
            icon: const Icon(Icons.explore_outlined),
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
      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search Wikipedia articles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                  onPressed: () {
                    _controller.clear();
                    _onChanged('');
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
              ),
            ),
          ),
          if (_loading)
            Expanded(
              child: ListView.builder(
                itemCount: 6,
                itemBuilder: (_, __) => const AppSkeleton(),
              ),
            )
          else if (_error != null)
            Expanded(
              child: AppError(
                message: _error!,
                onRetry: canSearch ? () => _performSearch(_controller.text) : null,
              ),
            )
          else
            Expanded(
              child: _items.isEmpty
                  ? const Center(
                child: Text('Type to search Wikipedia...'),
              )
                  : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final it = _items[index];
                  return ListTile(
                    leading: (it.thumbnailUrl != null)
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: it.thumbnailUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(Icons.article_outlined, size: 36),
                    title: Text(it.title),
                    subtitle: it.description == null
                        ? null
                        : Text(
                      it.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => context
                        .go('/article?title=${Uri.encodeComponent(it.title)}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchItem {
  final String title;
  final String? description;
  final String? thumbnailUrl;

  _SearchItem({required this.title, this.description, this.thumbnailUrl});

  /// Parser cho MediaWiki Action API (query.search[])
  factory _SearchItem.fromActionApi(Map<String, dynamic> json) {
    final title = json['title']?.toString() ?? '';
    // 'snippet' là HTML rút gọn; ở đây strip thô (bỏ tag) cho gọn
    final snippet = json['snippet']?.toString()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&');
    // Action API không trả thumb trực tiếp; ta để null (icon mặc định)
    return _SearchItem(title: title, description: snippet, thumbnailUrl: null);
  }

  @override
  String toString() => jsonEncode({'title': title, 'desc': description, 'thumb': thumbnailUrl});
}
