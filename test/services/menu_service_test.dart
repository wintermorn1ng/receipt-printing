import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/services/menu_service.dart';
import 'package:receipt_printing/models/dish.dart' show Value;
import 'package:receipt_printing/models/dish.dart' show Value;

void main() {
  late Database db;
  late DishDao dishDao;
  late MenuService menuService;

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
      },
    );
    dishDao = DishDao.withDatabase(db);
    menuService = MenuService(dishDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('MenuService', () {
    group('getAllDishes', () {
      test('should return empty list when no dishes exist', () async {
        final result = await menuService.getAllDishes();
        expect(result, isEmpty);
      });

      test('should return all dishes sorted by sort_order', () async {
        // Arrange
        await menuService.addDish('牛肉面', 15.0, null);
        await menuService.addDish('炸酱面', 12.0, null);
        await menuService.addDish('豆浆', 3.0, null);

        // Act
        final result = await menuService.getAllDishes();

        // Assert
        expect(result.length, 3);
        expect(result[0].name, '牛肉面');
        expect(result[1].name, '炸酱面');
        expect(result[2].name, '豆浆');
      });
    });

    group('addDish', () {
      test('should add dish with only name', () async {
        final dish = await menuService.addDish('牛肉面', null, null);

        expect(dish.id, isNotNull);
        expect(dish.name, '牛肉面');
        expect(dish.price, isNull);
        expect(dish.imagePath, isNull);
      });

      test('should add dish with name and price', () async {
        final dish = await menuService.addDish('牛肉面', 15.5, null);

        expect(dish.price, 15.5);
      });

      test('should add dish with name, price and image path', () async {
        final dish = await menuService.addDish('牛肉面', 15.0, '/path/to/image.jpg');

        expect(dish.imagePath, '/path/to/image.jpg');
      });

      test('should throw exception when adding dish with empty name', () async {
        expect(
          () => menuService.addDish('', 15.0, null),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('updateDish', () {
      test('should update dish information', () async {
        // Arrange
        final dish = await menuService.addDish('牛肉面', 15.0, null);
        final updatedDish = dish.copyWith(name: '红烧牛肉面', price: Value(18.0));

        // Act
        await menuService.updateDish(updatedDish);

        // Assert
        final result = await menuService.getAllDishes();
        expect(result.first.name, '红烧牛肉面');
        expect(result.first.price, 18.0);
      });

      test('should throw exception when updating dish without id', () async {
        final dish = Dish(
          name: 'Test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(
          () => menuService.updateDish(dish),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('deleteDish', () {
      test('should delete dish by id', () async {
        // Arrange
        final dish = await menuService.addDish('牛肉面', 15.0, null);

        // Act
        await menuService.deleteDish(dish.id!);

        // Assert
        final result = await menuService.getAllDishes();
        expect(result, isEmpty);
      });

      test('should not throw when deleting non-existent dish', () async {
        expect(
          () => menuService.deleteDish(999),
          returnsNormally,
        );
      });
    });

    group('reorderDishes', () {
      test('should update sort order of dishes', () async {
        // Arrange
        final dish1 = await menuService.addDish('牛肉面', 15.0, null);
        final dish2 = await menuService.addDish('炸酱面', 12.0, null);
        final dish3 = await menuService.addDish('豆浆', 3.0, null);

        // Act - reorder: 豆浆, 牛肉面, 炸酱面
        final reorderedList = [dish3, dish1, dish2];
        await menuService.reorderDishes(reorderedList);

        // Assert
        final result = await menuService.getAllDishes();
        expect(result[0].name, '豆浆');
        expect(result[1].name, '牛肉面');
        expect(result[2].name, '炸酱面');
      });

      test('should handle empty list', () async {
        expect(
          () => menuService.reorderDishes([]),
          returnsNormally,
        );
      });
    });
  });
}
