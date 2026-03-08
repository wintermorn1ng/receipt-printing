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

  const PrintData({
    required this.ticketNumber,
    required this.dishName,
    this.shopName,
    this.dateTime,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintData &&
          runtimeType == other.runtimeType &&
          ticketNumber == other.ticketNumber &&
          dishName == other.dishName &&
          shopName == other.shopName &&
          dateTime == other.dateTime;

  @override
  int get hashCode => Object.hash(ticketNumber, dishName, shopName, dateTime);

  @override
  String toString() {
    return 'PrintData(ticketNumber: $ticketNumber, dishName: $dishName, '
        'shopName: $shopName, dateTime: $dateTime)';
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