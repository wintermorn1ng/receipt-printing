import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/models/dish.dart';

void main() {
  group('Dish', () {
    final now = DateTime.now();
    final later = now.add(const Duration(seconds: 1));

    test('fromJson 正确反序列化数据库数据', () {
      final json = {
        'id': 1,
        'name': '红烧肉',
        'price': 28.5,
        'image_path': '/path/to/image.jpg',
        'sort_order': 2,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': later.millisecondsSinceEpoch,
      };

      final dish = Dish.fromJson(json);

      expect(dish.id, 1);
      expect(dish.name, '红烧肉');
      expect(dish.price, 28.5);
      expect(dish.imagePath, '/path/to/image.jpg');
      expect(dish.sortOrder, 2);
      expect(dish.createdAt.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(dish.updatedAt.millisecondsSinceEpoch, later.millisecondsSinceEpoch);
    });

    test('fromJson 处理可选字段为 null 的情况', () {
      final json = {
        'id': 1,
        'name': '清炒时蔬',
        'price': null,
        'image_path': null,
        'sort_order': 0,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      };

      final dish = Dish.fromJson(json);

      expect(dish.id, 1);
      expect(dish.name, '清炒时蔬');
      expect(dish.price, null);
      expect(dish.imagePath, null);
      expect(dish.sortOrder, 0);
    });

    test('toJson 正确序列化为数据库格式', () {
      final dish = Dish(
        id: 1,
        name: '糖醋排骨',
        price: 35.0,
        imagePath: '/images/paigu.jpg',
        sortOrder: 1,
        createdAt: now,
        updatedAt: later,
      );

      final json = dish.toJson();

      expect(json['id'], 1);
      expect(json['name'], '糖醋排骨');
      expect(json['price'], 35.0);
      expect(json['image_path'], '/images/paigu.jpg');
      expect(json['sort_order'], 1);
      expect(json['created_at'], now.millisecondsSinceEpoch);
      expect(json['updated_at'], later.millisecondsSinceEpoch);
    });

    test('copyWith 更新单个字段', () {
      final dish = Dish(
        id: 1,
        name: '原名称',
        price: 20.0,
        createdAt: now,
        updatedAt: now,
      );

      final updated = dish.copyWith(name: '新名称');

      expect(updated.id, 1);
      expect(updated.name, '新名称');
      expect(updated.price, 20.0);
      expect(updated.createdAt, now);
    });

    test('copyWith 使用 Value 包装器设置 null 值', () {
      final dish = Dish(
        id: 1,
        name: '测试菜品',
        price: 20.0,
        imagePath: '/path.jpg',
        createdAt: now,
        updatedAt: now,
      );

      // 使用 Value(null) 明确设置 price 为 null
      final updated = dish.copyWith(
        price: const Value<double?>(null),
        imagePath: const Value<String?>(null),
      );

      expect(updated.price, null);
      expect(updated.imagePath, null);
      expect(updated.name, '测试菜品'); // 其他字段不变
    });

    test('copyWith 不传入 Value 时保持原值', () {
      final dish = Dish(
        id: 1,
        name: '测试菜品',
        price: 20.0,
        createdAt: now,
        updatedAt: now,
      );

      // 不传 price 参数，应保持原值
      final updated = dish.copyWith(name: '新名称');

      expect(updated.price, 20.0); // 保持原值
      expect(updated.name, '新名称');
    });

    test('相等性判断 - 相同值的实例相等', () {
      final dish1 = Dish(
        id: 1,
        name: '测试',
        price: 20.0,
        createdAt: now,
        updatedAt: now,
      );

      final dish2 = Dish(
        id: 1,
        name: '测试',
        price: 20.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(dish1, dish2);
      expect(dish1.hashCode, dish2.hashCode);
    });

    test('相等性判断 - 不同值的实例不相等', () {
      final dish1 = Dish(
        id: 1,
        name: '测试1',
        createdAt: now,
        updatedAt: now,
      );

      final dish2 = Dish(
        id: 1,
        name: '测试2',
        createdAt: now,
        updatedAt: now,
      );

      expect(dish1, isNot(equals(dish2)));
    });

    test('toString 返回有意义的字符串表示', () {
      final dish = Dish(
        id: 1,
        name: '测试菜品',
        price: 20.0,
        createdAt: now,
        updatedAt: now,
      );

      final str = dish.toString();

      expect(str.contains('Dish'), true);
      expect(str.contains('测试菜品'), true);
      expect(str.contains('20.0'), true);
    });
  });
}
