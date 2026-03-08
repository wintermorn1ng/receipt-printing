import 'dart:async';
import 'package:intl/intl.dart';
import 'print_renderer.dart';
import 'preview_line.dart';

/// 页面预览渲染器
///
/// 实现 PrintRenderer 接口，用于在 UI 上预览小票样式
class PreviewRenderer implements PrintRenderer {
  final StreamController<List<PreviewLine>> _linesController =
      StreamController<List<PreviewLine>>.broadcast();

  /// 预览数据流，供 UI 订阅
  Stream<List<PreviewLine>> get linesStream => _linesController.stream;

  @override
  Future<void> render(PrintData data) async {
    final lines = _generatePreviewLines(data);
    _linesController.add(lines);
  }

  @override
  Future<void> renderTwoCopies(PrintData data) async {
    // 预览时只显示一联
    await render(data);
  }

  /// 生成预览线条列表
  List<PreviewLine> _generatePreviewLines(PrintData data) {
    final List<PreviewLine> lines = [];

    // 店名（如果提供）
    if (data.shopName != null && data.shopName!.isNotEmpty) {
      lines.add(PreviewLine(data.shopName!, isBold: true));
      lines.add(PreviewLine('-' * 20));
    }

    // 取餐号（大字加粗）
    lines.add(PreviewLine('#${data.ticketNumber}', isLarge: true, isBold: true));

    // 分隔线
    lines.add(PreviewLine('-' * 20));

    // 菜品名称
    lines.add(PreviewLine(data.dishName));

    // 空行
    lines.add(PreviewLine(''));

    // 日期时间（如果提供）
    if (data.dateTime != null) {
      lines.add(PreviewLine(_formatDateTime(data.dateTime!)));
      // 空行
      lines.add(PreviewLine(''));
    }

    return lines;
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }

  @override
  Future<void> dispose() async {
    await _linesController.close();
  }
}