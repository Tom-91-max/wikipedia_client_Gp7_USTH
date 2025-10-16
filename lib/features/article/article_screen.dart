import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../common/network/api_client.dart';
import '../../common/providers/language_provider.dart';
import '../../common/providers/tts_provider.dart';
import '../../common/services/tts_service.dart';
import '../../common/widgets/app_error.dart';
import '../../common/widgets/app_skeleton.dart';

/// Tên box (trùng với main.dart – nếu bạn đổi ở main.dart thì giữ đồng bộ ở đây)
class _HiveBoxes {
  static const articles = 'articles_box'; // lưu html + savedOffline + cachedAt
  static const history = 'history_box'; // ghi lịch sử đọc
  static const cache = 'cache_meta_box'; // dự phòng TTL/etag
}

/// Khoá lưu trữ: tách theo ngôn ngữ + title để tránh đè
String _articleKey(String lang, String title) =>
    'article:$lang:${title.toLowerCase()}';

/// TTL cache mặc định
const Duration _defaultTtl = Duration(hours: 24);

class ArticleScreen extends ConsumerStatefulWidget {
  final String title;
  const ArticleScreen({super.key, required this.title});

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  String? _articleSummary;

  // trạng thái offline
  bool _fromOffline = false;
  bool _savedOffline = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
            _addHistoryEntry(); // ghi lịch sử sau khi render
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
    await _loadSavedFlag(); // biết có đang saved không
    await Future.wait([
      _loadSummary(),
      _loadArticleSmart(), // ưu tiên offline rồi refresh online
    ]);
  }

  /// Đọc cờ savedOffline từ Hive
  Future<void> _loadSavedFlag() async {
    final lang = ref.read(languageProvider);
    final box = Hive.box(_HiveBoxes.articles);
    final key = _articleKey(lang, widget.title);
    final rec = box.get(key);
    if (!mounted) return;
    setState(() => _savedOffline = (rec?['savedOffline'] == true));
  }

  /// Lấy summary để đọc TTS
  Future<void> _loadSummary() async {
    try {
      final res = await ApiClient().getSummary(widget.title);
      if (mounted) {
        setState(() {
          _articleSummary = res.data?['extract']?.toString();
        });
      }
    } catch (_) {
      // bỏ qua lỗi summary
    }
  }

  /// Chiến lược tải:
  /// 1) Nếu có offline => loadHtmlString trước (mở nhanh)
  /// 2) Nếu cache hết hạn hoặc chưa có => gọi online và cập nhật
  Future<void> _loadArticleSmart() async {
    if (widget.title.isEmpty) {
      if (!mounted) return;
      setState(() => _error = 'Missing title.');
      return;
    }

    final lang = ref.read(languageProvider);
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
        // render bản offline trước
        await _controller.loadHtmlString(html,
            baseUrl: 'https://$lang.m.wikipedia.org');
        if (mounted) setState(() => _loading = false);
      }

      // nếu cache cũ, làm mới nền
      if (!isFresh) {
        _refreshFromNetwork(lang, replaceView: !_fromOffline);
      }
    } else {
      // không có offline => tải trực tiếp online
      _refreshFromNetwork(lang, replaceView: true);
    }
  }

  /// Gọi REST mobile-html để lấy HTML thô và:
  /// - render (nếu cần)
  /// - lưu vào Hive (cache)
  Future<void> _refreshFromNetwork(String lang,
      {required bool replaceView}) async {
    final url =
        'https://$lang.m.wikipedia.org/api/rest_v1/page/mobile-html/${Uri.encodeComponent(widget.title)}';
    try {
      final dio = Dio(BaseOptions(
        headers: const {
          'User-Agent': 'USTH-Group7-WikiClient/1.0 (contact@usth.edu.vn)',
        },
        responseType: ResponseType.plain, // nhận HTML string
      ));

      final res = await dio.get<String>(url);
      final html = res.data ?? '';

      // cập nhật view nếu đang xem bản rỗng/online
      if (replaceView) {
        await _controller.loadHtmlString(html,
            baseUrl: 'https://$lang.m.wikipedia.org');
        if (mounted) {
          setState(() {
            _fromOffline = false;
            _loading = false;
            _error = null;
          });
        }
      }

      // lưu cache (không mặc định đánh dấu savedOffline)
      final box = Hive.box(_HiveBoxes.articles);
      final key = _articleKey(lang, widget.title);
      final prev = box.get(key) as Map?;
      await box.put(key, {
        'title': widget.title,
        'html': html,
        'summary': _articleSummary,
        'savedOffline': prev?['savedOffline'] == true, // giữ trạng thái lưu
        'cachedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (!mounted) return;
      if (!_fromOffline) {
        setState(() => _error = 'Failed to load: $e');
      }
    }
  }

  /// Toggle lưu offline: nếu chưa lưu -> fetch HTML mới nhất & mark savedOffline = true
  Future<void> _toggleSaveOffline() async {
    final lang = ref.read(languageProvider);
    final box = Hive.box(_HiveBoxes.articles);
    final key = _articleKey(lang, widget.title);
    final rec = (box.get(key) as Map?) ?? {};

    if (_savedOffline) {
      // Gỡ lưu: giữ cache nhưng savedOffline=false
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

    // Lưu: đảm bảo có HTML
    String? html = rec['html'] as String?;
    if (html == null || html.isEmpty) {
      // fetch ngay để chắc chắn lưu được
      final url =
          'https://$lang.m.wikipedia.org/api/rest_v1/page/mobile-html/${Uri.encodeComponent(widget.title)}';
      try {
        final dio = Dio(BaseOptions(
          headers: const {
            'User-Agent': 'USTH-Group7-WikiClient/1.0 (contact@usth.edu.vn)',
          },
          responseType: ResponseType.plain,
        ));
        final res = await dio.get<String>(url);
        html = res.data ?? '';
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

  /// Thêm entry History: {articleId(title), openedAt}
  Future<void> _addHistoryEntry() async {
    try {
      final lang = ref.read(languageProvider);
      final key = _articleKey(lang, widget.title);
      final box = Hive.box(_HiveBoxes.history);

      // Để đơn giản: push một record JSON; SavedScreen/HistoryScreen sẽ đọc và group theo ngày
      await box.add({
        'key': key,
        'title': widget.title,
        'lang': lang,
        'openedAt': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title.isEmpty ? 'Article' : widget.title;
    final isPlaying = ref.watch(ttsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _handleBackPress(context),
          tooltip: 'Back',
        ),
        actions: [
          // Lưu/Gỡ lưu offline
          IconButton(
            tooltip: _savedOffline ? 'Remove offline' : 'Save offline',
            icon: Icon(_savedOffline ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSaveOffline,
          ),
          if (_articleSummary != null)
            IconButton(
              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
              onPressed: () => _handleTTS(context, ref),
              tooltip: isPlaying ? 'Stop reading' : 'Read aloud',
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
                    child: AppSkeleton(height: double.infinity),
                  ),
                if (_fromOffline)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _OfflineBanner(onRefresh: () async {
                      final lang = ref.read(languageProvider);
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
      final language = ref.read(languageProvider);
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
}

/// Banner hiển thị khi đang xem bản offline
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
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
