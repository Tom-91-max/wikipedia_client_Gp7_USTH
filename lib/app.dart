// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'common/theme/app_theme.dart';
import 'common/providers/theme_provider.dart';
import 'common/providers/app_language_provider.dart';

import 'features/search/search_screen.dart';
import 'features/article/article_screen.dart';
import 'features/discovery/discovery_screen.dart';
import 'features/saved/saved_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/history/history_screen.dart';
import 'l10n/app_localizations.dart';

/// Name/path of the route
class RouteNames {
  static const search = 'search';
  static const article = 'article';
  static const discovery = 'discovery';
  static const saved = 'saved';
  static const history = 'history';
  static const settings = 'settings';
}

class RoutePaths {
  static const search = '/search';
  static const article = '/article';
  static const discovery = '/discovery';
  static const saved = '/saved';
  static const history = '/history';
  static const settings = '/settings';

  /// Helper to build URL for an article (pass title, optional lang)
  static String articleWithTitle(String title, {String? lang}) {
    final t = Uri.encodeQueryComponent(title);
    final l = (lang == null || lang.isEmpty)
        ? ''
        : '&lang=${Uri.encodeQueryComponent(lang)}';
    return '$article?title=$t$l';
  }
}

/// Standard GoRouter configuration (with errorBuilder
final _router = GoRouter(
  initialLocation: RoutePaths.search,
  routes: [
    GoRoute(
      path: RoutePaths.search,
      name: RouteNames.search,
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: RoutePaths.article,
      name: RouteNames.article,
      builder: (context, state) {
        final title = state.uri.queryParameters['title'];
        final lang = state.uri.queryParameters['lang'];
        if (title == null || title.trim().isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Article')),
            body: const Center(child: Text('Missing article title')),
          );
        }
        return ArticleScreen(title: title, langOverride: lang);
      },
    ),
    GoRoute(
      path: RoutePaths.discovery,
      name: RouteNames.discovery,
      builder: (context, state) => const DiscoveryScreen(),
    ),
    GoRoute(
      path: RoutePaths.saved,
      name: RouteNames.saved,
      builder: (context, state) => const SavedScreen(),
    ),
    GoRoute(
      path: RoutePaths.history,
      name: RouteNames.history,
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: RoutePaths.settings,
      name: RouteNames.settings,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
  errorBuilder: (context, state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route not found')),
      body: Center(
        child: Text(
          state.error?.toString() ?? 'Unknown route',
          textAlign: TextAlign.center,
        ),
      ),
    );
  },
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(appLanguageProvider);

    return MaterialApp.router(
      title: 'Wikipedia Client',
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('vi', ''),
      ],
    );
  }
}
