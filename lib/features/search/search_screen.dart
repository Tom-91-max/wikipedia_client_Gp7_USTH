// import 'dart:convert';
//
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
//
// import '../../common/network/api_client.dart';
// import '../../common/utils/debouncer.dart';
// import '../../common/widgets/app_error.dart';
// import '../../common/widgets/app_skeleton.dart';
//
// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});
//
//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }
//
// class _SearchScreenState extends State<SearchScreen> {
//   final _controller = TextEditingController();
//   final _debouncer = Debouncer();
//   CancelToken? _cancelToken;
//
//   bool _loading = false;
//   String? _error;
//   List<_SearchItem> _items = [];
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _debouncer.dispose();
//     _cancelToken?.cancel('dispose');
//     super.dispose();
//   }
//
//   Future<void> _performSearch(String q) async {
//     if (q.trim().isEmpty) {
//       setState(() {
//         _loading = false;
//         _error = null;
//         _items = [];
//       });
//       return;
//     }
//     _cancelToken?.cancel('new search');
//     _cancelToken = CancelToken();
//
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//
//     try {
//       final res = await ApiClient().searchTitle(q.trim());
//       final data = res.data as Map<String, dynamic>?;
//
//       // Action API shape: { query: { search: [ { title, snippet, ... }, ... ] } }
//       final List results = data?['query']?['search'] ?? [];
//       final parsed = results.map((e) => _SearchItem.fromActionApi(e)).toList();
//
//       setState(() {
//         _items = parsed;
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Search failed: $e';
//       });
//     } finally {
//       if (mounted) {
//         setState(() {
//           _loading = false;
//         });
//       }
//     }
//   }
//
//   void _onChanged(String value) {
//     _debouncer.run(() => _performSearch(value));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final canSearch = _controller.text.trim().isNotEmpty;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Search'),
//         automaticallyImplyLeading: false, // Hide back button on home screen
//         actions: [
//           IconButton(
//             tooltip: 'Discovery',
//             onPressed: () => context.go('/discovery'),
//             icon: const Icon(Icons.explore_outlined),
//           ),
//           IconButton(
//             tooltip: 'Saved',
//             onPressed: () => context.go('/saved'),
//             icon: const Icon(Icons.bookmark_border),
//           ),
//           IconButton(
//             tooltip: 'Settings',
//             onPressed: () => context.go('/settings'),
//             icon: const Icon(Icons.settings_outlined),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding:
//             const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
//             child: TextField(
//               controller: _controller,
//               onChanged: _onChanged,
//               textInputAction: TextInputAction.search,
//               decoration: InputDecoration(
//                 hintText: 'Search Wikipedia articles...',
//                 prefixIcon: const Icon(Icons.search),
//                 suffixIcon: _controller.text.isEmpty
//                     ? null
//                     : IconButton(
//                   onPressed: () {
//                     _controller.clear();
//                     _onChanged('');
//                   },
//                   icon: const Icon(Icons.clear),
//                 ),
//                 border: const OutlineInputBorder(
//                   borderRadius: BorderRadius.all(Radius.circular(16)),
//                 ),
//               ),
//             ),
//           ),
//           if (_loading)
//             Expanded(
//               child: ListView.builder(
//                 itemCount: 6,
//                 itemBuilder: (_, __) => const AppSkeleton(),
//               ),
//             )
//           else if (_error != null)
//             Expanded(
//               child: AppError(
//                 message: _error!,
//                 onRetry: canSearch ? () => _performSearch(_controller.text) : null,
//               ),
//             )
//           else
//             Expanded(
//               child: _items.isEmpty
//                   ? const Center(
//                 child: Text('Type to search Wikipedia...'),
//               )
//                   : ListView.separated(
//                 itemCount: _items.length,
//                 separatorBuilder: (_, __) => const Divider(height: 1),
//                 itemBuilder: (context, index) {
//                   final it = _items[index];
//                   return ListTile(
//                     leading: (it.thumbnailUrl != null)
//                         ? ClipRRect(
//                       borderRadius: BorderRadius.circular(8),
//                       child: CachedNetworkImage(
//                         imageUrl: it.thumbnailUrl!,
//                         width: 56,
//                         height: 56,
//                         fit: BoxFit.cover,
//                       ),
//                     )
//                         : const Icon(Icons.article_outlined, size: 36),
//                     title: Text(it.title),
//                     subtitle: it.description == null
//                         ? null
//                         : Text(
//                       it.description!,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     onTap: () => context
//                         .go('/article?title=${Uri.encodeComponent(it.title)}'),
//                   );
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// class _SearchItem {
//   final String title;
//   final String? description;
//   final String? thumbnailUrl;
//
//   _SearchItem({required this.title, this.description, this.thumbnailUrl});
//
//   /// Parser cho MediaWiki Action API (query.search[])
//   factory _SearchItem.fromActionApi(Map<String, dynamic> json) {
//     final title = json['title']?.toString() ?? '';
//     // 'snippet' là HTML rút gọn; ở đây strip thô (bỏ tag) cho gọn
//     final snippet = json['snippet']?.toString()
//         .replaceAll(RegExp(r'<[^>]*>'), '')
//         .replaceAll('&quot;', '"')
//         .replaceAll('&amp;', '&');
//     // Action API không trả thumb trực tiếp; ta để null (icon mặc định)
//     return _SearchItem(title: title, description: snippet, thumbnailUrl: null);
//   }
//
//   @override
//   String toString() => jsonEncode({'title': title, 'desc': description, 'thumb': thumbnailUrl});
// }
//
//
//
//
//
//


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
  final _scrollController = ScrollController();
  CancelToken? _cancelToken;

  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  static const _pageSize = 20;
  String _query = '';
  int _offset = 0;
  bool _hasMore = false;
  List<_SearchItem> _items = [];

  List<String> get _quickSuggestions =>
      _items.map((e) => e.title).take(6).toList();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    _scrollController.dispose();
    _cancelToken?.cancel('dispose');
    super.dispose();
  }

  void _onScroll() {
    if (_loadingMore || _loading || _error != null || !_hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 240) {
      _fetchPage(append: true);
    }
  }

  Future<void> _startNewSearch(String q) async {
    final trimmed = q.trim();
    _query = trimmed;
    _cancelToken?.cancel('new search');
    _cancelToken = CancelToken();

    if (trimmed.isEmpty) {
      setState(() {
        _loading = false;
        _items.clear();
        _error = null;
        _hasMore = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _offset = 0;
      _items.clear();
    });

    await _fetchPage(append: false);
  }

  Future<void> _fetchPage({required bool append}) async {
    try {
      final res = await ApiClient().searchTitleRest(
        _query,
        limit: _pageSize,
        offset: append ? _offset : 0,
        cancelToken: _cancelToken,
      );

      final data = res.data as Map<String, dynamic>?;
      final List pages = (data?['pages'] as List?) ?? const [];
      final parsed = pages.map((e) => _SearchItem.fromRestTitle(e)).toList();

      setState(() {
        if (append) {
          _items.addAll(parsed);
        } else {
          _items = parsed;
        }
        _hasMore = parsed.length >= _pageSize;
        _offset = (append ? _offset : 0) + parsed.length;
      });
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) return;
      setState(() => _error = 'Search failed: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onChanged(String value) => _debouncer.run(() => _startNewSearch(value));
  Future<void> _onRefresh() async => _startNewSearch(_controller.text);

  @override
  Widget build(BuildContext context) {
    final canSearch = _controller.text.trim().isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        automaticallyImplyLeading: false,
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
              onSubmitted: (v) => _startNewSearch(v),
            ),
          ),
          if (_quickSuggestions.isNotEmpty && !_loading)
            SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _quickSuggestions.length,
                itemBuilder: (_, i) {
                  final s = _quickSuggestions[i];
                  return ActionChip(
                    label: Text(s, overflow: TextOverflow.ellipsis),
                    onPressed: () {
                      _controller.text = s;
                      _controller.selection =
                          TextSelection.collapsed(offset: s.length);
                      _startNewSearch(s);
                    },
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                onRetry: canSearch ? () => _startNewSearch(_controller.text) : null,
              ),
            )
          else
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Type to search Wikipedia...'))
                  : RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.separated(
                  controller: _scrollController,
                  itemCount: _items.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (_hasMore && index == _items.length) {
                      if (!_loadingMore) {
                        _loadingMore = true;
                        WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _fetchPage(append: true));
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final it = _items[index];
                    return ListTile(
                      leading: it.thumbnailUrl != null
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
                      subtitle: it.description != null
                          ? Text(it.description!,
                          maxLines: 2, overflow: TextOverflow.ellipsis)
                          : (it.excerpt != null
                          ? Text(it.excerpt!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis)
                          : null),
                      onTap: () => context.go(
                        '/article?title=${Uri.encodeComponent(it.title)}',
                      ),
                    );
                  },
                ),
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
  final String? excerpt;
  final String? thumbnailUrl;

  _SearchItem({
    required this.title,
    this.description,
    this.excerpt,
    this.thumbnailUrl,
  });

  factory _SearchItem.fromRestTitle(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['key'] ?? '').toString();
    final description = json['description']?.toString();
    final excerpt = (json['excerpt']?.toString() ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    String? thumb;
    final thumbMap = json['thumbnail'] as Map<String, dynamic>?;
    if (thumbMap != null) thumb = thumbMap['url']?.toString();
    return _SearchItem(
      title: title,
      description: description,
      excerpt: excerpt.isEmpty ? null : excerpt,
      thumbnailUrl: thumb,
    );
  }

  @override
  String toString() => jsonEncode({
    'title': title,
    'desc': description,
    'excerpt': excerpt,
    'thumb': thumbnailUrl,
  });
}
