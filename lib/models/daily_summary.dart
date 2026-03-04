import 'package:flutter/foundation.dart';

/// 菜品销量统计
///
/// 用于日总结中的各菜品销售数量统计
@immutable
class DishSummary {
  final int dishId;
  final String dishName;
  final int count;

  const DishSummary({
    required this.dishId,
    required this.dishName,
    required this.count,
  });

  /// 创建副本并更新指定字段
  DishSummary copyWith({
    int? dishId,
    String? dishName,
    int? count,
  }) {
    return DishSummary(
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DishSummary &&
          runtimeType == other.runtimeType &&
          dishId == other.dishId &&
          dishName == other.dishName &&
          count == other.count;

  @override
  int get hashCode => Object.hash(dishId, dishName, count);

  @override
  String toString() {
    return 'DishSummary(dishId: $dishId, dishName: $dishName, count: $count)';
  }
}

/// 日总结数据模型
///
/// 包含某一天的所有订单统计数据
@immutable
class DailySummary {
  final DateTime date;
  final int totalOrders;
  final List<DishSummary> dishSummaries;
  final Map<int, int> hourlyDistribution; // 小时(0-23): 订单数

  const DailySummary({
    required this.date,
    required this.totalOrders,
    required this.dishSummaries,
    required this.hourlyDistribution,
  });

  /// 获取日期字符串 (YYYY-MM-DD)
  String get dateString {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 计算总销量（所有菜品数量之和）
  int get totalDishes {
    return dishSummaries.fold(0, (sum, summary) => sum + summary.count);
  }

  /// 获取最畅销的菜品（按销量排序后取第一个）
  DishSummary? get topDish {
    if (dishSummaries.isEmpty) return null;
    final sorted = List<DishSummary>.from(dishSummaries)
      ..sort((a, b) => b.count.compareTo(a.count));
    return sorted.first;
  }

  /// 获取高峰时段（订单最多的小时）
  int? get peakHour {
    if (hourlyDistribution.isEmpty) return null;
    return hourlyDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// 创建副本并更新指定字段
  DailySummary copyWith({
    DateTime? date,
    int? totalOrders,
    List<DishSummary>? dishSummaries,
    Map<int, int>? hourlyDistribution,
  }) {
    return DailySummary(
      date: date ?? this.date,
      totalOrders: totalOrders ?? this.totalOrders,
      dishSummaries: dishSummaries ?? this.dishSummaries,
      hourlyDistribution: hourlyDistribution ?? this.hourlyDistribution,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailySummary &&
          runtimeType == other.runtimeType &&
          date.year == other.date.year &&
          date.month == other.date.month &&
          date.day == other.date.day &&
          totalOrders == other.totalOrders &&
          _listEquals(dishSummaries, other.dishSummaries) &&
          _mapEquals(hourlyDistribution, other.hourlyDistribution);

  @override
  int get hashCode => Object.hash(
        date.year,
        date.month,
        date.day,
        totalOrders,
        Object.hashAll(dishSummaries),
        Object.hashAll(hourlyDistribution.entries),
      );

  @override
  String toString() {
    return 'DailySummary(date: $dateString, totalOrders: $totalOrders, '
        'dishSummaries: ${dishSummaries.length}, hourlyDistribution: ${hourlyDistribution.length})';
  }
}

/// 比较两个列表是否相等
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 比较两个 Map 是否相等
bool _mapEquals<K, V>(Map<K, V>? a, Map<K, V>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || a[key] != b[key]) return false;
  }
  return true;
}
