import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:receipt_printing/database/order_dao.dart';
import 'package:receipt_printing/services/ticket_service.dart';
import 'package:receipt_printing/services/order_service.dart';
import 'package:receipt_printing/models/dish.dart';

void main() {
  late Database db;
  late OrderDao orderDao;
  late TicketService ticketService;
  late OrderService orderService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
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
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
    orderDao = OrderDao.withDatabase(db);
    ticketService = TicketService.withDatabase(db);
    orderService = OrderService.forTest(orderDao, ticketService);
  });

  tearDown(() async {
    await db.close();
  });

  group('OrderService', () {
    group('placeOrder', () {
      test('should create order with current ticket number', () async {
        // Arrange
        final dish = Dish(
          id: 1,
          name: '牛肉面',
          price: 15.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final order = await orderService.placeOrder(dish);

        // Assert
        expect(order.id, isNotNull);
        expect(order.ticketNumber, 1);
        expect(order.dishId, 1);
        expect(order.dishName, '牛肉面');
      });

      test('should increment ticket number after placing order', () async {
        // Arrange
        final dish = Dish(
          id: 1,
          name: '牛肉面',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await orderService.placeOrder(dish);
        final newTicketNumber = await ticketService.getCurrentTicketNumber();

        // Assert
        expect(newTicketNumber, 2);
      });

      test('should use correct ticket number for multiple orders', () async {
        // Arrange
        final dish1 = Dish(
          id: 1,
          name: '牛肉面',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final dish2 = Dish(
          id: 2,
          name: '炸酱面',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final order1 = await orderService.placeOrder(dish1);
        final order2 = await orderService.placeOrder(dish2);

        // Assert
        expect(order1.ticketNumber, 1);
        expect(order2.ticketNumber, 2);
      });

      test('should respect manually set ticket number', () async {
        // Arrange
        await ticketService.setTicketNumber(100);
        final dish = Dish(
          id: 1,
          name: '牛肉面',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        final order = await orderService.placeOrder(dish);

        // Assert
        expect(order.ticketNumber, 100);
      });
    });

    group('getTodayOrderCount', () {
      test('should return 0 when no orders exist', () async {
        final count = await orderService.getTodayOrderCount();
        expect(count, 0);
      });

      test('should return correct count for today orders', () async {
        // Arrange
        final dish = Dish(
          id: 1,
          name: '牛肉面',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await orderService.placeOrder(dish);
        await orderService.placeOrder(dish);
        final count = await orderService.getTodayOrderCount();

        // Assert
        expect(count, 2);
      });
    });

    group('getTodayOrders', () {
      test('should return empty list when no orders exist', () async {
        final orders = await orderService.getTodayOrders();
        expect(orders, isEmpty);
      });

      test('should return all orders for today', () async {
        // Arrange
        final dish1 = Dish(
          id: 1,
          name: '牛肉面',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final dish2 = Dish(
          id: 2,
          name: '炸酱面',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act
        await orderService.placeOrder(dish1);
        await orderService.placeOrder(dish2);
        final orders = await orderService.getTodayOrders();

        // Assert
        expect(orders.length, 2);
        expect(orders[0].dishName, '牛肉面');
        expect(orders[1].dishName, '炸酱面');
      });
    });
  });
}