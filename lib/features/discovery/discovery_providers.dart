import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../common/network/api_client.dart';
import 'discovery_models.dart' as dm;
import 'discovery_service.dart';

final _dioProvider = Provider<Dio>((ref) {
  final base = ApiClient().baseUrl;
  return Dio(BaseOptions(baseUrl: base));
});

final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final dio = ref.watch(_dioProvider);
  return DiscoveryService(dio);
});

final featuredContentProvider =
    FutureProvider.autoDispose<dm.FeaturedArticle?>((ref) async {
  final svc = ref.watch(discoveryServiceProvider);
  final data = await svc.getFeaturedContent();
  final tfa = data['tfa'];
  if (tfa is Map<String, dynamic>) {
    return dm.FeaturedArticle.fromTfaJson(tfa);
  }
  return null;
});

final onThisDayProvider =
    FutureProvider.autoDispose<List<dm.OnThisDayEvent>>((ref) async {
  final svc = ref.watch(discoveryServiceProvider);
  final data = await svc.getOnThisDayEvents();
  final events = (data['events'] as List?) ?? const [];
  return events
      .whereType<Map>()
      .map((e) =>
          dm.OnThisDayEvent.fromJson(Map<String, dynamic>.from(e as Map)))
      .take(3)
      .toList();
});

final randomArticleProvider =
    FutureProvider.autoDispose<dm.WikipediaPage?>((ref) async {
  final svc = ref.watch(discoveryServiceProvider);
  final data = await svc.getRandomArticle();
  return dm.WikipediaPage.fromSummaryJson(data);
});
