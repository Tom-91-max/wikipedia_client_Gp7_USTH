// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'common/services/settings_service.dart';

/// Names of boxes used for Offline / History / Cache
class HiveBoxes {
  static const articles = 'articles_box';
  static const history = 'history_box';
  static const cache = 'cache_meta_box';
}

class _ProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(ProviderBase provider, Object? previousValue,
      Object? newValue, ProviderContainer container) {
    if (kDebugMode) {
      debugPrint(
          '[Provider] ${provider.name ?? provider.runtimeType} -> $newValue');
    }
    super.didUpdateProvider(provider, previousValue, newValue, container);
  }
}

Future<void> _initLocalStorage() async {
  await Hive.initFlutter();

  try {
    await Future.wait([
      Hive.openBox(HiveBoxes.articles),
      Hive.openBox(HiveBoxes.history),
      Hive.openBox(HiveBoxes.cache),
    ]);
  } catch (e, st) {
    debugPrint('Hive openBox error: $e\n$st');
    rethrow;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runZonedGuarded(() async {
    await SettingsService().init();
    await _initLocalStorage();
    runApp(
      ProviderScope(
        observers: kDebugMode ? [_ProviderLogger()] : const [],
        child: const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught zone error: $error\n$stack');
  });
}
