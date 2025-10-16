import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'discovery_service.dart';

// Service provider
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final dio = Dio();
  dio.options.headers['User-Agent'] = 'USTH-Group7-WikiClient/1.0 (contact@usth.edu.vn)';
  // Add timeout and better error handling
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 10);
  return DiscoveryService(dio);
});

// Featured content provider - get only one featured article
final featuredContentProvider = FutureProvider.autoDispose<FeaturedArticle?>((ref) async {
  final discoveryService = ref.watch(discoveryServiceProvider);
  try {
    final data = await discoveryService.getFeaturedContent();
    final featuredArticle = data['tfa'] as Map<String, dynamic>?; // tfa = today's featured article

    if (featuredArticle != null) {
      return FeaturedArticle.fromJson(featuredArticle);
    }
    return null;
  } catch (e) {
    throw Exception('Failed to load featured content');
  }
});

// Most viewed provider - returns raw JSON data instead of specific class
final mostViewedProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final discoveryService = ref.watch(discoveryServiceProvider);
  try {
    final data = await discoveryService.getMostViewedArticles();
    final items = data['items'] as List<dynamic>?;

    if (items != null && items.isNotEmpty) {
      final articles = items[0]['articles'] as List<dynamic>?;
      if (articles != null && articles.isNotEmpty) {
        return articles.take(5).map((article) => article as Map<String, dynamic>).toList();
      }
    }
    // Return empty list if no real data available
    return [];
  } catch (e) {
    // Return empty list on error
    return [];
  }
});

// On this day provider - updated structure
final onThisDayProvider = FutureProvider.autoDispose<List<OnThisDayEvent>>((ref) async {
  final discoveryService = ref.watch(discoveryServiceProvider);
  try {
    final data = await discoveryService.getOnThisDayEvents();
    final events = data['events'] as List<dynamic>?;

    if (events != null) {
      return events.take(3).map((event) => OnThisDayEvent.fromJson(event)).toList();
    }
    return [];
  } catch (e) {
    throw Exception('Failed to load on this day events');
  }
});

final randomArticleProvider = FutureProvider.autoDispose<WikipediaPage?>((ref) async {
  final discoveryService = ref.watch(discoveryServiceProvider);
  try {
    final data = await discoveryService.getRandomArticle();
    return WikipediaPage(
      title: data['title'] ?? 'No Title',
      description: data['description'] ?? data['extract'],
      thumbnailUrl: data['thumbnail']?['source'],
      contentUrl: data['content_urls']?['desktop']?['page'] ?? '',
    );
  } catch (e) {
    throw Exception('Failed to load random article');
  }
});