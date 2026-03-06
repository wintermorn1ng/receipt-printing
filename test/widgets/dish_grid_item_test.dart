import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/widgets/dish_grid_item.dart';
import 'package:receipt_printing/database/dish_dao.dart';

void main() {
  group('DishGridItem', () {
    testWidgets('should display dish name', (WidgetTester tester) async {
      // Arrange
      final dish = Dish(
        id: 1,
        name: '牛肉面',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishGridItem(dish: dish),
          ),
        ),
      );

      // Assert
      expect(find.text('牛肉面'), findsOneWidget);
    });

    testWidgets('should display price when available', (WidgetTester tester) async {
      // Arrange
      final dish = Dish(
        id: 1,
        name: '牛肉面',
        price: 15.5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishGridItem(dish: dish),
          ),
        ),
      );

      // Assert
      expect(find.text('¥15.5'), findsOneWidget);
    });

    testWidgets('should not display price when null', (WidgetTester tester) async {
      // Arrange
      final dish = Dish(
        id: 1,
        name: '免费汤',
        price: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishGridItem(dish: dish),
          ),
        ),
      );

      // Assert
      expect(find.text('免费汤'), findsOneWidget);
      expect(find.textContaining('¥'), findsNothing);
    });

    testWidgets('should display integer price without decimal', (WidgetTester tester) async {
      // Arrange
      final dish = Dish(
        id: 1,
        name: '豆浆',
        price: 3.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishGridItem(dish: dish),
          ),
        ),
      );

      // Assert - should show "¥3" not "¥3.0"
      expect(find.text('¥3'), findsOneWidget);
    });

    testWidgets('should show placeholder when no image', (WidgetTester tester) async {
      // Arrange
      final dish = Dish(
        id: 1,
        name: '牛肉面',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishGridItem(dish: dish),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (WidgetTester tester) async {
      // Arrange
      bool tapped = false;
      final dish = Dish(
        id: 1,
        name: '牛肉面',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishGridItem(
              dish: dish,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DishGridItem));

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('should call onLongPress when long pressed', (WidgetTester tester) async {
      // Arrange
      bool longPressed = false;
      final dish = Dish(
        id: 1,
        name: '牛肉面',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishGridItem(
              dish: dish,
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(DishGridItem));

      // Assert
      expect(longPressed, isTrue);
    });

    testWidgets('should have elevated appearance when dragging', (WidgetTester tester) async {
      // Arrange
      final dish = Dish(
        id: 1,
        name: '牛肉面',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DishGridItem(
              dish: dish,
              isDragging: true,
            ),
          ),
        ),
      );

      // Assert - verify the widget builds without error
      expect(find.byType(DishGridItem), findsOneWidget);
      expect(find.text('牛肉面'), findsOneWidget);
    });

    testWidgets('should truncate long names', (WidgetTester tester) async {
      // Arrange
      final dish = Dish(
        id: 1,
        name: '这是一个非常长的菜品名称应该被截断',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: DishGridItem(dish: dish),
            ),
          ),
        ),
      );

      // Assert - widget should render without overflow error
      expect(find.text('这是一个非常长的菜品名称应该被截断'), findsOneWidget);
    });
  });
}
