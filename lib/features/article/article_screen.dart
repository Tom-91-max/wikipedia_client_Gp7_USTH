import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../common/network/api_client.dart';
import '../../common/widgets/app_error.dart';
import '../../common/widgets/app_skeleton.dart';

class ArticleScreen extends StatefulWidget {
  final String title;
  const ArticleScreen({super.key, required this.title});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

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
  }

  Future<void> _loadArticle() async {
    if (widget.title.isEmpty) {
      if (!mounted) return;
      setState(() => _error = 'Missing title.');
      return;
    }

    final url =
        'https://en.m.wikipedia.org/api/rest_v1/page/mobile-html/${Uri.encodeComponent(widget.title)}';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
          context.canPop() ? context.pop() : context.go('/search'),
        ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final res = await ApiClient().getSummary(widget.title);
            if (!mounted) return; // đảm bảo context còn sống sau await
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
