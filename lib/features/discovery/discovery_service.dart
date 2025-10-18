import 'package:dio/dio.dart';

class DiscoveryService {
  final Dio _dio;
  DiscoveryService(this._dio);

  static const _userAgent = 'USTH-Group7-WikiClient/1.0 (discovery)';
  Options get _opts => Options(headers: const {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      });

  String _two(int n) => n.toString().padLeft(2, '0');

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected response format');
  }

  Future<Map<String, dynamic>> getFeaturedContent({DateTime? date}) async {
    final d = date ?? DateTime.now();
    final y = d.year, m = _two(d.month), dd = _two(d.day);
    final res =
        await _dio.get('/api/rest_v1/feed/featured/$y/$m/$dd', options: _opts);
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> getMostViewedArticles({DateTime? date}) async {
    final d = date ?? DateTime.now();
    final y = d.year, m = _two(d.month), dd = _two(d.day);
    final res =
        await _dio.get('/api/rest_v1/feed/most-read/$y/$m/$dd', options: _opts);
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> getOnThisDayEvents({DateTime? date}) async {
    final d = date ?? DateTime.now();
    final m = _two(d.month), dd = _two(d.day);
    final res = await _dio.get('/api/rest_v1/feed/onthisday/events/$m/$dd',
        options: _opts);
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> getRandomArticle() async {
    final res =
        await _dio.get('/api/rest_v1/page/random/summary', options: _opts);
    return _asMap(res.data);
  }
}
