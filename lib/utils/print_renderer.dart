/// 打印数据模型
///
/// 包含打印小票所需的所有信息
class PrintData {
  /// 取餐号
  final int ticketNumber;

  /// 菜品名称
  final String dishName;

  /// 店名（可选）
  final String? shopName;

  /// 日期时间（可选）
  final DateTime? dateTime;

  /// 切纸前进纸行数
  final int gapLines;

  /// 两联打印时，两张票之间的间距行数
  final int ticketGapLines;

  /// 诗句（可选，不打印诗词时为 null）
  final String? poetryText;

  /// 诗句作者（可选）
  final String? poetryAuthor;

  const PrintData({
    required this.ticketNumber,
    required this.dishName,
    this.shopName,
    this.dateTime,
    this.gapLines = 0,
    this.ticketGapLines = 0,
    this.poetryText,
    this.poetryAuthor,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintData &&
          runtimeType == other.runtimeType &&
          ticketNumber == other.ticketNumber &&
          dishName == other.dishName &&
          shopName == other.shopName &&
          dateTime == other.dateTime &&
          gapLines == other.gapLines &&
          ticketGapLines == other.ticketGapLines &&
          poetryText == other.poetryText &&
          poetryAuthor == other.poetryAuthor;

  @override
  int get hashCode => Object.hash(ticketNumber, dishName, shopName, dateTime,
      gapLines, ticketGapLines, poetryText, poetryAuthor);

  @override
  String toString() {
    return 'PrintData(ticketNumber: $ticketNumber, dishName: $dishName, '
        'shopName: $shopName, dateTime: $dateTime, gapLines: $gapLines, '
        'ticketGapLines: $ticketGapLines, poetryText: $poetryText, '
        'poetryAuthor: $poetryAuthor)';
  }
}

/// 抽象打印渲染器
///
/// 定义打印接口，支持多种渲染目标（蓝牙打印机、预览等）
abstract class PrintRenderer {
  /// 渲染单张小票
  Future<void> render(PrintData data);

  /// 渲染两联小票
  Future<void> renderTwoCopies(PrintData data);

  /// 释放资源
  Future<void> dispose();
}