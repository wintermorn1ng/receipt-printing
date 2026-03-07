/// 非 Web 平台的实现
///
/// 这个文件在非 Web 平台（iOS, Android, macOS, Windows, Linux）上被使用
import 'dart:io';

/// 创建 File 对象
File createFile(String path) => File(path);