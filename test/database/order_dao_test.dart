import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:receipt_printing/database/order_dao.dart';

/// OrderDao 单元测试
///
/// 使用 sqflite_common_ffi 在桌面环境测试 SQLite 数据库
void main() {
  // 初始化 FFI
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('OrderDao Tests', () {
    late Database db;
    late OrderDao orderDao;

    setUp(() async {
      // 每个测试使用独立的数据库实例
      final dbPath = inMemoryDatabasePath;
      db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE orders (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ticket_number INTEGER NOT NULL,
              dish_id INTEGER NOT NULL,
              dish_name TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              date TEXT NOT NULL
            )
          ''');
          await db.execute('CREATE INDEX idx_orders_date ON orders(date)');
        },
      );
      orderDao = OrderDao.withDatabase(db);
    });

    tearDown(() async {
      await db.close();
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
      final id = await orderDao.insert(order);
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

    test('获取时段分布', () async {
      // Arrange - 使用本地时间创建订单
      final baseDate = DateTime(2024, 3, 15);
      final orders = [
        Order(ticketNumber: 1, dishId: 1, dishName: '早餐', createdAt: baseDate.add(const Duration(hours: 8))),
        Order(ticketNumber: 2, dishId: 1, dishName: '早餐', createdAt: baseDate.add(const Duration(hours: 8, minutes: 30))),
        Order(ticketNumber: 3, dishId: 1, dishName: '午餐', createdAt: baseDate.add(const Duration(hours: 12))),
        Order(ticketNumber: 4, dishId: 1, dishName: '晚餐', createdAt: baseDate.add(const Duration(hours: 18))),
      ];

      // Act
      for (final order in orders) {
        await orderDao.insert(order);
      }
      final distribution = await orderDao.getHourlyDistribution('2024-03-15');

      // Assert - 验证本地时间的小时数
      expect(distribution[8], equals(2));  // 8点有2单
      expect(distribution[12], equals(1)); // 12点有1单
      expect(distribution[18], equals(1)); // 18点有1单
      expect(distribution[0], equals(0));  // 0点没有单
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
