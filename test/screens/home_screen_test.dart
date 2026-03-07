import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/database/order_dao.dart';
import 'package:receipt_printing/providers/menu_provider.dart';
import 'package:receipt_printing/providers/order_provider.dart';
import 'package:receipt_printing/screens/home_screen.dart';
import 'package:receipt_printing/services/menu_service.dart';
import 'package:receipt_printing/services/order_service.dart';
import 'package:receipt_printing/services/ticket_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late DishDao dishDao;
  late OrderDao orderDao;
  late TicketService ticketService;
  late MenuService menuService;
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
          CREATE TABLE dishes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL,
            image_path TEXT,
            sort_order INTEGER DEFAULT 0,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
          )
        ''');
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
    dishDao = DishDao.withDatabase(db);
    orderDao = OrderDao.withDatabase(db);
    ticketService = TicketService.withDatabase(db);
    menuService = MenuService(dishDao);
    orderService = OrderService.forTest(orderDao, ticketService);
  });

  tearDown(() async {
    await db.close();
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MenuProvider>(
          create: (_) => MenuProvider(menuService),
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (_) => OrderProvider(orderService, ticketService),
        ),
      ],
      child: MaterialApp(
        home: const HomeScreen(),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('点单助手'), findsOneWidget);
    });

    testWidgets('should display ticket number in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('should display empty state when no dishes', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('暂无菜品'), findsOneWidget);
    });

    testWidgets('should display bottom navigation bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('点单'), findsOneWidget);
      expect(find.text('菜单管理'), findsOneWidget);
    });

    testWidgets('should show placeholder for print settings', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('打印设置'));
      await tester.pumpAndSettle();

      expect(find.text('打印设置功能开发中'), findsOneWidget);
    });

    testWidgets('should show placeholder for daily summary', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('日总结'));
      await tester.pumpAndSettle();

      expect(find.text('日总结功能开发中'), findsOneWidget);
    });
  });
}