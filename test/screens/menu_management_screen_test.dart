import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:receipt_printing/screens/menu_management_screen.dart';
import 'package:receipt_printing/providers/menu_provider.dart';
import 'package:receipt_printing/services/menu_service.dart';
import 'package:receipt_printing/database/dish_dao.dart';

/// 手动 Mock MenuService
class MockMenuService implements MenuService {
  List<Dish> _dishes = [];
  int _nextId = 1;

  void setDishes(List<Dish> dishes) {
    _dishes = List.from(dishes);
    for (final dish in dishes) {
      if (dish.id != null && dish.id! >= _nextId) {
        _nextId = dish.id! + 1;
      }
    }
  }

  @override
  Future<List<Dish>> getAllDishes() async => List.from(_dishes);

  @override
  Future<Dish> addDish(String name, double? price, String? imagePath) async {
    final dish = Dish(
      id: _nextId++,
      name: name,
      price: price,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _dishes.add(dish);
    return dish;
  }

  @override
  Future<void> updateDish(Dish dish) async {
    final index = _dishes.indexWhere((d) => d.id == dish.id);
    if (index != -1) {
      _dishes[index] = dish;
    }
  }

  @override
  Future<void> deleteDish(int id) async {
    _dishes.removeWhere((d) => d.id == id);
  }

  @override
  Future<void> reorderDishes(List<Dish> dishes) async {
    // Reorder the internal list to match
    final newOrder = <Dish>[];
    for (final dish in dishes) {
      final existing = _dishes.firstWhere((d) => d.id == dish.id);
      newOrder.add(existing);
    }
    _dishes = newOrder;
  }
}

void main() {
  group('MenuManagementScreen', () {
    late MockMenuService mockMenuService;
    late MenuProvider menuProvider;

    setUp(() {
      mockMenuService = MockMenuService();
      menuProvider = MenuProvider(mockMenuService);
    });

    Widget buildTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<MenuProvider>.value(
          value: menuProvider,
          child: const MenuManagementScreen(),
        ),
      );
    }

    group('初始加载', () {
      testWidgets('should show title and add button', (WidgetTester tester) async {
        mockMenuService.setDishes([]);
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('菜单管理'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });

      testWidgets('should show empty state when no dishes', (WidgetTester tester) async {
        mockMenuService.setDishes([]);
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
        expect(find.text('暂无菜品'), findsOneWidget);
        expect(find.textContaining('添加'), findsOneWidget);
      });

      testWidgets('should load and display dishes', (WidgetTester tester) async {
        mockMenuService.setDishes([
          Dish(
            id: 1,
            name: '牛肉面',
            price: 15.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Dish(
            id: 2,
            name: '炸酱面',
            price: 12.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('牛肉面'), findsOneWidget);
        expect(find.text('炸酱面'), findsOneWidget);
      });
    });

    group('菜品操作', () {
      testWidgets('should show options menu on long press', (WidgetTester tester) async {
        mockMenuService.setDishes([
          Dish(
            id: 1,
            name: '牛肉面',
            price: 15.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Long press on dish
        await tester.longPress(find.text('牛肉面'));
        await tester.pumpAndSettle();

        // Should show popup menu
        expect(find.text('编辑'), findsOneWidget);
        expect(find.text('删除'), findsOneWidget);
      });

      testWidgets('should show delete confirmation dialog', (WidgetTester tester) async {
        mockMenuService.setDishes([
          Dish(
            id: 1,
            name: '牛肉面',
            price: 15.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Long press on dish
        await tester.longPress(find.text('牛肉面'));
        await tester.pumpAndSettle();

        // Tap delete
        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.text('确认删除'), findsOneWidget);
        expect(find.textContaining('确定要删除'), findsOneWidget);
        expect(find.text('取消'), findsOneWidget);
        expect(find.text('删除'), findsAtLeast(1));
      });

      testWidgets('should delete dish after confirmation', (WidgetTester tester) async {
        mockMenuService.setDishes([
          Dish(
            id: 1,
            name: '牛肉面',
            price: 15.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Long press and delete
        await tester.longPress(find.text('牛肉面'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();

        // Confirm deletion - find the FilledButton with "删除" text in the dialog
        final deleteButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('删除'),
        );
        await tester.tap(deleteButton);
        await tester.pump();

        // Dish should be deleted
        expect(find.text('牛肉面'), findsNothing);
      });

      testWidgets('should cancel delete when canceled', (WidgetTester tester) async {
        mockMenuService.setDishes([
          Dish(
            id: 1,
            name: '牛肉面',
            price: 15.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Long press and delete
        await tester.longPress(find.text('牛肉面'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('删除'));
        await tester.pumpAndSettle();

        // Cancel deletion
        await tester.tap(find.widgetWithText(TextButton, '取消'));
        await tester.pump();

        // Dish should still exist
        expect(find.text('牛肉面'), findsOneWidget);
      });
    });

    group('导航', () {
      testWidgets('should navigate to add screen when FAB tapped', (WidgetTester tester) async {
        mockMenuService.setDishes([]);
        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Tap add button
        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        // Should navigate to edit screen
        expect(find.text('添加菜品'), findsOneWidget);
      });

      testWidgets('should navigate to edit screen from menu', (WidgetTester tester) async {
        mockMenuService.setDishes([
          Dish(
            id: 1,
            name: '牛肉面',
            price: 15.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        // Long press and edit
        await tester.longPress(find.text('牛肉面'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('编辑'));
        await tester.pumpAndSettle();

        // Should navigate to edit screen with pre-filled data
        expect(find.text('编辑菜品'), findsOneWidget);
      });
    });

    group('网格布局', () {
      testWidgets('should use GridView for layout', (WidgetTester tester) async {
        mockMenuService.setDishes([
          Dish(id: 1, name: 'A', createdAt: DateTime.now(), updatedAt: DateTime.now()),
          Dish(id: 2, name: 'B', createdAt: DateTime.now(), updatedAt: DateTime.now()),
          Dish(id: 3, name: 'C', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        ]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('should display prices correctly', (WidgetTester tester) async {
        mockMenuService.setDishes([
          Dish(
            id: 1,
            name: '牛肉面',
            price: 15.5,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Dish(
            id: 2,
            name: '免费汤',
            price: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(buildTestWidget());
        await tester.pump();

        expect(find.text('¥15.5'), findsOneWidget);
        // Free soup should not show price
        expect(find.text('免费汤'), findsOneWidget);
      });
    });
  });
}
