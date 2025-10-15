import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:dio/dio.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;
import 'package:cached_network_image/cached_network_image.dart'; 

import '../../common/network/api_client.dart';
import '../../common/widgets/app_error.dart';
import '../../common/widgets/app_skeleton.dart';
import 'extras_section.dart'; 

class ArticleScreen extends StatefulWidget {
  final String title;
  const ArticleScreen({super.key, required this.title});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;
  List<_Section> _toc = []; 
  String? _webHtml;
  Map<String, GlobalKey> _sectionKeys = {}; 
  ScrollController _contentScrollController = ScrollController(); 

  // Thêm cho N4: Media và Related
  List<dynamic> _mediaItems = [];
  List<dynamic> _relatedArticles = [];
  bool _loadingMedia = true;
  bool _loadingRelated = true;
  String? _mediaError;
  String? _relatedError;

  bool _showN4Section = false;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (!mounted) return;
              setState(() => _loading = false);
            },
            onWebResourceError: (err) {
              if (!mounted) return;
              setState(() => _error = 'Web error: ${err.description}');
            },
          ),
        );
    }

    // Load TOC, Article, và thêm Media + Related 
    Future.wait([_loadTOC(), _loadArticle(), _loadMedia(), _loadRelated()]);
  }

  @override
  void dispose() {
    _contentScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArticle() async {
    if (widget.title.isEmpty) {
      if (!mounted) return;
      setState(() => _error = 'Missing title.');
      return;
    }

    try {
      if (!kIsWeb) {
        final data = await ApiClient().getMobileHtml(widget.title);
        final String html = data['html']!;
        final String baseUrl = data['baseUrl']!;
        if (html.isEmpty) throw 'No HTML data';

        await _controller!.loadHtmlString(html, baseUrl: baseUrl);
      } else {
        final res = await ApiClient().getArticleHtml(widget.title);
        final parse = res.data['parse'] as Map<String, dynamic>?;
        if (parse == null) throw 'No parse data';

        final html = parse['text']['*'] as String?;
        final sections = parse['sections'] as List<dynamic>? ?? [];

        final parsedToc = sections
            .where((s) => (s['toclevel'] as int?) == 1)
            .map((s) => _Section(
                  id: int.tryParse((s['index'] ?? '').toString()) ?? 0,
                  title: s['line'] as String? ?? '',
                  anchor: s['anchor'] as String? ?? '',
                ))
            .toList();

        if (!mounted) return;
        setState(() {
          _toc = parsedToc;
          _sectionKeys = {for (var s in _toc) s.anchor: GlobalKey()};
          _webHtml = html;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadTOC() async {
    if (kIsWeb) return; 

    try {
      final res = await ApiClient().getSections(widget.title);
      final data = res.data as Map<String, dynamic>?;
      final sections = (data?['parse']?['sections'] as List<dynamic>?) ?? [];

      final parsedToc = sections
          .where((s) => (s['toclevel'] as int?) == 1)
          .map((s) => _Section(
                id: int.tryParse((s['index'] ?? '').toString()) ?? 0,
                title: s['line'] as String? ?? '',
                anchor: s['anchor'] as String? ?? '',
              ))
          .toList();

      if (!mounted) return;
      setState(() => _toc = parsedToc);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load TOC: $e')),
      );
    }
  }

  // Thêm cho N4: Load Media List
  Future<void> _loadMedia() async {
    try {
      final res = await ApiClient().getMediaList(widget.title);
      final items = res.data['items'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _mediaItems = items;
        _loadingMedia = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mediaError = 'Failed to load media: $e';
        _loadingMedia = false;
      });
    }
  }

  // Thêm  N4: Load Related Articles
  Future<void> _loadRelated() async {
    try {
      final res = await ApiClient().getRelated(widget.title);
      final pages = res.data['pages'] as List<dynamic>? ?? [];
      if (!mounted) return;
      setState(() {
        _relatedArticles = pages;
        _loadingRelated = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _relatedError = 'Failed to load related: $e';
        _loadingRelated = false;
      });
    }
  }

  // Thêm  N4: Refresh all 
  Future<void> _refreshAll() async {
    setState(() {
      _loading = true;
      _loadingMedia = true;
      _loadingRelated = true;
      _error = null;
      _mediaError = null;
      _relatedError = null;
    });
    await Future.wait([_loadArticle(), _loadMedia(), _loadRelated()]);
  }

  void _shareArticle() {
    final url = 'https://en.wikipedia.org/wiki/${Uri.encodeComponent(widget.title)}';
    Share.share('Check out this Wikipedia article: $url', subject: widget.title);
  }

  void _onHtmlLinkTap(String? url, Map<String, String> attributes, dom.Element? element) {
    if (url == null) return;
    if (url.startsWith('#')) {
      final anchor = url.substring(1);
      _scrollToSection(anchor);
    } else {
      launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    }
  }

  void _scrollToSection(String anchor) {
    if (kIsWeb) {
      final key = _sectionKeys[anchor];
      if (key != null && key.currentContext != null) {
        final renderBox = key.currentContext!.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final offset = renderBox.localToGlobal(Offset.zero).dy;
          final position = _contentScrollController.offset + offset - 100; 
          _contentScrollController.animateTo(
            position,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          print('RenderBox not found for anchor: $anchor');
        }
      } else {
        print('Key not found for anchor: $anchor');
      }
    } else {
      _controller!.runJavaScript(
        "var element = document.getElementById('$anchor');"
        "if (element) { element.scrollIntoView({behavior: 'smooth', block: 'start'}); } else { console.log('Anchor not found'); }",
      ).then((_) => print('JS executed')).catchError((err) => print('JS error: $err'));
    }
  }


void _showTocBottomSheet() {
  if (_toc.isEmpty) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent, 
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)), 
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true, 
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -2), 
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Table of Contents',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _toc.length,
                itemBuilder: (context, index) {
                  final section = _toc[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    elevation: 1, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Colors.white.withOpacity(0.95), 
                    child: InkWell( 
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        _scrollToSection(section.anchor);
                        Navigator.pop(context);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    section.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600, 
                                      letterSpacing: 0.2, 
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 1,
                                    color: Colors.grey.shade200,
                                    width: double.infinity,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildTocSidebar() {
    return Container(
      width: 250,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListView.builder(
        itemCount: _toc.length,
        itemBuilder: (context, index) {
          final section = _toc[index];
          return ListTile(
            title: Text(section.title, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Divider(height: 1), 
            onTap: () {
              _scrollToSection(section.anchor);
            },
          );
        },
      ),
    );
  }

  // Callback forrrrrrr onTap innerr RelatedArticles
  void _onArticleTap(String title) {
    context.go('/article?title=${Uri.encodeComponent(title)}');
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title.isEmpty ? 'Article' : widget.title;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/search'),
        ),
        actions: [
          if (!kIsWeb && _toc.isNotEmpty) 
            IconButton(
              icon: const Icon(Icons.list),
              tooltip: 'Table of Contents',
              onPressed: _showTocBottomSheet, 
            ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: _shareArticle,
          ),
          IconButton(
            icon: Icon(_showN4Section ? Icons.expand_less : Icons.expand_more),
            tooltip: 'Show/Hide Extras',
            onPressed: () {
              setState(() {
                _showN4Section = !_showN4Section;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator( // Pull-to-Refresh 
        onRefresh: _refreshAll,
        child: _error != null
            ? AppError(message: _error!, onRetry: _loadArticle)
            : kIsWeb
                ? Row( 
                    children: [
                      if (_toc.isNotEmpty) 
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                          ),
                          child: _buildTocSidebar(),
                        ),
                      Expanded(
                        child: Stack(
                          children: [
                            if (_webHtml != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: SingleChildScrollView(
                                  controller: _contentScrollController, 
                                  child: Column( 
                                    children: [
                                      Html(
                                        data: _webHtml!,
                                        onLinkTap: _onHtmlLinkTap,
                                        extensions: [
                                          MwHeadlineExtension(sectionKeys: _sectionKeys),
                                        ],
                                      ),
                                      if (_showN4Section) ...[
                                        const Divider(),
                                        MediaGallery(
                                          mediaItems: _mediaItems,
                                          loadingMedia: _loadingMedia,
                                          mediaError: _mediaError,
                                          onRetry: _loadMedia,
                                        ),
                                        const Divider(),
                                        RelatedArticles(
                                          relatedArticles: _relatedArticles,
                                          loadingRelated: _loadingRelated,
                                          relatedError: _relatedError,
                                          onArticleTap: _onArticleTap,
                                          onRetry: _loadRelated,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            if (_loading)
                              const Positioned.fill(
                                child: AppSkeleton(height: double.infinity),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Stack( // Mobile
                    children: [
                      SingleChildScrollView( 
                        child: Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,  
                              child: WebViewWidget(controller: _controller!),
                            ),
                            if (_showN4Section) ...[
                              MediaGallery(
                                mediaItems: _mediaItems,
                                loadingMedia: _loadingMedia,
                                mediaError: _mediaError,
                                onRetry: _loadMedia,
                              ),
                              RelatedArticles(
                                relatedArticles: _relatedArticles,
                                loadingRelated: _loadingRelated,
                                relatedError: _relatedError,
                                onArticleTap: _onArticleTap,
                                onRetry: _loadRelated,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_loading)
                        const Positioned.fill(
                          child: AppSkeleton(height: double.infinity),
                        ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final res = await ApiClient().getSummary(widget.title);
            if (!mounted) return;
            final extract = res.data?['extract'] ?? 'No summary';
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Summary: ${widget.title}'),
                content: Text(extract.toString()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Summary error: $e')),
            );
          }
        },
        label: const Text('Summary'),
        icon: const Icon(Icons.info_outline),
      ),
    );
  }
}

class _Section {
  final int id;
  final String title;
  final String anchor;

  _Section({required this.id, required this.title, required this.anchor});
}

class MwHeadlineExtension extends HtmlExtension {
  final Map<String, GlobalKey> sectionKeys;

  MwHeadlineExtension({required this.sectionKeys});

  @override
  Set<String> get supportedTags => {}; 

  @override
  bool matches(ExtensionContext context) {
    return context.element?.classes.contains('mw-headline') ?? false;
  }

  @override
  InlineSpan build(ExtensionContext context) {
    final id = context.element?.id;
    if (id != null && sectionKeys.containsKey(id)) {
      return WidgetSpan(
        child: Container(
          key: sectionKeys[id],
          child: Text(context.element?.text ?? ''),
        ),
      );
    }
    return TextSpan(text: context.element?.text ?? '');
  }
}