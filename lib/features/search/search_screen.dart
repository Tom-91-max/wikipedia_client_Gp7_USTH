// lib/features/search/search_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../common/network/api_client.dart';

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
      thumbnailUrl:
          (json['thumbnail'] is Map ? json['thumbnail']['source'] : null)
              ?.toString(),
    );
  }
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debouncer;
  final _api = ApiClient();

  List<WikiArticle> _results = [];
  String _searchQuery = '';
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  // Fix rớt dấu khi gõ TV: bỏ xử lý khi IME còn composing
  bool get _isComposing => _controller.value.isComposingRangeValid;

  @override
  void initState() {
    super.initState();
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

  void _onSearchChanged(String query) {
    if (_isComposing) return; // đang gõ dấu -> đợi chốt
    _debouncer?.cancel();
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
        if (newItems.length < 10) _hasMore = false; // page size = 10
        _results.addAll(newItems);
        _page++;
      });
    } on DioException catch (e) {
      setState(() =>
          _error = 'Lỗi kết nối API: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<WikiArticle>> _fetchPage(int page) async {
    const size = 10;
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
    final data = await _api.get('/w/api.php', queryParameters: queryParams);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Lỗi định dạng dữ liệu API');
    }
    final pages = data['query']?['pages'];
    if (pages == null) return [];
    final List pagesList = (pages as Map).values.toList()
      ..sort((a, b) => (a['index'] ?? 0).compareTo(b['index'] ?? 0));
    return pagesList.map<WikiArticle>((p) => WikiArticle.fromJson(p)).toList();
  }

  void _navigateToArticle(String title) {
    context.goNamed('article', queryParameters: {'title': title});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wikipedia Search'),
        actions: [
          // 🔎 Discovery
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'Khám phá',
            onPressed: () => context.go('/discovery'),
          ),
          // ⚙️ Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () => context.go('/settings'),
          ),
          // 🔖 Saved (xem bài đã lưu)
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Bài đã lưu',
            onPressed: () => context.go('/saved'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                        _controller.value = const TextEditingValue(
                          text: '',
                          selection: TextSelection.collapsed(offset: 0),
                          composing: TextRange.empty,
                        );
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
              onSubmitted: (_) => _search(reset: true),
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

    // Trang chủ: KHÔNG hiển thị History/Saved preview
    if (_results.isEmpty && _searchQuery.isEmpty) {
      return const Center(child: Text('Bắt đầu tìm kiếm Wikipedia.'));
    }

    if (_results.isEmpty && _searchQuery.isNotEmpty) {
      return const Center(child: Text('Không tìm thấy kết quả nào.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _results.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _results.length) {
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
