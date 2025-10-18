import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final _api = ApiClient();

  Timer? _debouncer;
  CancelToken? _activeToken;

  List<WikiArticle> _results = [];
  String _searchQuery = '';
  int _page = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  // Recent
  List<String> _recent = [];

  bool _featuredLoading = false;
  String? _featuredError;
  _FeaturedToday? _featured;
  bool get _isComposing => _controller.value.isComposingRangeValid;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadRecent();
    _loadFeatured();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _debouncer?.cancel();
    _activeToken?.cancel('dispose');
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final pref = await SharedPreferences.getInstance();
    _recent = pref.getStringList('recent_searches') ?? [];
  }

  Future<void> _pushRecent(String q) async {
    if (q.trim().isEmpty) return;
    final pref = await SharedPreferences.getInstance();
    final list = pref.getStringList('recent_searches') ?? [];
    list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    list.insert(0, q);
    while (list.length > 30) list.removeLast();
    await pref.setStringList('recent_searches', list);
    _recent = list;
  }

  Future<void> _submitQuery(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    _controller.text = trimmed;
    _searchQuery = trimmed;
    await _pushRecent(trimmed);
    await _search(reset: true);
  }

  void _onScroll() {
    final nearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;
    if (nearBottom && !_isLoading && _searchQuery.isNotEmpty && _hasMore) {
      _search();
    }
  }

  void _onSearchChanged(String query) {
    if (_isComposing) return;
    _debouncer?.cancel();
    _debouncer = Timer(const Duration(milliseconds: 300), () {
      final trimmed = query.trim();
      if (_searchQuery != trimmed) {
        _searchQuery = trimmed;
        _search(reset: true);
      }
    });
  }

  Future<void> _search({bool reset = false}) async {
    if (_searchQuery.isEmpty) {
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

    _activeToken?.cancel('new search');
    _activeToken = CancelToken();

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
      final newItems = await _fetchPage(_page, _activeToken!);
      if (!mounted) return;
      setState(() {
        if (newItems.length < 10) _hasMore = false;
        _results.addAll(newItems);
        _page++;
      });
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (!mounted) return;
      setState(() =>
          _error = 'Lỗi kết nối API: ${e.response?.statusCode ?? e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<WikiArticle>> _fetchPage(int page, CancelToken token) async {
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
    final data = await _api.get('/w/api.php',
        queryParameters: queryParams, cancelToken: token);
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
    final lang = _api.langCode;
    context.goNamed('article', queryParameters: {
      'title': title,
      'lang': lang,
    });
  }

  Future<void> _loadFeatured() async {
    setState(() {
      _featuredLoading = true;
      _featuredError = null;
    });
    try {
      final now = DateTime.now();
      final yyyy = now.year.toString().padLeft(4, '0');
      final mm = now.month.toString().padLeft(2, '0');
      final dd = now.day.toString().padLeft(2, '0');
      final data = await _api.get('/api/rest_v1/feed/featured/$yyyy/$mm/$dd');

      final tfa = _parseTFA(data);
      final mostRead = _parseMostRead(data);

      if (!mounted) return;
      setState(() {
        _featured = _FeaturedToday(tfa: tfa, mostRead: mostRead);
        _featuredLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _featuredLoading = false;
        _featuredError = 'Không tải được gợi ý hôm nay: $e';
      });
    }
  }

  _FeaturedItem? _parseTFA(dynamic data) {
    try {
      final tfa = data?['tfa'];
      if (tfa == null) return null;
      final title =
          (tfa['titles']?['normalized'] ?? tfa['title'])?.toString() ?? '';
      if (title.isEmpty) return null;
      final desc =
          (tfa['extract'] ?? tfa['description'] ?? '')?.toString() ?? '';
      final thumb = (tfa['thumbnail'] is Map)
          ? tfa['thumbnail']['source']?.toString()
          : null;
      return _FeaturedItem(title: title, description: desc, thumbnail: thumb);
    } catch (_) {
      return null;
    }
  }

  List<_FeaturedItem> _parseMostRead(dynamic data) {
    try {
      final arts = (data?['mostread']?['articles'] as List?) ?? const [];
      return arts
          .take(10)
          .map<_FeaturedItem>((a) {
            final title =
                (a['titles']?['normalized'] ?? a['title'])?.toString() ?? '';
            final desc =
                (a['extract'] ?? a['description'] ?? '')?.toString() ?? '';
            final thumb = (a['thumbnail'] is Map)
                ? a['thumbnail']['source']?.toString()
                : null;
            return _FeaturedItem(
                title: title, description: desc, thumbnail: thumb);
          })
          .where((e) => e.title.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wikipedia Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.explore_outlined),
            tooltip: 'Khám phá',
            onPressed: () => context.go('/discovery'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'Bài đã lưu',
            onPressed: () => context.go('/saved'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt',
            onPressed: () => context.go('/settings'),
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
                          _hasMore = true;
                          _error = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
              onSubmitted: _submitQuery,
            ),
          ),
          Expanded(child: _buildResultsOrFeatured()),
        ],
      ),
    );
  }

  Widget _buildResultsOrFeatured() {
    final nothingTyped = _results.isEmpty && _searchQuery.isEmpty;

    if (_isLoading && _results.isEmpty) return _buildSkeletonLoader();
    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (nothingTyped) {
      return _FeaturedHome(
        data: _featured,
        loading: _featuredLoading,
        error: _featuredError,
        onRetry: _loadFeatured,
        onOpenArticle: _navigateToArticle,
      );
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

class _FeaturedItem {
  final String title;
  final String description;
  final String? thumbnail;
  _FeaturedItem(
      {required this.title, required this.description, this.thumbnail});
}

class _FeaturedToday {
  final _FeaturedItem? tfa;
  final List<_FeaturedItem> mostRead;
  _FeaturedToday({this.tfa, required this.mostRead});
}

class _FeaturedHome extends StatelessWidget {
  final _FeaturedToday? data;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final void Function(String title) onOpenArticle;

  const _FeaturedHome({
    required this.data,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpenArticle,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (data == null) {
      return const Center(child: Text('Chưa có dữ liệu hôm nay.'));
    }

    final tfa = data!.tfa;
    final most = data!.mostRead;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        if (tfa != null) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text('Bài viết chọn lọc hôm nay',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          _FeaturedCard(item: tfa, onTap: () => onOpenArticle(tfa.title)),
          const SizedBox(height: 16),
        ],
        if (most.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text('Đọc nhiều nhất hôm nay',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          ...most.map((e) =>
              _FeaturedListTile(item: e, onTap: () => onOpenArticle(e.title))),
        ],
        if (tfa == null && most.isEmpty)
          const Center(child: Text('Không có gợi ý hiển thị.')),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final _FeaturedItem item;
  final VoidCallback onTap;
  const _FeaturedCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.thumbnail != null)
              CachedNetworkImage(
                imageUrl: item.thumbnail!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedListTile extends StatelessWidget {
  final _FeaturedItem item;
  final VoidCallback onTap;
  const _FeaturedListTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      onTap: onTap,
      leading: item.thumbnail != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: item.thumbnail!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          : const Icon(Icons.article_outlined),
      title:
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        item.description,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
