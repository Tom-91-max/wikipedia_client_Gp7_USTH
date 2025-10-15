// import 'package:dio/dio.dart';
// import '../services/settings_service.dart';
//
// /// ApiClient cấu hình Dio + Interceptor gắn User-Agent/Wikipedia JSON.
// class ApiClient {
//   static final ApiClient _i = ApiClient._internal();
//   factory ApiClient() => _i;
//
//   ApiClient._internal() {
//     _updateBaseUrl();
//     _dio = Dio(
//       BaseOptions(
//         baseUrl: _baseUrl,
//         connectTimeout: const Duration(seconds: 10),
//         receiveTimeout: const Duration(seconds: 15),
//         headers: {
//           'User-Agent': _userAgent,
//           'Accept': 'application/json',
//         },
//       ),
//     );
//
//     _dio.interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) {
//           options.headers['User-Agent'] = _userAgent;
//           return handler.next(options);
//         },
//         onError: (e, handler) {
//           return handler.next(e);
//         },
//       ),
//     );
//   }
//
//   static const String _userAgent =
//       'USTH-Group7-WikiClient/1.0 (contact@usth.edu.vn)';
//
//   late Dio _dio;
//   String _baseUrl = 'https://en.wikipedia.org';
//   Dio get dio => _dio;
//
//   void _updateBaseUrl() {
//     final language = SettingsService().wikipediaLanguage;
//     _baseUrl = 'https://$language.wikipedia.org';
//   }
//
//   void updateLanguage(String language) {
//     _baseUrl = 'https://$language.wikipedia.org';
//     _dio.options.baseUrl = _baseUrl;
//   }
//
//   /// SEARCH (Action API cũ)
//   Future<Response<dynamic>> searchTitle(String query) {
//     return _dio.get(
//       '/w/api.php',
//       queryParameters: {
//         'action': 'query',
//         'list': 'search',
//         'srsearch': query,
//         'srlimit': 10,
//         'format': 'json',
//         'origin': '*',
//       },
//     );
//   }
//
//   /// 🔎 REST search/title (mới, hỗ trợ thumbnail + pagination)
//   Future<Response<dynamic>> searchTitleRest(
//       String query, {
//         int limit = 20,
//         int offset = 0,
//         CancelToken? cancelToken,
//       }) {
//     return _dio.get(
//       '/w/rest.php/v1/search/title',
//       queryParameters: {
//         'q': query,
//         'limit': limit,
//         'offset': offset,
//       },
//       cancelToken: cancelToken,
//     );
//   }
//
//   /// SUMMARY (REST)
//   Future<Response<dynamic>> getSummary(String title) {
//     final encoded = Uri.encodeComponent(title);
//     return _dio.get('/api/rest_v1/page/summary/$encoded');
//   }
// }






// lib/common/network/api_client.dart
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

  // Ngôn ngữ mặc định (khớp LanguageProvider của bạn nếu là 'en')
  String _langCode = 'en';
  String get baseUrl => 'https://$_langCode.wikipedia.org';

  void _createDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'User-Agent': 'USTH-Group7-WikiClient/1.0 (contact@usth.edu.vn)',
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

  /// Được LanguageProvider gọi để đổi ngôn ngữ (vi, en, fr...)
  Future<void> updateLanguage(String languageCode) async {
    if (languageCode.isEmpty || languageCode == _langCode) return;
    _langCode = languageCode;
    _createDio(); // rebuild Dio với baseUrl mới
  }

  /// GET tiện ích -> trả về data đã parse (dynamic/Map)
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final res = await _dio.get(path, queryParameters: queryParameters);
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

  /// SEARCH cho SearchScreen (nếu muốn dùng trực tiếp)
  Future<Map<String, dynamic>> searchRaw({
    required String query,
    required int limit,
    required int offset,
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
    final data = await get('/w/api.php', queryParameters: params);
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected API data');
  }

  // =======================
  //  QUAN TRỌNG CHO BẠN
  //  Trả về Response để article_screen.dart dùng .data
  // =======================
  Future<Response<dynamic>> getSummary(String title) async {
    final res = await _dio.get('/api/rest_v1/page/summary/$title');
    if (res.statusCode == 200) return res;
    throw DioException(
      requestOptions: res.requestOptions,
      response: res,
      error: 'HTTP ${res.statusCode}',
      type: DioExceptionType.badResponse,
    );
  }

  /// Nếu nơi nào đó thích nhận Map thay vì Response, dùng hàm này (tuỳ chọn)
  Future<Map<String, dynamic>> getSummaryMap(String title) async {
    final res = await getSummary(title);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected summary data');
  }

  /// Mobile HTML (full content) – ít khi article_screen cần vì đã load WebView trực tiếp
  Future<String> getMobileHtml(String title) async {
    final res = await _dio.get(
      '/api/rest_v1/page/mobile-html/$title',
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

  /// Media list (mở rộng)
  Future<Map<String, dynamic>> getMediaList(String title) async {
    final data = await get('/api/rest_v1/page/media-list/$title');
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected media data');
  }

  /// Related articles (mở rộng)
  Future<Map<String, dynamic>> getRelated(String title) async {
    final data = await get('/api/rest_v1/page/related/$title');
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected related data');
  }
}
