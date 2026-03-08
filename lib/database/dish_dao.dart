import 'package:meta/meta.dart';
import 'database_repository.dart';
import 'database_helper.dart';
import '../models/dish.dart';
export '../models/dish.dart';

/// 菜品数据访问对象
class DishDao {
  final DatabaseRepository? _repository;
  final DatabaseRepository? _testRepository;

  static const String _tableName = 'dishes';

  /// 构造函数 - 使用默认数据库仓库
  DishDao() : _repository = null, _testRepository = null;

  /// 构造函数 - 使用指定的数据库仓库
  DishDao.withRepository(DatabaseRepository repository)
      : _repository = repository,
        _testRepository = null;

  /// 构造函数 - 使用测试仓库
  @visibleForTesting
  DishDao.withTestRepository(DatabaseRepository repository)
      : _testRepository = repository,
        _repository = null;

  /// 获取数据库仓库实例
  Future<DatabaseRepository> get _db async {
    if (_testRepository != null) return _testRepository;
    if (_repository != null) return _repository;
    // 使用全局单例仓库
    return getDefaultRepository();
  }

  /// 获取所有菜品，按 sort_order 排序
  Future<List<Dish>> getAll() async {
    try {
      final db = await _db;
      final maps = await db.query(
        _tableName,
        orderBy: 'sort_order ASC, id ASC',
      );
      return maps.map((map) => Dish.fromJson(map)).toList();
    } catch (e) {
      throw Exception('获取菜品列表失败: $e');
    }
  }

  /// 根据 ID 获取菜品
  Future<Dish?> getById(int id) async {
    try {
      final db = await _db;
      final maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Dish.fromJson(maps.first);
    } catch (e) {
      throw Exception('获取菜品详情失败: $e');
    }
  }

  /// 插入新菜品
  ///
  /// 返回插入记录的 ID
  Future<int> insert(Dish dish) async {
    try {
      final db = await _db;
      final now = DateTime.now();
      final dishToInsert = dish.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      return await db.insert(_tableName, dishToInsert.toJson());
    } catch (e) {
      throw Exception('插入菜品失败: $e');
    }
  }

  /// 更新菜品信息
  ///
  /// 返回受影响的行数
  Future<int> update(Dish dish) async {
    try {
      if (dish.id == null) {
        throw ArgumentError('更新操作需要 dish.id');
      }
      final db = await _db;
      final dishToUpdate = dish.copyWith(updatedAt: DateTime.now());
      return await db.update(
        _tableName,
        dishToUpdate.toJson(),
        where: 'id = ?',
        whereArgs: [dish.id],
      );
    } catch (e) {
      throw Exception('更新菜品失败: $e');
    }
  }

  /// 删除菜品
  ///
  /// 返回受影响的行数
  Future<int> delete(int id) async {
    try {
      final db = await _db;
      return await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('删除菜品失败: $e');
    }
  }

  /// 批量更新菜品排序
  ///
  /// 使用事务确保原子性
  Future<void> updateSortOrder(List<Dish> dishes) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        for (var i = 0; i < dishes.length; i++) {
          final dish = dishes[i];
          if (dish.id == null) continue;
          await txn.update(
            _tableName,
            {'sort_order': i, 'updated_at': DateTime.now().millisecondsSinceEpoch},
            where: 'id = ?',
            whereArgs: [dish.id],
          );
        }
      });
    } catch (e) {
      throw Exception('更新排序失败: $e');
    }
  }
}