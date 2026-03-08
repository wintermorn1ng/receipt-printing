import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/database/order_dao.dart';
import 'package:receipt_printing/database/in_memory_repository.dart';

/// OrderDao 单元测试
///
/// 使用 InMemoryRepository 在所有平台测试数据库操作
void main() {
  group('OrderDao Tests', () {
    late InMemoryRepository repository;
    late OrderDao orderDao;

    setUp(() async {
      // 每个测试使用独立的内存数据库实例
      repository = InMemoryRepository();
      repository.createTable('orders');
      orderDao = OrderDao.withTestRepository(repository);
    });

    test('插入订单并获取', () async {
      // Arrange
      final order = Order(
        ticketNumber: 1,
        dishId: 101,
        dishName: '牛肉面',
        createdAt: DateTime(2024, 3, 15, 10, 30),
      );

      // Act
      await orderDao.insert(order);
      final dateStr = '2024-03-15';
      final orders = await orderDao.getByDate(dateStr);

      // Assert
      expect(orders.length, equals(1));
      expect(orders.first.ticketNumber, equals(1));
      expect(orders.first.dishName, equals('牛肉面'));
      expect(orders.first.dishId, equals(101));
    });

    test('获取某日订单数量', () async {
      // Arrange
      final baseDate = DateTime(2024, 3, 15);
      final orders = [
        Order(ticketNumber: 1, dishId: 1, dishName: 'A', createdAt: baseDate.add(const Duration(hours: 8))),
        Order(ticketNumber: 2, dishId: 2, dishName: 'B', createdAt: baseDate.add(const Duration(hours: 9))),
        Order(ticketNumber: 3, dishId: 1, dishName: 'A', createdAt: baseDate.add(const Duration(hours: 10))),
      ];

      // Act
      for (final order in orders) {
        await orderDao.insert(order);
      }
      final count = await orderDao.getOrderCountByDate('2024-03-15');

      // Assert
      expect(count, equals(3));
    });

    test('获取各菜品销量统计', () async {
      // Arrange
      final baseDate = DateTime(2024, 3, 15);
      final orders = [
        Order(ticketNumber: 1, dishId: 1, dishName: '牛肉面', createdAt: baseDate),
        Order(ticketNumber: 2, dishId: 2, dishName: '炸酱面', createdAt: baseDate),
        Order(ticketNumber: 3, dishId: 1, dishName: '牛肉面', createdAt: baseDate),
        Order(ticketNumber: 4, dishId: 1, dishName: '牛肉面', createdAt: baseDate),
        Order(ticketNumber: 5, dishId: 3, dishName: '豆浆', createdAt: baseDate),
      ];

      // Act
      for (final order in orders) {
        await orderDao.insert(order);
      }
      final stats = await orderDao.getDishCountByDate('2024-03-15');

      // Assert
      expect(stats['牛肉面'], equals(3));
      expect(stats['炸酱面'], equals(1));
      expect(stats['豆浆'], equals(1));
    });

    test('获取最大取餐号', () async {
      // Arrange
      final baseDate = DateTime(2024, 3, 15);
      final orders = [
        Order(ticketNumber: 5, dishId: 1, dishName: 'A', createdAt: baseDate),
        Order(ticketNumber: 12, dishId: 2, dishName: 'B', createdAt: baseDate),
        Order(ticketNumber: 8, dishId: 1, dishName: 'C', createdAt: baseDate),
      ];

      // Act
      for (final order in orders) {
        await orderDao.insert(order);
      }
      final maxTicket = await orderDao.getMaxTicketNumber('2024-03-15');

      // Assert
      expect(maxTicket, equals(12));
    });

    test('不同日期的订单隔离', () async {
      // Arrange
      final order1 = Order(
        ticketNumber: 1,
        dishId: 1,
        dishName: '今日订单',
        createdAt: DateTime(2024, 3, 15, 10, 0),
      );
      final order2 = Order(
        ticketNumber: 2,
        dishId: 1,
        dishName: '昨日订单',
        createdAt: DateTime(2024, 3, 14, 10, 0),
      );

      // Act
      await orderDao.insert(order1);
      await orderDao.insert(order2);
      final todayOrders = await orderDao.getByDate('2024-03-15');
      final yesterdayOrders = await orderDao.getByDate('2024-03-14');

      // Assert
      expect(todayOrders.length, equals(1));
      expect(todayOrders.first.dishName, equals('今日订单'));
      expect(yesterdayOrders.length, equals(1));
      expect(yesterdayOrders.first.dishName, equals('昨日订单'));
    });
  });
}