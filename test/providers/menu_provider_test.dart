import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/providers/menu_provider.dart';
import 'package:receipt_printing/services/menu_service.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/models/dish.dart' show Value;

/// 手动实现的 Mock MenuService
class MockMenuService implements MenuService {
  List<Dish> _dishes = [];
  int _nextId = 1;

  void setDishes(List<Dish> dishes) {
    _dishes = List.from(dishes);
    // Update nextId based on existing dishes
    for (final dish in dishes) {
      if (dish.id != null && dish.id! >= _nextId) {
        _nextId = dish.id! + 1;
      }
    }
  }

  @override
  Future<List<Dish>> getAllDishes() async {
    return List.from(_dishes);
  }

  @override
  Future<Dish> addDish(String name, double? price, String? imagePath) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('菜品名称不能为空');
    }
    final now = DateTime.now();
    final dish = Dish(
      id: _nextId++,
      name: name.trim(),
      price: price,
      imagePath: imagePath,
      createdAt: now,
      updatedAt: now,
    );
    _dishes.add(dish);
    return dish;
  }

  @override
  Future<void> updateDish(Dish dish) async {
    if (dish.id == null) {
      throw ArgumentError('更新操作需要 dish.id');
    }
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
    // In real implementation this updates sort_order in database
    // For mock, we just verify it's called with correct data
  }
}

void main() {
  late MockMenuService mockMenuService;
  late MenuProvider menuProvider;

  setUp(() {
    mockMenuService = MockMenuService();
    menuProvider = MenuProvider(mockMenuService);
  });

  group('MenuProvider', () {
    group('loadDishes', () {
      test('should load dishes and notify listeners', () async {
        // Arrange
        final dishes = [
          Dish(
            id: 1,
            name: '牛肉面',
            price: 15.0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
        mockMenuService.setDishes(dishes);

        // Act
        await menuProvider.loadDishes();

        // Assert
        expect(menuProvider.dishes.length, 1);
        expect(menuProvider.dishes.first.name, '牛肉面');
        expect(menuProvider.isLoading, false);
      });

      test('should handle loading state', () async {
        // Arrange
        mockMenuService.setDishes([]);

        // Act - check initial state
        expect(menuProvider.isLoading, false);

        // Start loading
        final future = menuProvider.loadDishes();
        expect(menuProvider.isLoading, true);

        await future;
        expect(menuProvider.isLoading, false);
      });
    });

    group('addDish', () {
      test('should add dish and reload list', () async {
        // Arrange
        mockMenuService.setDishes([]);
        await menuProvider.loadDishes();

        // Act
        await menuProvider.addDish(name: '新菜品', price: 10.0, imagePath: null);

        // Assert
        expect(menuProvider.dishes.length, 1);
        expect(menuProvider.dishes.first.name, '新菜品');
        expect(menuProvider.dishes.first.price, 10.0);
      });

      test('should throw error when adding dish with empty name', () async {
        // Act & Assert
        expect(
          () => menuProvider.addDish(name: '', price: 10.0, imagePath: null),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('updateDish', () {
      test('should update dish and reload list', () async {
        // Arrange
        final existingDish = Dish(
          id: 1,
          name: '原菜品',
          price: 10.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        mockMenuService.setDishes([existingDish]);
        await menuProvider.loadDishes();

        final updatedDish = existingDish.copyWith(name: '更新后的菜品', price: Value(20.0));

        // Act
        await menuProvider.updateDish(updatedDish);

        // Assert
        expect(menuProvider.dishes.first.name, '更新后的菜品');
        expect(menuProvider.dishes.first.price, 20.0);
      });
    });

    group('deleteDish', () {
      test('should delete dish and reload list', () async {
        // Arrange
        mockMenuService.setDishes([
          Dish(
            id: 1,
            name: '要删除的菜品',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);
        await menuProvider.loadDishes();
        expect(menuProvider.dishes.length, 1);

        // Act
        await menuProvider.deleteDish(1);

        // Assert
        expect(menuProvider.dishes, isEmpty);
      });
    });

    group('reorderDishes', () {
      test('should reorder dishes and persist changes', () async {
        // Arrange
        final dishes = [
          Dish(
            id: 1,
            name: '牛肉面',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Dish(
            id: 2,
            name: '炸酱面',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Dish(
            id: 3,
            name: '豆浆',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        // Initialize provider with dishes
        mockMenuService.setDishes(dishes);
        await menuProvider.loadDishes();

        // Act - move first item to last (oldIndex=0, newIndex=3)
        // Note: In ReorderableListView, when moving to end, newIndex equals list length
        await menuProvider.reorderDishes(oldIndex: 0, newIndex: 3);

        // Assert
        expect(menuProvider.dishes[0].name, '炸酱面');
        expect(menuProvider.dishes[1].name, '豆浆');
        expect(menuProvider.dishes[2].name, '牛肉面');
      });

      test('should handle reorder from higher to lower index', () async {
        // Arrange
        final dishes = [
          Dish(
            id: 1,
            name: '牛肉面',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Dish(
            id: 2,
            name: '炸酱面',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          Dish(
            id: 3,
            name: '豆浆',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        mockMenuService.setDishes(dishes);
        await menuProvider.loadDishes();

        // Act - move last item to first (oldIndex=2, newIndex=0)
        await menuProvider.reorderDishes(oldIndex: 2, newIndex: 0);

        // Assert
        expect(menuProvider.dishes[0].name, '豆浆');
        expect(menuProvider.dishes[1].name, '牛肉面');
        expect(menuProvider.dishes[2].name, '炸酱面');
      });
    });
  });
}
