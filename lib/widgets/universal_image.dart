import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 条件导入：非 Web 平台使用 dart:io，Web 平台使用空实现
import 'universal_image_stub.dart'
    if (dart.library.io) 'universal_image_io.dart';

/// 跨平台图片组件
///
/// 在非 Web 平台使用 Image.file，在 Web 平台显示占位图
/// 因为 Web 平台不支持本地文件路径的图片显示
class UniversalImage extends StatelessWidget {
  /// 图片路径
  final String path;

  /// 图片填充方式
  final BoxFit fit;

  /// 错误构建器
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const UniversalImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web 平台暂不支持本地文件图片，显示错误或占位
      if (errorBuilder != null) {
        return errorBuilder!(context, 'Web does not support local file images', null);
      }
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      );
    }

    // 非 Web 平台使用 Image.file
    return Image.file(
      createFile(path),
      fit: fit,
      errorBuilder: errorBuilder,
    );
  }
}