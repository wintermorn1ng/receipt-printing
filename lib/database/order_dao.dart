import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

/// 订单数据模型
class Order {
  final int? id;
  final int ticketNumber;
  final int dishId;
  final String dishName;
  final DateTime createdAt;

  Order({
    this.id,
    required this.ticketNumber,
    required this.dishId,
    required this.dishName,
    required this.createdAt,
  });

  /// 从数据库 Map 转换为 Order 对象
  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as int?,
      ticketNumber: map['ticket_number'] as int,
      dishId: map['dish_id'] as int,
      dishName: map['dish_name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// 将 Order 对象转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'ticket_number': ticketNumber,
      'dish_id': dishId,
      'dish_name': dishName,
      'created_at': createdAt.millisecondsSinceEpoch,
      'date': _formatDate(createdAt),
    };
  }

  /// 格式化日期为 YYYY-MM-DD
  static String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// 创建副本并更新指定字段
  Order copyWith({
    int? id,
    int? ticketNumber,
    int? dishId,
    String? dishName,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      dishId: dishId ?? this.dishId,
      dishName: dishName ?? this.dishName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Order(id: $id, ticketNumber: $ticketNumber, dishId: $dishId, '
        'dishName: $dishName, createdAt: $createdAt)';
  }
}

/// 订单数据访问对象
class OrderDao {
  final DatabaseHelper? _dbHelper;
  final Database? _testDb;

  static const String _tableName = 'orders';

  /// 构造函数 - 使用默认数据库
  OrderDao() : _dbHelper = DatabaseHelper(), _testDb = null;

  /// 构造函数 - 使用测试数据库
  @visibleForTesting
  OrderDao.withDatabase(Database db) : _dbHelper = null, _testDb = db;

  /// 获取数据库实例
  Future<Database> get _database async {
    if (_testDb != null) return _testDb!;
    return _dbHelper!.database;
  }

  /// 插入新订单
  ///
  /// 返回插入记录的 ID
  Future<int> insert(Order order) async {
    try {
      final db = await _database;
      return await db.insert(_tableName, order.toMap());
    } catch (e) {
      throw Exception('插入订单失败: $e');
    }
  }

  /// 获取某日的所有订单
  ///
  /// [date] 格式: YYYY-MM-DD
  Future<List<Order>> getByDate(String date) async {
    try {
      final db = await _database;
      final maps = await db.query(
        _tableName,
        where: 'date = ?',
        whereArgs: [date],
        orderBy: 'created_at ASC',
      );
      return maps.map((map) => Order.fromMap(map)).toList();
    } catch (e) {
      throw Exception('获取订单列表失败: $e');
    }
  }

  /// 获取某日的订单数量
  ///
  /// [date] 格式: YYYY-MM-DD
  Future<int> getOrderCountByDate(String date) async {
    try {
      final db = await _database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE date = ?',
        [date],
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e) {
      throw Exception('获取订单数量失败: $e');
    }
  }

  /// 获取某日各菜品的销量统计
  ///
  /// 返回 Map: {菜品名称: 销量}
  /// [date] 格式: YYYY-MM-DD
  Future<Map<String, int>> getDishCountByDate(String date) async {
    try {
      final db = await _database;
      final result = await db.rawQuery(
        '''
        SELECT dish_name, COUNT(*) as count
        FROM $_tableName
        WHERE date = ?
        GROUP BY dish_name
        ORDER BY count DESC
        ''',
        [date],
      );
      return {
        for (var row in result)
          row['dish_name'] as String: (row['count'] as int?) ?? 0
      };
    } catch (e) {
      throw Exception('获取菜品销量统计失败: $e');
    }
  }

  /// 获取某日订单的时段分布
  ///
  /// 返回 Map: {小时(0-23): 订单数量}
  /// [date] 格式: YYYY-MM-DD
  Future<Map<int, int>> getHourlyDistribution(String date) async {
    try {
      final db = await _database;
      // 使用本地时间计算小时
      final result = await db.rawQuery(
        '''
        SELECT
          CAST(strftime('%H', datetime((created_at / 1000), 'unixepoch', 'localtime')) AS INTEGER) as hour,
          COUNT(*) as count
        FROM $_tableName
        WHERE date = ?
        GROUP BY hour
        ORDER BY hour
        ''',
        [date],
      );
      // 初始化所有小时为 0
      final distribution = {for (var i = 0; i < 24; i++) i: 0};
      // 填充实际数据
      for (var row in result) {
        final hour = row['hour'] as int;
        final count = (row['count'] as int?) ?? 0;
        distribution[hour] = count;
      }
      return distribution;
    } catch (e) {
      throw Exception('获取时段分布失败: $e');
    }
  }

  /// 获取某日的取餐号最大值
  ///
  /// [date] 格式: YYYY-MM-DD
  Future<int> getMaxTicketNumber(String date) async {
    try {
      final db = await _database;
      final result = await db.rawQuery(
        'SELECT MAX(ticket_number) as max FROM $_tableName WHERE date = ?',
        [date],
      );
      return (result.first['max'] as int?) ?? 0;
    } catch (e) {
      throw Exception('获取最大取餐号失败: $e');
    }
  }
}
