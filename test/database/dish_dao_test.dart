import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/database/in_memory_repository.dart';
import 'package:receipt_printing/models/dish.dart';

/// DishDao 单元测试
///
/// 使用 InMemoryRepository 在所有平台测试数据库操作
void main() {
  group('DishDao Tests', () {
    late InMemoryRepository repository;
    late DishDao dishDao;

    setUp(() async {
      // 每个测试使用独立的内存数据库实例
      repository = InMemoryRepository();
      repository.createTable('dishes');
      dishDao = DishDao.withTestRepository(repository);
    });

    test('插入菜品并获取', () async {
      // Arrange
      final dish = Dish(
        name: '牛肉面',
        price: 15.0,
        sortOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final id = await dishDao.insert(dish);
      final retrieved = await dishDao.getById(id);

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('牛肉面'));
      expect(retrieved.price, equals(15.0));
    });

    test('获取所有菜品按排序顺序', () async {
      // Arrange
      final dishes = [
        Dish(name: '豆浆', price: 3.0, sortOrder: 2, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Dish(name: '牛肉面', price: 15.0, sortOrder: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Dish(name: '炸酱面', price: 12.0, sortOrder: 1, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      // Act
      for (final dish in dishes) {
        await dishDao.insert(dish);
      }
      final allDishes = await dishDao.getAll();

      // Assert - 应该按 sort_order 排序
      expect(allDishes.length, equals(3));
      expect(allDishes[0].name, equals('牛肉面'));
      expect(allDishes[1].name, equals('炸酱面'));
      expect(allDishes[2].name, equals('豆浆'));
    });

    test('更新菜品信息', () async {
      // Arrange
      final dish = Dish(
        name: '牛肉面',
        price: 15.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final id = await dishDao.insert(dish);

      // Act
      final updated = Dish(
        id: id,
        name: '红烧牛肉面',
        price: 18.0,
        createdAt: dish.createdAt,
        updatedAt: DateTime.now(),
      );
      await dishDao.update(updated);
      final retrieved = await dishDao.getById(id);

      // Assert
      expect(retrieved!.name, equals('红烧牛肉面'));
      expect(retrieved.price, equals(18.0));
    });

    test('删除菜品', () async {
      // Arrange
      final dish = Dish(
        name: '测试菜品',
        price: 10.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final id = await dishDao.insert(dish);

      // Act
      final deletedCount = await dishDao.delete(id);
      final retrieved = await dishDao.getById(id);

      // Assert
      expect(deletedCount, equals(1));
      expect(retrieved, isNull);
    });

    test('批量更新排序', () async {
      // Arrange
      final dishes = [
        Dish(name: 'A', price: 1.0, sortOrder: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Dish(name: 'B', price: 2.0, sortOrder: 1, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        Dish(name: 'C', price: 3.0, sortOrder: 2, createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];
      final ids = <int>[];
      for (final dish in dishes) {
        ids.add(await dishDao.insert(dish));
      }

      // Act - 重新排序：C, A, B
      final reordered = [
        (await dishDao.getById(ids[2]))!,
        (await dishDao.getById(ids[0]))!,
        (await dishDao.getById(ids[1]))!,
      ];
      await dishDao.updateSortOrder(reordered);
      final allDishes = await dishDao.getAll();

      // Assert
      expect(allDishes[0].name, equals('C'));
      expect(allDishes[1].name, equals('A'));
      expect(allDishes[2].name, equals('B'));
      expect(allDishes[0].sortOrder, equals(0));
      expect(allDishes[1].sortOrder, equals(1));
      expect(allDishes[2].sortOrder, equals(2));
    });

    test('可选字段为空', () async {
      // Arrange - 只有名称，其他可选
      final dish = Dish(
        name: '免费试吃',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final id = await dishDao.insert(dish);
      final retrieved = await dishDao.getById(id);

      // Assert
      expect(retrieved!.price, isNull);
      expect(retrieved.imagePath, isNull);
    });
  });
}