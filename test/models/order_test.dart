import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/models/order.dart';

void main() {
  group('Order', () {
    final testDate = DateTime(2024, 3, 15, 10, 30);

    test('应该正确从 JSON 反序列化', () {
      final json = {
        'id': 1,
        'ticket_number': 42,
        'dish_id': 5,
        'dish_name': '红烧肉',
        'created_at': testDate.millisecondsSinceEpoch,
        'date': '2024-03-15',
      };

      final order = Order.fromJson(json);

      expect(order.id, equals(1));
      expect(order.ticketNumber, equals(42));
      expect(order.dishId, equals(5));
      expect(order.dishName, equals('红烧肉'));
      expect(order.createdAt, equals(testDate));
    });

    test('应该正确序列化为 JSON', () {
      final order = Order(
        id: 1,
        ticketNumber: 42,
        dishId: 5,
        dishName: '红烧肉',
        createdAt: testDate,
      );

      final json = order.toJson();

      expect(json['id'], equals(1));
      expect(json['ticket_number'], equals(42));
      expect(json['dish_id'], equals(5));
      expect(json['dish_name'], equals('红烧肉'));
      expect(json['created_at'], equals(testDate.millisecondsSinceEpoch));
      expect(json['date'], equals('2024-03-15'));
    });

    test('copyWith 应该创建更新后的副本', () {
      final order = Order(
        id: 1,
        ticketNumber: 1,
        dishId: 1,
        dishName: '原菜品',
        createdAt: testDate,
      );

      final updated = order.copyWith(
        dishName: '新菜品',
        ticketNumber: 2,
      );

      // 验证更新的字段
      expect(updated.dishName, equals('新菜品'));
      expect(updated.ticketNumber, equals(2));

      // 验证未改变的字段
      expect(updated.id, equals(order.id));
      expect(updated.dishId, equals(order.dishId));
      expect(updated.createdAt, equals(order.createdAt));
    });

    test('copyWith 不传入参数应返回相同值', () {
      final order = Order(
        id: 1,
        ticketNumber: 42,
        dishId: 5,
        dishName: '红烧肉',
        createdAt: testDate,
      );

      final copied = order.copyWith();

      expect(copied.id, equals(order.id));
      expect(copied.ticketNumber, equals(order.ticketNumber));
      expect(copied.dishId, equals(order.dishId));
      expect(copied.dishName, equals(order.dishName));
      expect(copied.createdAt, equals(order.createdAt));
    });

    test('相等性判断应正确工作', () {
      final order1 = Order(
        id: 1,
        ticketNumber: 42,
        dishId: 5,
        dishName: '红烧肉',
        createdAt: testDate,
      );

      final order2 = Order(
        id: 1,
        ticketNumber: 42,
        dishId: 5,
        dishName: '红烧肉',
        createdAt: testDate,
      );

      final order3 = Order(
        id: 2,
        ticketNumber: 43,
        dishId: 6,
        dishName: '糖醋排骨',
        createdAt: testDate,
      );

      expect(order1, equals(order2));
      expect(order1.hashCode, equals(order2.hashCode));
      expect(order1, isNot(equals(order3)));
    });

    test('date getter 应返回正确格式的日期字符串', () {
      final morningOrder = Order(
        ticketNumber: 1,
        dishId: 1,
        dishName: '早餐',
        createdAt: DateTime(2024, 1, 5, 8, 30),
      );

      final afternoonOrder = Order(
        ticketNumber: 2,
        dishId: 2,
        dishName: '午餐',
        createdAt: DateTime(2024, 12, 25, 14, 0),
      );

      expect(morningOrder.date, equals('2024-01-05'));
      expect(afternoonOrder.date, equals('2024-12-25'));
    });

    test('应支持 null id（新订单）', () {
      final order = Order(
        ticketNumber: 1,
        dishId: 1,
        dishName: '测试菜品',
        createdAt: testDate,
      );

      expect(order.id, isNull);

      final json = order.toJson();
      expect(json['id'], isNull);
    });

    test('fromJson 应处理所有整数字段', () {
      final json = {
        'id': 100,
        'ticket_number': 999,
        'dish_id': 50,
        'dish_name': '测试',
        'created_at': testDate.millisecondsSinceEpoch,
        'date': '2024-03-15',
      };

      final order = Order.fromJson(json);

      expect(order.id.runtimeType, equals(int));
      expect(order.ticketNumber.runtimeType, equals(int));
      expect(order.dishId.runtimeType, equals(int));
    });
  });
}
