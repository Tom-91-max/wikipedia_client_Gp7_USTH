// lib/features/discovery/discovery_models.dart
class WikipediaPage {
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? contentUrl;

  WikipediaPage({
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.contentUrl,
  });

  /// From the random/summary API
  factory WikipediaPage.fromSummaryJson(Map<String, dynamic> json) {
    return WikipediaPage(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? json['extract'])?.toString(),
      thumbnailUrl: (json['thumbnail']?['source'])?.toString(),
      contentUrl: (json['content_urls']?['desktop']?['page'])?.toString(),
    );
  }

  factory WikipediaPage.fromFeedJson(Map<String, dynamic> json) {
    final titles = json['titles'];
    final title =
        (titles?['normalized'] ?? titles?['display'] ?? json['title'] ?? '')
            .toString();
    final thumb =
        (json['thumbnail']?['source'] ?? json['thumbnail']?['url'])?.toString();
    final url = (json['content_urls']?['desktop']?['page'] ??
            json['content_urls']?['mobile']?['page'])
        ?.toString();

    return WikipediaPage(
      title: title,
      description: (json['description'] ?? json['extract'])?.toString(),
      thumbnailUrl: thumb,
      contentUrl: url,
    );
  }
}

class FeaturedArticle {
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? contentUrl;

  FeaturedArticle({
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.contentUrl,
  });

  /// Today's featured article
  factory FeaturedArticle.fromTfaJson(Map<String, dynamic> json) {
    return FeaturedArticle(
      title: (json['title'] ?? '').toString(),
      description: (json['extract'] ?? json['description'])?.toString(),
      thumbnailUrl: (json['thumbnail']?['source'])?.toString(),
      contentUrl: (json['content_urls']?['desktop']?['page'])?.toString(),
    );
  }
}

class OnThisDayEvent {
  final int year;
  final String text;
  final List<WikipediaPage> pages;

  OnThisDayEvent({
    required this.year,
    required this.text,
    required this.pages,
  });

  factory OnThisDayEvent.fromJson(Map<String, dynamic> json) {
    final pagesJson = (json['pages'] as List? ?? const [])
        .whereType<Map>()
        .map((e) =>
            WikipediaPage.fromFeedJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    return OnThisDayEvent(
      year: int.tryParse(json['year']?.toString() ?? '') ?? 0,
      text: (json['text'] ?? '').toString(),
      pages: pagesJson,
    );
  }
}
