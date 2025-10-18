// lib/common/network/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  // Singleton
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _createDio();
  }

  late Dio _dio;

  // Wikipedia language (synchronized with languageProvider)
  String _langCode = 'en';
  String get langCode => _langCode;
  String get baseUrl => 'https://$_langCode.wikipedia.org';

  static const String _userAgent =
      'USTH-Group7-WikiClient/1.0 (contact@usth.edu.vn)';

  void _createDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  /// Called from languageProvider when the user changes language (vi, en, fr, …)
  Future<void> updateLanguage(String languageCode) async {
    if (languageCode.isEmpty || languageCode == _langCode) return;
    _langCode = languageCode;
    _createDio();
  }

  String _enc(String title) => Uri.encodeComponent(title);

  /// Article URL for opening in browser / sharing
  String buildArticleUrl(String title, {String? lang}) {
    final l = (lang == null || lang.isEmpty) ? _langCode : lang;
    return 'https://$l.wikipedia.org/wiki/${Uri.encodeComponent(title)}';
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final res = await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
    if (res.statusCode != 200) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'HTTP ${res.statusCode}',
        type: DioExceptionType.badResponse,
      );
    }
    return res.data;
  }

  /// REST search/title (supports thumbnail + pagination)
  Future<Response<dynamic>> searchTitleRest(
    String query, {
    int limit = 20,
    int offset = 0,
    CancelToken? cancelToken,
  }) {
    return _dio.get(
      '/w/rest.php/v1/search/title',
      queryParameters: {
        'q': query,
        'limit': limit,
        'offset': offset,
      },
      cancelToken: cancelToken,
    );
  }

  /// Action API (generator=search)
  Future<Map<String, dynamic>> searchRaw({
    required String query,
    required int limit,
    required int offset,
    CancelToken? cancelToken,
  }) async {
    final params = <String, dynamic>{
      'action': 'query',
      'format': 'json',
      'origin': '*',
      'generator': 'search',
      'gsrsearch': query,
      'gsrlimit': '$limit',
      'gsroffset': '$offset',
      'prop': 'pageimages|extracts',
      'piprop': 'thumbnail',
      'pithumbsize': '120',
      'exintro': '1',
      'explaintext': '1',
      'exsentences': '2',
      'redirects': '1',
    };
    final data = await get('/w/api.php',
        queryParameters: params, cancelToken: cancelToken);
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected API data');
  }

  /// SUMMARY (REST)
  Future<Response<dynamic>> getSummary(String title) async {
    final res = await _dio.get('/api/rest_v1/page/summary/${_enc(title)}');
    if (res.statusCode == 200) return res;
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      error: 'HTTP ${res.statusCode}',
      type: DioExceptionType.badResponse,
    );
  }

  /// SUMMARY utility (as a Map)
  Future<Map<String, dynamic>> getSummaryMap(String title) async {
    final res = await getSummary(title);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected summary data');
  }

  /// MOBILE HTML (full article)
  Future<String> getMobileHtml(String title) async {
    final res = await _dio.get(
      '/api/rest_v1/page/mobile-html/${_enc(title)}',
      options: Options(responseType: ResponseType.plain),
    );
    if (res.statusCode == 200) return res.data as String;
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      error: 'HTTP ${res.statusCode}',
      type: DioExceptionType.badResponse,
    );
  }

  /// Media list
  Future<Map<String, dynamic>> getMediaList(String title) async {
    final data = await get('/api/rest_v1/page/media-list/${_enc(title)}');
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected media data');
  }

  /// Related articles
  Future<Map<String, dynamic>> getRelated(String title) async {
    final data = await get('/api/rest_v1/page/related/${_enc(title)}');
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected related data');
  }

  Future<String> getParsedHtml(String title) async {
    final params = <String, dynamic>{
      'action': 'parse',
      'format': 'json',
      'origin': '*',
      'page': title,
      'prop': 'text',
      'redirects': '1',
    };
    final data = await get('/w/api.php', queryParameters: params);
    if (data is Map && data['parse'] is Map && data['parse']['text'] is Map) {
      final html = (data['parse']['text'] as Map)['*'];
      if (html is String) return html;
    }
    throw const FormatException('Unexpected parse text data');
  }

  /// Retrieve the list of Sections (TOC) from the Action API
  /// Each section includes: index, line (title), anchor
  Future<List<Map<String, dynamic>>> getSections(String title) async {
    final params = <String, dynamic>{
      'action': 'parse',
      'format': 'json',
      'origin': '*',
      'page': title,
      'prop': 'sections',
      'redirects': '1',
    };
    final data = await get('/w/api.php', queryParameters: params);
    if (data is Map &&
        data['parse'] is Map &&
        data['parse']['sections'] is List) {
      return List<Map<String, dynamic>>.from(
          (data['parse']['sections'] as List).cast<Map>());
    }
    throw const FormatException('Unexpected sections data');
  }
}
