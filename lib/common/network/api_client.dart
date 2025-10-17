import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart'; 

class ApiClient {
  static final ApiClient _i = ApiClient._internal();
  factory ApiClient() => _i;

  ApiClient._internal() {
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Api-User-Agent': _userAgent,  // Sử dụng Api-User-Agent để bypass browser restriction
    };

    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://en.wikipedia.org',
        connectTimeout: const Duration(seconds: 200), 
        receiveTimeout: const Duration(seconds: 150),
        headers: headers,
      ),
    );

    final cacheOptions = CacheOptions(
      store: MemCacheStore(), 
      policy: CachePolicy.refreshForceCache, 
      hitCacheOnErrorExcept: [401, 403],
      maxStale: const Duration(hours: 1),
    );
    _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Api-User-Agent'] = _userAgent;
          if (kIsWeb) {
            options.headers.remove('User-Agent');  
          } else {
            options.headers['User-Agent'] = _userAgent;  
          }
          return handler.next(options);
        },
        onError: (e, handler) {
          return handler.next(e);
        },
      ),
    );
  }

  static const String _userAgent =
      'USTH-Group7-WikiClient/1.0 (contact@usth.edu.vn)';

  late Dio _dio;
  Dio get dio => _dio;

  /// SEARCH (ổn định): MediaWiki Action API
  /// https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=...&format=json&srlimit=10
  Future<Response<dynamic>> searchTitle(String query) {
    return _dio.get(
      '/w/api.php',
      queryParameters: {
        'action': 'query',
        'list': 'search',
        'srsearch': query,
        'srlimit': 10,
        'format': 'json',
        if (kIsWeb) 'origin': '*', 
      },
    );
  }

  Future<Response<dynamic>> getSummary(String title) {
    return _dio.get(
      '/api/rest_v1/page/summary/$title',
      queryParameters: kIsWeb ? {'origin': '*'} : null, 
    );
  }

  // chơi lớn: test trên web nên dùng api riêng :)))))))
  Future<Response<dynamic>> getArticleHtml(String title) {
    return _dio.get(
      '/w/api.php',
      queryParameters: {
        'action': 'parse',
        'page': title,
        'format': 'json',
        'prop': 'text|sections',
        if (kIsWeb) 'origin': '*',
      },
    );
  }

  Future<Response<dynamic>> getSections(String title) {
    return _dio.get(
      '/w/api.php',
      queryParameters: {
        'action': 'parse',
        'page': title,
        'format': 'json',
        'prop': 'sections',
        if (kIsWeb) 'origin': '*',
      },
    );
  }

  // API cho điện thoại
  Future<Map<String, String>> getMobileHtml(String title) async {
    final apiUrl = 'https://en.m.wikipedia.org/api/rest_v1/page/mobile-html/${Uri.encodeComponent(title)}';
    final res = await _dio.get<String>(
      apiUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final html = res.data ?? '';
    final baseUrl = 'https://en.m.wikipedia.org/wiki/${Uri.encodeComponent(title)}';
    return {'html': html, 'baseUrl': baseUrl};
  }

  Future<Response<dynamic>> getMediaList(String title) {
    return _dio.get(
      '/api/rest_v1/page/media-list/${Uri.encodeComponent(title)}',
      queryParameters: kIsWeb ? {'origin': '*'} : null,
    );
  }

  Future<Response<dynamic>> getRelated(String title) {
    return _dio.get(
      '/api/rest_v1/page/related/${Uri.encodeComponent(title)}',
      queryParameters: kIsWeb ? {'origin': '*'} : null,
    );
  }
}