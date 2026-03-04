import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// 菜品数据模型
class Dish {
  final int? id;
  final String name;
  final double? price;
  final String? imagePath;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  Dish({
    this.id,
    required this.name,
    this.price,
    this.imagePath,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从数据库 Map 转换为 Dish 对象
  factory Dish.fromMap(Map<String, dynamic> map) {
    return Dish(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: map['price'] as double?,
      imagePath: map['image_path'] as String?,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// 将 Dish 对象转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'image_path': imagePath,
      'sort_order': sortOrder,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// 复制 Dish 对象并修改部分字段
  Dish copyWith({
    int? id,
    String? name,
    double? price,
    String? imagePath,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Dish(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// 菜品数据访问对象
class DishDao {
  final DatabaseHelper? _dbHelper;
  final Database? _testDb;

  static const String _tableName = 'dishes';

  /// 构造函数 - 使用默认数据库
  DishDao() : _dbHelper = DatabaseHelper(), _testDb = null;

  /// 构造函数 - 使用测试数据库
  @visibleForTesting
  DishDao.withDatabase(Database db) : _dbHelper = null, _testDb = db;

  /// 获取数据库实例
  Future<Database> get _database async {
    if (_testDb != null) return _testDb!;
    return _dbHelper!.database;
  }

  /// 获取所有菜品，按 sort_order 排序
  Future<List<Dish>> getAll() async {
    try {
      final db = await _database;
      final maps = await db.query(
        _tableName,
        orderBy: 'sort_order ASC, id ASC',
      );
      return maps.map((map) => Dish.fromMap(map)).toList();
    } catch (e) {
      throw Exception('获取菜品列表失败: $e');
    }
  }

  /// 根据 ID 获取菜品
  Future<Dish?> getById(int id) async {
    try {
      final db = await _database;
      final maps = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Dish.fromMap(maps.first);
    } catch (e) {
      throw Exception('获取菜品详情失败: $e');
    }
  }

  /// 插入新菜品
  ///
  /// 返回插入记录的 ID
  Future<int> insert(Dish dish) async {
    try {
      final db = await _database;
      final now = DateTime.now();
      final dishToInsert = dish.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      return await db.insert(_tableName, dishToInsert.toMap());
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
      final db = await _database;
      final dishToUpdate = dish.copyWith(updatedAt: DateTime.now());
      return await db.update(
        _tableName,
        dishToUpdate.toMap(),
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
      final db = await _database;
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
      final db = await _database;
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
