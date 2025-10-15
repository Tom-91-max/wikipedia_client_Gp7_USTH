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
//   /// Update base URL when language changes
//   void updateLanguage(String language) {
//     _baseUrl = 'https://$language.wikipedia.org';
//     _dio.options.baseUrl = _baseUrl;
//   }
//
//   /// SEARCH (ổn định): MediaWiki Action API
//   /// https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=...&format=json&srlimit=10
//   Future<Response<dynamic>> searchTitle(String query) {
//     return _dio.get(
//       '/w/api.php',
//       queryParameters: {
//         'action': 'query',
//         'list': 'search',
//         'srsearch': query,
//         'srlimit': 10,
//         'format': 'json',
//         'origin': '*', // an toàn nếu chạy web; mobile không vấn đề
//       },
//     );
//   }
//
//   /// SUMMARY (REST vẫn dùng tốt)
//   Future<Response<dynamic>> getSummary(String title) {
//     return _dio.get('/api/rest_v1/page/summary/$title');
//   }
// }


import 'package:dio/dio.dart';
import '../services/settings_service.dart';

/// ApiClient cấu hình Dio + Interceptor gắn User-Agent/Wikipedia JSON.
class ApiClient {
  static final ApiClient _i = ApiClient._internal();
  factory ApiClient() => _i;

  ApiClient._internal() {
    _updateBaseUrl();
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['User-Agent'] = _userAgent;
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
  String _baseUrl = 'https://en.wikipedia.org';
  Dio get dio => _dio;

  void _updateBaseUrl() {
    final language = SettingsService().wikipediaLanguage;
    _baseUrl = 'https://$language.wikipedia.org';
  }

  void updateLanguage(String language) {
    _baseUrl = 'https://$language.wikipedia.org';
    _dio.options.baseUrl = _baseUrl;
  }

  /// SEARCH (Action API cũ)
  Future<Response<dynamic>> searchTitle(String query) {
    return _dio.get(
      '/w/api.php',
      queryParameters: {
        'action': 'query',
        'list': 'search',
        'srsearch': query,
        'srlimit': 10,
        'format': 'json',
        'origin': '*',
      },
    );
  }

  /// 🔎 REST search/title (mới, hỗ trợ thumbnail + pagination)
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

  /// SUMMARY (REST)
  Future<Response<dynamic>> getSummary(String title) {
    final encoded = Uri.encodeComponent(title);
    return _dio.get('/api/rest_v1/page/summary/$encoded');
  }
}
