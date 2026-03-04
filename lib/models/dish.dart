import 'package:flutter/foundation.dart';

/// 菜品数据模型
///
/// 表示菜单中的一个菜品，支持序列化和不可变更新
@immutable
class Dish {
  final int? id;
  final String name; // 必填
  final double? price; // 可选
  final String? imagePath; // 可选
  final int sortOrder; // 排序，默认0
  final DateTime createdAt;
  final DateTime updatedAt;

  const Dish({
    this.id,
    required this.name,
    this.price,
    this.imagePath,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON (Map) 反序列化
  ///
  /// 用于从数据库读取数据
  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as int?,
      name: json['name'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      imagePath: json['image_path'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int),
    );
  }

  /// 序列化为 JSON (Map)
  ///
  /// 用于写入数据库
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image_path': imagePath,
      'sort_order': sortOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 创建副本并更新指定字段
  ///
  /// 使用 [Value] 包装器来区分 null 值和未设置值
  Dish copyWith({
    Value<int?>? id,
    String? name,
    Value<double?>? price,
    Value<String?>? imagePath,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dish(
      id: id != null ? id.value : this.id,
      name: name ?? this.name,
      price: price != null ? price.value : this.price,
      imagePath: imagePath != null ? imagePath.value : this.imagePath,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Dish &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price &&
          imagePath == other.imagePath &&
          sortOrder == other.sortOrder &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, name, price, imagePath, sortOrder, createdAt, updatedAt);

  @override
  String toString() {
    return 'Dish(id: $id, name: $name, price: $price, imagePath: $imagePath, '
        'sortOrder: $sortOrder, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// 用于区分 null 值和未设置值的包装类
@immutable
class Value<T> {
  final T value;
  const Value(this.value);
}
