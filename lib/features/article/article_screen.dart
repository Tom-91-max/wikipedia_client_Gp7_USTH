import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/network/api_client.dart';
import '../../common/providers/language_provider.dart';
import '../../common/providers/tts_provider.dart';
import '../../common/services/tts_service.dart';
import '../../common/widgets/app_error.dart';
import '../../common/widgets/app_skeleton.dart';

class _HiveBoxes {
  static const articles = 'articles_box';
  static const history = 'history_box';
  static const cache = 'cache_meta_box';
}

String _articleKey(String lang, String title) =>
    'article:$lang:${title.toLowerCase()}';

const Duration _defaultTtl = Duration(hours: 24);

class ArticleScreen extends ConsumerStatefulWidget {
  final String title;
  final String? langOverride;
  const ArticleScreen({super.key, required this.title, this.langOverride});

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  String? _articleSummary;

  bool _fromOffline = false;
  bool _savedOffline = false;

  List<Map<String, dynamic>> _sections = [];
  bool get _hasTOC => _sections.isNotEmpty;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            if (!mounted) return;
            setState(() => _loading = false);
            await _injectHelperJs();
            _addHistoryEntry();
          },
          onWebResourceError: (err) {
            if (!mounted) return;
            setState(() => _error = 'Web error: ${err.description}');
          },
        ),
      );

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadSavedFlag();
    await Future.wait([
      _loadSummary(),
      _loadArticleSmart(),
      _loadSections(),
    ]);
  }

  Future<void> _loadSavedFlag() async {
    final String lang = (widget.langOverride ?? ref.read(languageProvider));
    final box = Hive.box(_HiveBoxes.articles);
    final key = _articleKey(lang, widget.title);
    final rec = box.get(key);
    if (!mounted) return;
    setState(() => _savedOffline = (rec?['savedOffline'] == true));
  }

  Future<void> _loadSummary() async {
    try {
      final res = await ApiClient().getSummary(widget.title);
      if (mounted) {
        setState(() {
          _articleSummary = res.data?['extract']?.toString();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadSections() async {
    try {
      final sections = await ApiClient().getSections(widget.title);
      if (!mounted) return;
      setState(() {
        _sections = sections;
      });
    } catch (_) {}
  }

  Future<void> _loadArticleSmart() async {
    if (widget.title.isEmpty) {
      if (!mounted) return;
      setState(() => _error = 'Missing title.');
      return;
    }

    final String lang = (widget.langOverride ?? ref.read(languageProvider));
    final box = Hive.box(_HiveBoxes.articles);
    final key = _articleKey(lang, widget.title);
    final rec = box.get(key);

    final now = DateTime.now();

    if (rec != null) {
      final html = rec['html'] as String?;
      final cachedAtString = rec['cachedAt'] as String?;
      final cachedAt =
          cachedAtString != null ? DateTime.tryParse(cachedAtString) : null;
      final isFresh =
          cachedAt != null ? now.difference(cachedAt) < _defaultTtl : false;

      if (html != null && html.isNotEmpty) {
        _fromOffline = true;
        await _controller.loadHtmlString(
          _wrapHtml(html, lang: lang),
          baseUrl: 'https://$lang.wikipedia.org',
        );
        if (mounted) setState(() => _loading = false);
      }

      if (!isFresh) {
        _refreshFromNetwork(lang, replaceView: !_fromOffline);
      }
    } else {
      _refreshFromNetwork(lang, replaceView: true);
    }
  }

  Future<void> _refreshFromNetwork(String lang,
      {required bool replaceView}) async {
    try {
      final html = await ApiClient().getParsedHtml(widget.title);

      if (replaceView) {
        await _controller.loadHtmlString(
          _wrapHtml(html, lang: lang),
          baseUrl: 'https://$lang.wikipedia.org',
        );
        if (mounted) {
          setState(() {
            _fromOffline = false;
            _loading = false;
            _error = null;
          });
        }
      }

      final box = Hive.box(_HiveBoxes.articles);
      final key = _articleKey(lang, widget.title);
      final prev = box.get(key) as Map?;
      await box.put(key, {
        'title': widget.title,
        'html': html,
        'summary': _articleSummary,
        'savedOffline': prev?['savedOffline'] == true,
        'cachedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (!mounted) return;
      if (!_fromOffline) {
        setState(() => _error = 'Failed to load: $e');
      }
    }
  }

  Future<void> _toggleSaveOffline() async {
    final String lang = (widget.langOverride ?? ref.read(languageProvider));
    final box = Hive.box(_HiveBoxes.articles);
    final key = _articleKey(lang, widget.title);
    final rec = (box.get(key) as Map?) ?? {};

    if (_savedOffline) {
      await box.put(key, {
        ...rec,
        'savedOffline': false,
      });
      if (!mounted) return;
      setState(() => _savedOffline = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from Offline')),
        );
      }
      return;
    }

    String? html = rec['html'] as String?;
    if (html == null || html.isEmpty) {
      try {
        html = await ApiClient().getParsedHtml(widget.title);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Save failed: $e')),
          );
        }
        return;
      }
    }

    await box.put(key, {
      'title': widget.title,
      'html': html,
      'summary': _articleSummary,
      'savedOffline': true,
      'cachedAt': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    setState(() => _savedOffline = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved for Offline')),
    );
  }

  Future<void> _addHistoryEntry() async {
    try {
      final String lang = (widget.langOverride ?? ref.read(languageProvider));
      final key = _articleKey(lang, widget.title);
      final box = Hive.box(_HiveBoxes.history);

      await box.add({
        'key': key,
        'title': widget.title,
        'lang': lang,
        'openedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title.isEmpty ? 'Article' : widget.title;
    final isPlaying =
        ref.watch(ttsProvider); // giữ nguyên, nhưng KHÔNG dùng nữa
    final String lang = (widget.langOverride ?? ref.watch(languageProvider));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackPress(context),
        ),
        actions: [
          IconButton(
            tooltip: _savedOffline ? 'Remove offline' : 'Save offline',
            icon: Icon(_savedOffline ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSaveOffline,
          ),
          if (_hasTOC)
            IconButton(
              tooltip: 'Table of contents',
              icon: const Icon(Icons.list),
              onPressed: _showTocSheet,
            ),
          IconButton(
            tooltip: 'Share link',
            icon: const Icon(Icons.share),
            onPressed: () => _shareArticle(lang),
          ),
        ],
      ),
      body: _error != null
          ? AppError(message: _error!, onRetry: _bootstrap)
          : Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading)
                  const Positioned.fill(
                      child: AppSkeleton(height: double.infinity)),
                if (_fromOffline)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _OfflineBanner(onRefresh: () async {
                      await _refreshFromNetwork(lang, replaceView: true);
                    }),
                  ),
              ],
            ),
      floatingActionButton: _articleSummary != null
          ? FloatingActionButton.extended(
              onPressed: () => _showSummaryDialog(context),
              label: const Text('Summary'),
              icon: const Icon(Icons.info_outline),
            )
          : null,
    );
  }

  void _handleBackPress(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/search');
    }
  }

  Future<void> _handleTTS(BuildContext context, WidgetRef ref) async {
    if (_articleSummary == null) return;

    final ttsNotifier = ref.read(ttsProvider.notifier);

    if (ttsNotifier.isPlaying) {
      await ttsNotifier.stop();
    } else {
      final String language =
          (widget.langOverride ?? ref.read(languageProvider));
      await TTSService().setLanguage(_getTTSLanguageCode(language));

      final cleanText = _articleSummary!
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&quot;', '"')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>');

      await ttsNotifier.speak('${widget.title}. $cleanText');
    }
  }

  String _getTTSLanguageCode(String wikiLanguage) {
    switch (wikiLanguage) {
      case 'en':
        return 'en-US';
      case 'vi':
        return 'vi-VN';
      case 'fr':
        return 'fr-FR';
      case 'ja':
        return 'ja-JP';
      case 'de':
        return 'de-DE';
      case 'es':
        return 'es-ES';
      case 'it':
        return 'it-IT';
      case 'pt':
        return 'pt-PT';
      case 'ru':
        return 'ru-RU';
      case 'zh':
        return 'zh-CN';
      case 'ko':
        return 'ko-KR';
      case 'ar':
        return 'ar-SA';
      case 'hi':
        return 'hi-IN';
      case 'th':
        return 'th-TH';
      case 'nl':
        return 'nl-NL';
      case 'sv':
        return 'sv-SE';
      case 'no':
        return 'no-NO';
      case 'da':
        return 'da-DK';
      case 'fi':
        return 'fi-FI';
      case 'pl':
        return 'pl-PL';
      default:
        return 'en-US';
    }
  }

  void _showSummaryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Summary: ${widget.title}'),
        content: SingleChildScrollView(
          child: Text(_articleSummary ?? 'No summary available'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTocSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
                  'Table of contents',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _sections.length,
                  itemBuilder: (_, i) {
                    final s = _sections[i];
                    final title = (s['line'] ?? '').toString();
                    final anchor = (s['anchor'] ?? '').toString();
                    final level = (s['toclevel'] ?? 1) as int;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.only(
                        left: 16.0 + (level - 1) * 16.0,
                        right: 16,
                      ),
                      title: Text(title),
                      onTap: () {
                        Navigator.pop(context);
                        _scrollToAnchor(anchor);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _scrollToAnchor(String anchor) async {
    final js = """
      (function() {
        var id = "$anchor";
        var el = document.getElementById(id);
        if (!el) {
          var candidates = document.getElementsByClassName('mw-headline');
          for (var i = 0; i < candidates.length; i++) {
            if (candidates[i].id === id) { el = candidates[i]; break; }
          }
        }
        if (el && el.scrollIntoView) { el.scrollIntoView({behavior: 'smooth', block: 'start'}); return true; }
        return false;
      })();
    """;
    try {
      await _controller.runJavaScriptReturningResult(js);
    } catch (_) {}
  }

  Future<void> _injectHelperJs() async {
    const js = """
      try {
        var style = document.createElement('style');
        style.innerHTML = `
          body { padding: 12px !important; }
          figure, table { max-width: 100%; overflow-x: auto; }
          img { height: auto; max-width: 100%; }
          @media (prefers-color-scheme: dark) {
            body { background: #121212; color: #e0e0e0; }
            a { color: #8ab4f8; }
          }
        `;
        document.head.appendChild(style);
      } catch (e) {}
    """;
    try {
      await _controller.runJavaScript(js);
    } catch (_) {}
  }

  Future<void> _shareArticle(String lang) async {
    final url = ApiClient().buildArticleUrl(widget.title, lang: lang);
    await Share.share(url, subject: widget.title);
  }

  String _wrapHtml(String rawHtml, {required String lang}) {
    return """
<!doctype html>
<html lang="$lang">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${htmlEscape.convert(widget.title)}</title>
<style>
  body { font-family: -apple-system, Roboto, "Helvetica Neue", Arial, "Noto Sans", "Liberation Sans", sans-serif; line-height: 1.5; }
  img { max-width: 100%; height: auto; }
  table { width: 100%; border-collapse: collapse; }
  .infobox, .thumb, .navbox { max-width: 100%; overflow-x: auto; }
</style>
</head>
<body>
$rawHtml
</body>
</html>
""";
  }
}

class _OfflineBanner extends StatelessWidget {
  final VoidCallback onRefresh;
  const _OfflineBanner({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.75),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onRefresh,
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off, size: 18, color: Colors.white),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'You are viewing an offline copy. Tap to refresh.',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
