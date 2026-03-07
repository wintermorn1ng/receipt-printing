import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/database/database_helper.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/database/order_dao.dart';
import 'package:receipt_printing/models/dish.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Tests', () {
    late DatabaseHelper dbHelper;
    late DishDao dishDao;
    late OrderDao orderDao;

    setUp(() async {
      dbHelper = DatabaseHelper();
      dishDao = DishDao();
      orderDao = OrderDao();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Database can be initialized', () async {
      final db = await dbHelper.database;
      expect(db, isNotNull);
      expect(db.isOpen, true);
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
