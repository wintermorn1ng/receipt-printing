import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';

// 条件导入：非 Web 平台使用 dart:io，Web 平台使用空实现
import 'platform_utils_stub.dart'
    if (dart.library.io) 'platform_utils_io.dart';

/// 应用入口
///
/// 初始化 Flutter 应用并启动
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 仅在桌面平台初始化 sqflite FFI（Web 平台不支持）
  if (!kIsWeb && isDesktopPlatform()) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const App());
}