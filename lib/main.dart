import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'common/services/settings_service.dart';

/// Tên các box dùng cho Offline / History / Cache
class HiveBoxes {
  static const articles =
      'articles_box'; // lưu bài đọc (HTML/summary/thumb + savedOffline)
  static const history = 'history_box'; // lịch sử đọc
  static const cache = 'cache_meta_box'; // TTL/etag nếu cần
}

Future<void> _initLocalStorage() async {
  // Khởi tạo Hive (dùng thư mục app documents)
  await Hive.initFlutter();

  // TODO: khi thêm model + TypeAdapter, nhớ register ở đây.
  // Ví dụ:
  // Hive.registerAdapter(ArticleEntityAdapter());
  // Hive.registerAdapter(HistoryEntityAdapter());
  // Hive.registerAdapter(CacheMetaEntityAdapter());

  // Mở các box cần dùng (dùng dynamic trước; sau sẽ chuyển sang typed)
  await Hive.openBox(HiveBoxes.articles);
  await Hive.openBox(HiveBoxes.history);
  await Hive.openBox(HiveBoxes.cache);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Settings (giữ nguyên app hiện tại)
  await SettingsService().init();

  // 2) Local DB cho Offline/History/Cache
  await _initLocalStorage();

  runApp(const ProviderScope(child: MyApp()));
}
