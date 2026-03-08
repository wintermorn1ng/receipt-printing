import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/database/order_dao.dart';
import 'package:receipt_printing/database/in_memory_repository.dart';
import 'package:receipt_printing/models/dish.dart';

void main() {
  group('Database Tests', () {
    late InMemoryRepository repository;
    late DishDao dishDao;
    late OrderDao orderDao;

    setUp(() async {
      repository = InMemoryRepository();
      repository.createTable('dishes');
      repository.createTable('orders');
      repository.createTable('settings');
      dishDao = DishDao.withTestRepository(repository);
      orderDao = OrderDao.withTestRepository(repository);
    });

    test('Database can be initialized', () async {
      expect(repository, isNotNull);
    });

    test('Dish CRUD operations', () async {
      // Insert
      final dish = Dish(
        name: '测试菜品',
        price: 15.0,
        sortOrder: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final id = await dishDao.insert(dish);
      expect(id, greaterThan(0));

      // Get by ID
      final fetched = await dishDao.getById(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, '测试菜品');
      expect(fetched.price, 15.0);

      // Update
      final updated = fetched.copyWith(name: '更新后的菜品');
      final updateCount = await dishDao.update(updated);
      expect(updateCount, 1);

      // Delete
      final deleteCount = await dishDao.delete(id);
      expect(deleteCount, 1);

      // Verify deletion
      final deleted = await dishDao.getById(id);
      expect(deleted, isNull);
    });

    test('Order insert and query', () async {
      final now = DateTime.now();
      // 使用 order_dao.dart 导出的 Order 类
      final order = Order(
        ticketNumber: 1,
        dishId: 1,
        dishName: '牛肉面',
        createdAt: now,
      );

      final id = await orderDao.insert(order);
      expect(id, greaterThan(0));

      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final orders = await orderDao.getByDate(today);
      expect(orders.length, greaterThan(0));
    });
  });
}