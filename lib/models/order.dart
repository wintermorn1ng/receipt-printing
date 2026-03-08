import 'package:flutter/foundation.dart';
import 'dish.dart';

/// 订单数据模型
///
/// 表示一个点单记录，包含取餐号和菜品信息
@immutable
class Order {
  final int? id;
  final int ticketNumber; // 取餐号
  final int dishId; // 菜品ID
  final String dishName; // 菜品名称（冗余存储，防止菜品被删除后无法显示）
  final DateTime createdAt;

  const Order({
    this.id,
    required this.ticketNumber,
    required this.dishId,
    required this.dishName,
    required this.createdAt,
  });

  /// 从 JSON (Map) 反序列化
  ///
  /// 用于从数据库读取数据
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      ticketNumber: json['ticket_number'] as int,
      dishId: json['dish_id'] as int,
      dishName: json['dish_name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
    );
  }

  /// 从数据库 Map 转换为 Order 对象
  /// [fromJson] 的别名，用于兼容旧代码
  factory Order.fromMap(Map<String, dynamic> map) => Order.fromJson(map);

  /// 序列化为 JSON (Map)
  ///
  /// 用于写入数据库
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'dish_id': dishId,
      'dish_name': dishName,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// 将 Order 对象转换为数据库 Map
  /// [toJson] 的别名，用于兼容旧代码
  Map<String, dynamic> toMap() => toJson();

  /// 创建副本并更新指定字段
  ///
  /// 使用 [Value] 包装器来区分 null 值和未设置值
  Order copyWith({
    Value<int?>? id,
    int? ticketNumber,
    int? dishId,
    String? dishName,
    DateTime? createdAt,
  }) {
    return Order(
      id: id != null ? id.value : this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 获取日期字符串 (YYYY-MM-DD)
  String get date {
    final year = createdAt.year.toString().padLeft(4, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final day = createdAt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ticketNumber == other.ticketNumber &&
          dishId == other.dishId &&
          dishName == other.dishName &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      Object.hash(id, ticketNumber, dishId, dishName, createdAt);

  @override
  String toString() {
    return 'Order(id: $id, ticketNumber: $ticketNumber, dishId: $dishId, '
        'dishName: $dishName, createdAt: $createdAt)';
  }
}
