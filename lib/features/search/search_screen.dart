// import 'dart:convert';
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
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
//   final _scrollController = ScrollController();
//   CancelToken? _cancelToken;
//
//   bool _loading = false;
//   bool _loadingMore = false;
//   String? _error;
//   static const _pageSize = 20;
//   String _query = '';
//   int _offset = 0;
//   bool _hasMore = false;
//   List<_SearchItem> _items = [];
//
//   List<String> get _quickSuggestions =>
//       _items.map((e) => e.title).take(6).toList();
//
//   @override
//   void initState() {
//     super.initState();
//     _scrollController.addListener(_onScroll);
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _debouncer.dispose();
//     _scrollController.dispose();
//     _cancelToken?.cancel('dispose');
//     super.dispose();
//   }
//
//   void _onScroll() {
//     if (_loadingMore || _loading || _error != null || !_hasMore) return;
//     if (_scrollController.position.pixels >=
//         _scrollController.position.maxScrollExtent - 240) {
//       _fetchPage(append: true);
//     }
//   }
//
//   Future<void> _startNewSearch(String q) async {
//     final trimmed = q.trim();
//     _query = trimmed;
//     _cancelToken?.cancel('new search');
//     _cancelToken = CancelToken();
//
//     if (trimmed.isEmpty) {
//       setState(() {
//         _loading = false;
//         _items.clear();
//         _error = null;
//         _hasMore = false;
//       });
//       return;
//     }
//
//     setState(() {
//       _loading = true;
//       _error = null;
//       _offset = 0;
//       _items.clear();
//     });
//
//     await _fetchPage(append: false);
//   }
//
//   Future<void> _fetchPage({required bool append}) async {
//     try {
//       final res = await ApiClient().searchTitleRest(
//         _query,
//         limit: _pageSize,
//         offset: append ? _offset : 0,
//         cancelToken: _cancelToken,
//       );
//
//       final data = res.data as Map<String, dynamic>?;
//       final List pages = (data?['pages'] as List?) ?? const [];
//       final parsed = pages.map((e) => _SearchItem.fromRestTitle(e)).toList();
//
//       setState(() {
//         if (append) {
//           _items.addAll(parsed);
//         } else {
//           _items = parsed;
//         }
//         _hasMore = parsed.length >= _pageSize;
//         _offset = (append ? _offset : 0) + parsed.length;
//       });
//     } catch (e) {
//       if (e is DioException && CancelToken.isCancel(e)) return;
//       setState(() => _error = 'Search failed: $e');
//     } finally {
//       if (!mounted) return;
//       setState(() {
//         _loading = false;
//         _loadingMore = false;
//       });
//     }
//   }
//
//   void _onChanged(String value) => _debouncer.run(() => _startNewSearch(value));
//   Future<void> _onRefresh() async => _startNewSearch(_controller.text);
//
//   @override
//   Widget build(BuildContext context) {
//     final canSearch = _controller.text.trim().isNotEmpty;
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Search'),
//         automaticallyImplyLeading: false,
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
//               onSubmitted: (v) => _startNewSearch(v),
//             ),
//           ),
//           if (_quickSuggestions.isNotEmpty && !_loading)
//             SizedBox(
//               height: 42,
//               child: ListView.separated(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 scrollDirection: Axis.horizontal,
//                 itemCount: _quickSuggestions.length,
//                 itemBuilder: (_, i) {
//                   final s = _quickSuggestions[i];
//                   return ActionChip(
//                     label: Text(s, overflow: TextOverflow.ellipsis),
//                     onPressed: () {
//                       _controller.text = s;
//                       _controller.selection =
//                           TextSelection.collapsed(offset: s.length);
//                       _startNewSearch(s);
//                     },
//                   );
//                 },
//                 separatorBuilder: (_, __) => const SizedBox(width: 8),
//               ),
//             ),
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
//                 onRetry: canSearch ? () => _startNewSearch(_controller.text) : null,
//               ),
//             )
//           else
//             Expanded(
//               child: _items.isEmpty
//                   ? const Center(child: Text('Type to search Wikipedia...'))
//                   : RefreshIndicator(
//                 onRefresh: _onRefresh,
//                 child: ListView.separated(
//                   controller: _scrollController,
//                   itemCount: _items.length + (_hasMore ? 1 : 0),
//                   separatorBuilder: (_, __) => const Divider(height: 1),
//                   itemBuilder: (context, index) {
//                     if (_hasMore && index == _items.length) {
//                       if (!_loadingMore) {
//                         _loadingMore = true;
//                         WidgetsBinding.instance.addPostFrameCallback(
//                                 (_) => _fetchPage(append: true));
//                       }
//                       return const Padding(
//                         padding: EdgeInsets.symmetric(vertical: 16),
//                         child: Center(child: CircularProgressIndicator()),
//                       );
//                     }
//
//                     final it = _items[index];
//                     return ListTile(
//                       leading: it.thumbnailUrl != null
//                           ? ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: CachedNetworkImage(
//                           imageUrl: it.thumbnailUrl!,
//                           width: 56,
//                           height: 56,
//                           fit: BoxFit.cover,
//                         ),
//                       )
//                           : const Icon(Icons.article_outlined, size: 36),
//                       title: Text(it.title),
//                       subtitle: it.description != null
//                           ? Text(it.description!,
//                           maxLines: 2, overflow: TextOverflow.ellipsis)
//                           : (it.excerpt != null
//                           ? Text(it.excerpt!,
//                           maxLines: 2,
//                           overflow: TextOverflow.ellipsis)
//                           : null),
//                       onTap: () => context.go(
//                         '/article?title=${Uri.encodeComponent(it.title)}',
//                       ),
//                     );
//                   },
//                 ),
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
//   final String? excerpt;
//   final String? thumbnailUrl;
//
//   _SearchItem({
//     required this.title,
//     this.description,
//     this.excerpt,
//     this.thumbnailUrl,
//   });
//
//   factory _SearchItem.fromRestTitle(Map<String, dynamic> json) {
//     final title = (json['title'] ?? json['key'] ?? '').toString();
//     final description = json['description']?.toString();
//     final excerpt = (json['excerpt']?.toString() ?? '')
//         .replaceAll(RegExp(r'<[^>]*>'), '')
//         .trim();
//     String? thumb;
//     final thumbMap = json['thumbnail'] as Map<String, dynamic>?;
//     if (thumbMap != null) thumb = thumbMap['url']?.toString();
//     return _SearchItem(
//       title: title,
//       description: description,
//       excerpt: excerpt.isEmpty ? null : excerpt,
//       thumbnailUrl: thumb,
//     );
//   }
//
//   @override
//   String toString() => jsonEncode({
//     'title': title,
//     'desc': description,
//     'excerpt': excerpt,
//     'thumb': thumbnailUrl,
//   });
// }

// lib/features/search/search_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // để bắt DioException khi gọi qua ApiClient
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import tương đối theo cấu trúc nhóm bạn
import '../../common/network/api_client.dart';

// --- 1. MODEL DỮ LIỆU ---
class WikiArticle {
  final String title;
  final String description;
  final String? thumbnailUrl;

  WikiArticle({
    required this.title,
    required this.description,
    this.thumbnailUrl,
  });

  factory WikiArticle.fromJson(Map<String, dynamic> json) {
    return WikiArticle(
      title: json['title']?.toString() ?? '',
      description: json['extract']?.toString() ?? '',
      thumbnailUrl: (json['thumbnail'] is Map
          ? json['thumbnail']['source']
          : null)
          ?.toString(),
    );
  }
}

// --- 2. SEARCH SCREEN ---
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Trạng thái & scroll
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debouncer;

  final _api = ApiClient(); // dùng ApiClient chuẩn

  List<WikiArticle> _results = [];
  String _searchQuery = '';
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Infinite scroll
    _scrollController.addListener(() {
      final nearBottom = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200;
      if (nearBottom && !_isLoading && _searchQuery.isNotEmpty && _hasMore) {
        _search();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _debouncer?.cancel();
    super.dispose();
  }

  // --- 3. LOGIC TÌM KIẾM (DEBOUNCE & PHÂN TRANG) ---
  void _onSearchChanged(String query) {
    if (_debouncer?.isActive ?? false) _debouncer!.cancel();
    _debouncer = Timer(const Duration(milliseconds: 300), () {
      if (_searchQuery.trim() != query.trim()) {
        _searchQuery = query.trim();
        _search(reset: true);
      }
    });
  }

  Future<void> _search({bool reset = false}) async {
    if (_searchQuery.trim().isEmpty) {
      if (reset) {
        setState(() {
          _results = [];
          _page = 0;
          _hasMore = true;
          _error = null;
        });
      }
      return;
    }
    if (_isLoading || (!reset && !_hasMore)) return;

    setState(() {
      _isLoading = true;
      if (reset) {
        _results = [];
        _page = 0;
        _hasMore = true;
        _error = null;
      }
    });

    try {
      final newItems = await _fetchPage(_page);
      setState(() {
        if (newItems.length < 10) _hasMore = false; // size=10
        _results.addAll(newItems);
        _page++;
      });
    } on DioException catch (e) {
      setState(() {
        _error = 'Lỗi kết nối API: ${e.response?.statusCode ?? e.message}';
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<WikiArticle>> _fetchPage(int page) async {
    const int size = 10;

    final queryParams = {
      'action': 'query',
      'format': 'json',
      'origin': '*',
      'generator': 'search',
      'gsrsearch': _searchQuery,
      'gsrlimit': size.toString(),
      'gsroffset': (page * size).toString(),
      'prop': 'pageimages|extracts',
      'piprop': 'thumbnail',
      'pithumbsize': '120',
      'exintro': '1',
      'explaintext': '1',
      'exsentences': '2',
      'redirects': '1',
    };

    // Gọi qua ApiClient (đã set baseUrl + User-Agent)
    final data = await _api.get('/w/api.php', queryParameters: queryParams);

    if (data is Map<String, dynamic>) {
      final pages = data['query']?['pages'];
      if (pages == null) return [];
      final List pagesList = (pages as Map).values.toList();

      // sắp xếp theo index để đúng thứ tự
      pagesList.sort(
            (a, b) => (a['index'] ?? 0).compareTo(b['index'] ?? 0),
      );

      return pagesList
          .map<WikiArticle>((p) => WikiArticle.fromJson(p))
          .toList();
    }
    throw const FormatException('Lỗi định dạng dữ liệu API');
  }

  // Routing tới màn article
  void _navigateToArticle(String title) {
    context.goNamed(
      'article', // Tên route N1 đã định nghĩa trong app.dart
      queryParameters: {'title': title},
    );
  }

  // --- 4. UI ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wikipedia Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Nhập từ khoá...',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading && _results.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Làm mới',
                      onPressed: () => _search(reset: true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Xóa',
                      onPressed: () {
                        _controller.clear();
                        _onSearchChanged('');
                        setState(() {
                          _results = [];
                          _searchQuery = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading && _results.isEmpty) return _buildSkeletonLoader();
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_results.isEmpty && _searchQuery.isNotEmpty) {
      return const Center(child: Text('Không tìm thấy kết quả nào.'));
    }
    if (_results.isEmpty && _searchQuery.isEmpty) {
      return const Center(child: Text('Bắt đầu tìm kiếm Wikipedia.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _results.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          // footer load/hết
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Đã tải hết kết quả.'),
            ),
          );
        }

        final item = _results[index];
        return _buildListItem(item);
      },
    );
  }

  Widget _buildListItem(WikiArticle item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: () => _navigateToArticle(item.title),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.0),
                  child: CachedNetworkImage(
                    imageUrl: item.thumbnailUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                    ),
                    errorWidget: (context, url, error) => const SizedBox(
                      width: 80,
                      height: 80,
                      child: Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description.replaceAll(RegExp(r'<[^>]*>'), ''),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Skeleton (Shimmer)
  Widget _buildSkeletonLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Container(
            height: 96,
            width: double.infinity,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
