import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DiscoveryService {
  final Dio _dio;

  DiscoveryService(this._dio);

  // Get current date components
  String get _currentYear {
    final now = DateTime.now();
    return now.year.toString();
  }

  String get _currentMonth {
    final now = DateTime.now();
    return now.month.toString().padLeft(2, '0');
  }

  String get _currentDay {
    final now = DateTime.now();
    return now.day.toString().padLeft(2, '0');
  }

  // Featured content API - get only one article
  Future<Map<String, dynamic>> getFeaturedContent() async {
    try {
      final response = await _dio.get(
        'https://api.wikimedia.org/feed/v1/wikipedia/en/featured/$_currentYear/$_currentMonth/$_currentDay',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load featured content: $e');
    }
  }

  // On this day API - updated endpoint
  Future<Map<String, dynamic>> getOnThisDayEvents() async {
    try {
      final response = await _dio.get(
        'https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/events/$_currentMonth/$_currentDay',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load on this day events: $e');
    }
  }

  // Most viewed articles API - use a working endpoint with recent data
  Future<Map<String, dynamic>> getMostViewedArticles() async {
    try {
      // Use a recent date that has data (e.g., last month)
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      final year = lastMonth.year.toString();
      final month = lastMonth.month.toString().padLeft(2, '0');

      final response = await _dio.get(
        'https://wikimedia.org/api/rest_v1/metrics/pageviews/top/en.wikipedia/all-access/$year/$month/all-days',
      );
      return response.data;
    } catch (e) {
      // Fallback to a known working date
      try {
        final response = await _dio.get(
          'https://wikimedia.org/api/rest_v1/metrics/pageviews/top/en.wikipedia/all-access/2024/10/all-days',
        );
        return response.data;
      } catch (fallbackError) {
        throw Exception('Failed to load most viewed articles: $e');
      }
    }
  }

  // Random article API - simplified endpoint
  Future<Map<String, dynamic>> getRandomArticle() async {
    try {
      final response = await _dio.get(
        'https://en.wikipedia.org/api/rest_v1/page/random/summary',
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to load random article: $e');
    }
  }
}

class FeaturedArticle {
  final String title;
  final String description;
  final String? thumbnailUrl;
  final String contentUrl;

  FeaturedArticle({
    required this.title,
    required this.description,
    this.thumbnailUrl,
    required this.contentUrl,
  });

  factory FeaturedArticle.fromJson(Map<String, dynamic> json) {
    return FeaturedArticle(
      title: json['titles']['normalized'] ?? json['title'] ?? 'No Title',
      description: json['description'] ?? 'No description available',
      thumbnailUrl: json['thumbnail']?['source'],
      contentUrl: json['content_urls']?['desktop']?['page'] ?? '',
    );
  }
}

class OnThisDayEvent {
  final String text;
  final List<WikipediaPage> pages;

  OnThisDayEvent({
    required this.text,
    required this.pages,
  });

  factory OnThisDayEvent.fromJson(Map<String, dynamic> json) {
    return OnThisDayEvent(
      text: json['text'] ?? '',
      pages: (json['pages'] as List<dynamic>?)
          ?.map((page) => WikipediaPage.fromJson(page))
          .toList() ?? [],
    );
  }
}

class WikipediaPage {
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String contentUrl;

  WikipediaPage({
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.contentUrl,
  });

  factory WikipediaPage.fromJson(Map<String, dynamic> json) {
    return WikipediaPage(
      title: json['titles']['normalized'] ?? json['title'] ?? 'No Title',
      description: json['description'],
      thumbnailUrl: json['thumbnail']?['source'],
      contentUrl: json['content_urls']?['desktop']?['page'] ?? '',
    );
  }
}

class MostViewedArticle {
  final String title;
  final int views;
  final int rank;

  MostViewedArticle({
    required this.title,
    required this.views,
    required this.rank,
  });

  factory MostViewedArticle.fromJson(Map<String, dynamic> json) {
    return MostViewedArticle(
      title: json['article'] ?? 'No Title',
      views: json['views'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }
}