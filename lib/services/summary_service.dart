import 'package:meta/meta.dart';
import '../database/order_dao.dart';
import '../models/daily_summary.dart';

/// 日总结服务
///
/// 提供获取日总结数据、有订单日期列表等功能
class SummaryService {
  final OrderDao _orderDao;

  /// 构造函数
  SummaryService(this._orderDao);

  /// 构造函数 - 用于测试
  @visibleForTesting
  SummaryService.forTest(this._orderDao);

  /// 获取某日总结
  Future<DailySummary> getDailySummary(DateTime date) async {
    final dateStr = _formatDate(date);

    // 并行获取所有数据
    final results = await Future.wait([
      _orderDao.getOrderCountByDate(dateStr),
      _orderDao.getDishCountByDate(dateStr),
      _orderDao.getHourlyDistribution(dateStr),
    ]);

    final totalOrders = results[0] as int;
    final dishCounts = results[1] as Map<String, int>;
    final hourlyDistribution = results[2] as Map<int, int>;

    // 转换菜品统计（由于没有 dishId，设为 0）
    final dishSummaries = dishCounts.entries.map((entry) {
      return DishSummary(
        dishId: 0,
        dishName: entry.key,
        count: entry.value,
      );
    }).toList();

    // 按销量降序排列
    dishSummaries.sort((a, b) => b.count.compareTo(a.count));

    return DailySummary(
      date: date,
      totalOrders: totalOrders,
      dishSummaries: dishSummaries,
      hourlyDistribution: hourlyDistribution,
    );
  }

  /// 获取有订单的日期列表
  Future<List<DateTime>> getAvailableDates() async {
    final dateStrings = await _orderDao.getAvailableDates();
    return dateStrings.map((str) => _parseDate(str)).toList();
  }

  /// 格式化日期 YYYY-MM-DD
  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// 解析日期字符串为 DateTime
  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}