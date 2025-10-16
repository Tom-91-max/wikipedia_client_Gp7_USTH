import 'package:dio/dio.dart';

class ApiClient {
  // Singleton
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal() {
    _createDio();
  }

  late Dio _dio;

  // Ngôn ngữ Wikipedia (phải khớp với languageProvider của bạn)
  String _langCode = 'en';
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

    // Log nhẹ để debug (tắt body cho gọn)
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  /// Gọi từ languageProvider khi người dùng đổi ngôn ngữ (vi, en, fr, ...)
  Future<void> updateLanguage(String languageCode) async {
    if (languageCode.isEmpty || languageCode == _langCode) return;
    _langCode = languageCode;
    _createDio(); // rebuild Dio với baseUrl mới
  }

  // --------------------------
  // Helpers
  // --------------------------
  String _enc(String title) => Uri.encodeComponent(title);

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

  // --------------------------
  // Search
  // --------------------------

  /// REST search/title (hỗ trợ thumbnail + pagination)
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

  /// Action API (generator=search) – nếu SearchScreen của bạn đang dùng dạng này
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

  // --------------------------
  // Page content APIs (REST)
  // --------------------------

  /// SUMMARY (REST) – dùng cho TTS/preview
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

  /// SUMMARY tiện ích (Map) – nếu bạn thích dữ liệu parse sẵn
  Future<Map<String, dynamic>> getSummaryMap(String title) async {
    final res = await getSummary(title);
    final data = res.data;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected summary data');
  }

  /// MOBILE HTML (full article) – dùng để lưu/offline
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

  /// Media list (mở rộng)
  Future<Map<String, dynamic>> getMediaList(String title) async {
    final data = await get('/api/rest_v1/page/media-list/${_enc(title)}');
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected media data');
  }

  /// Related articles (mở rộng)
  Future<Map<String, dynamic>> getRelated(String title) async {
    final data = await get('/api/rest_v1/page/related/${_enc(title)}');
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected related data');
  }
}
