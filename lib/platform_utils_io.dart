/// 非 Web 平台的实现
///
/// 这个文件在非 Web 平台（iOS, Android, macOS, Windows, Linux）上被使用
import 'dart:io';

/// 检查是否为桌面平台（macOS, Windows, Linux）
bool isDesktopPlatform() {
  return Platform.isMacOS || Platform.isLinux || Platform.isWindows;
}