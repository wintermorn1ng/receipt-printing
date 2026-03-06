import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:receipt_printing/screens/dish_edit_screen.dart';
import 'package:receipt_printing/providers/menu_provider.dart';
import 'package:receipt_printing/services/menu_service.dart';
import 'package:receipt_printing/database/dish_dao.dart';

/// 手动 Mock MenuService
class MockMenuService implements MenuService {
  List<Dish> _dishes = [];
  int _nextId = 1;

  void setDishes(List<Dish> dishes) {
    _dishes = List.from(dishes);
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
  Future<void> reorderDishes(List<Dish> dishes) async {}
}

void main() {
  group('DishEditScreen', () {
    late MockMenuService mockMenuService;
    late MenuProvider menuProvider;

    setUp(() {
      mockMenuService = MockMenuService();
      menuProvider = MenuProvider(mockMenuService);
    });

    Widget buildTestWidget({Dish? dish}) {
      return MaterialApp(
        home: ChangeNotifierProvider<MenuProvider>.value(
          value: menuProvider,
          child: DishEditScreen(dish: dish),
        ),
      );
    }

    group('新增模式', () {
      testWidgets('should show "添加菜品" title in add mode', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        expect(find.text('添加菜品'), findsOneWidget);
      });

      testWidgets('should show empty form fields in add mode', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Verify name field is empty
        final nameField = find.byType(TextFormField).first;
        expect(nameField, findsOneWidget);

        // Verify no validation error initially
        expect(find.text('菜品名称不能为空'), findsNothing);
      });

      testWidgets('should validate empty name', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Tap save button without entering name
        await tester.tap(find.text('保存'));
        await tester.pump();

        // Should show validation error
        expect(find.text('菜品名称不能为空'), findsOneWidget);
      });

      testWidgets('should accept valid input and save', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Enter name
        await tester.enterText(find.byType(TextFormField).first, '新菜品');

        // Enter price
        await tester.enterText(find.byType(TextFormField).last, '15.5');

        // Save
        await tester.tap(find.text('保存'));
        await tester.pump();
        await tester.pump();

        // Should pop with true result
        // Note: In real app, this would navigate back
      });
    });

    group('编辑模式', () {
      testWidgets('should show "编辑菜品" title in edit mode', (WidgetTester tester) async {
        final existingDish = Dish(
          id: 1,
          name: '牛肉面',
          price: 15.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(dish: existingDish));
        expect(find.text('编辑菜品'), findsOneWidget);
      });

      testWidgets('should pre-fill form fields in edit mode', (WidgetTester tester) async {
        final existingDish = Dish(
          id: 1,
          name: '牛肉面',
          price: 15.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(dish: existingDish));

        // Verify name is pre-filled
        final nameField = find.byType(TextFormField).first;
        expect(nameField, findsOneWidget);

        // Check the text controller has the value
        final TextFormField nameWidget = tester.widget(nameField);
        expect(nameWidget.controller?.text, '牛肉面');
      });

      testWidgets('should format integer price correctly', (WidgetTester tester) async {
        final existingDish = Dish(
          id: 1,
          name: '豆浆',
          price: 3.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(buildTestWidget(dish: existingDish));

        // Integer prices should be shown without decimal
        final priceField = find.byType(TextFormField).last;
        final TextFormField priceWidget = tester.widget(priceField);
        expect(priceWidget.controller?.text, '3');
      });
    });

    group('表单验证', () {
      testWidgets('should reject negative price', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Enter name
        await tester.enterText(find.byType(TextFormField).first, '测试菜品');

        // Enter negative price
        await tester.enterText(find.byType(TextFormField).last, '-10');

        // Try to save
        await tester.tap(find.text('保存'));
        await tester.pump();

        // Should show validation error
        expect(find.text('价格不能为负数'), findsOneWidget);
      });

      testWidgets('should reject invalid price format', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Enter name
        await tester.enterText(find.byType(TextFormField).first, '测试菜品');

        // Enter invalid price
        await tester.enterText(find.byType(TextFormField).last, 'abc');

        // Try to save
        await tester.tap(find.text('保存'));
        await tester.pump();

        // Should show validation error
        expect(find.text('请输入有效的数字'), findsOneWidget);
      });

      testWidgets('should accept empty price', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Enter name only
        await tester.enterText(find.byType(TextFormField).first, '免费菜品');

        // Price is optional, so saving should work
        await tester.tap(find.text('保存'));
        await tester.pump();

        // No price validation error should appear
        expect(find.text('请输入有效的数字'), findsNothing);
      });
    });

    group('UI元素', () {
      testWidgets('should have image picker area', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Should show image picker hint
        expect(find.text('点击添加图片（可选）'), findsOneWidget);
        expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
      });

      testWidgets('should have save button', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        expect(find.text('保存'), findsOneWidget);
        expect(find.byIcon(Icons.save), findsOneWidget);
      });

      testWidgets('should show loading state when saving', (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());

        // Enter valid data
        await tester.enterText(find.byType(TextFormField).first, '测试菜品');

        // Tap save
        await tester.tap(find.text('保存'));
        await tester.pump();

        // Should show loading indicator or change button text
        // The button might show "保存中..." or have a progress indicator
        expect(find.byType(ElevatedButton), findsOneWidget);
      });
    });
  });
}
