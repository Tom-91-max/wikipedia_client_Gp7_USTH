import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../common/network/api_client.dart';
import '../../common/providers/language_provider.dart';
import '../../common/providers/tts_provider.dart';
import '../../common/services/tts_service.dart';
import '../../common/widgets/app_error.dart';
import '../../common/widgets/app_skeleton.dart';

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

  @override
  void initState() {
    super.initState();

    // API mới: dùng WebViewController + WebViewWidget, KHÔNG cần WebView.platform/AndroidWebView
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

    _loadArticle();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final res = await ApiClient().getSummary(widget.title);
      if (mounted) {
        setState(() {
          _articleSummary = res.data?['extract']?.toString();
        });
      }
    } catch (e) {
      // Ignore summary loading errors
    }
  }

  Future<void> _loadArticle() async {
    if (widget.title.isEmpty) {
      if (!mounted) return;
      setState(() => _error = 'Missing title.');
      return;
    }

    final language = ref.read(languageProvider);
    final url =
        'https://$language.m.wikipedia.org/api/rest_v1/page/mobile-html/${Uri.encodeComponent(widget.title)}';

    try {
      await _controller.loadRequest(
        Uri.parse(url),
        headers: const {
          'User-Agent': 'USTH-Group7-WikiClient/1.0 (contact@usth.edu.vn)',
        },
      );
      if (!mounted) return;
      // _loading sẽ được tắt trong onPageFinished; không cần setState ở đây
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load: $e');
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
          if (_articleSummary != null)
            IconButton(
              icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
              onPressed: () => _handleTTS(context, ref),
              tooltip: isPlaying ? 'Stop reading' : 'Read aloud',
            ),
        ],
      ),
      body: _error != null
          ? AppError(message: _error!, onRetry: _loadArticle)
          : Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Positioned.fill(
              child: AppSkeleton(height: double.infinity),
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
      // Get language from settings for TTS
      final language = ref.read(languageProvider);
      await TTSService().setLanguage(_getTTSLanguageCode(language));
      
      // Clean up HTML tags and read the summary
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
    // Map Wikipedia language codes to TTS language codes
    switch (wikiLanguage) {
      case 'en': return 'en-US';
      case 'vi': return 'vi-VN';
      case 'fr': return 'fr-FR';
      case 'ja': return 'ja-JP';
      case 'de': return 'de-DE';
      case 'es': return 'es-ES';
      case 'it': return 'it-IT';
      case 'pt': return 'pt-PT';
      case 'ru': return 'ru-RU';
      case 'zh': return 'zh-CN';
      case 'ko': return 'ko-KR';
      case 'ar': return 'ar-SA';
      case 'hi': return 'hi-IN';
      case 'th': return 'th-TH';
      case 'nl': return 'nl-NL';
      case 'sv': return 'sv-SE';
      case 'no': return 'no-NO';
      case 'da': return 'da-DK';
      case 'fi': return 'fi-FI';
      case 'pl': return 'pl-PL';
      default: return 'en-US';
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
