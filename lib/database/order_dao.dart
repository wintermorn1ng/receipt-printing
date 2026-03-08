import 'package:meta/meta.dart';
import 'database_repository.dart';
import 'database_helper.dart';
import '../models/order.dart';

export '../models/order.dart';

/// 订单数据访问对象
class OrderDao {
  final DatabaseRepository? _repository;
  final DatabaseRepository? _testRepository;

  static const String _tableName = 'orders';

  /// 构造函数 - 使用默认数据库仓库
  OrderDao() : _repository = null, _testRepository = null;

  /// 构造函数 - 使用指定的数据库仓库
  OrderDao.withRepository(DatabaseRepository repository)
      : _repository = repository,
        _testRepository = null;

  /// 构造函数 - 使用测试仓库
  @visibleForTesting
  OrderDao.withTestRepository(DatabaseRepository repository)
      : _testRepository = repository,
        _repository = null;

  /// 获取数据库仓库实例
  Future<DatabaseRepository> get _db async {
    if (_testRepository != null) return _testRepository;
    if (_repository != null) return _repository;
    // 使用全局单例仓库
    return getDefaultRepository();
  }

  /// 插入新订单
  ///
  /// 返回插入记录的 ID
  Future<int> insert(Order order) async {
    try {
      final db = await _db;
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
      final db = await _db;
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
      final db = await _db;
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
      final db = await _db;
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
      final db = await _db;
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
      final db = await _db;
      final result = await db.rawQuery(
        'SELECT MAX(ticket_number) as max FROM $_tableName WHERE date = ?',
        [date],
      );
      return (result.first['max'] as int?) ?? 0;
    } catch (e) {
      throw Exception('获取最大取餐号失败: $e');
    }
  }

  /// 获取有订单的日期列表
  ///
  /// 返回所有有订单的日期（格式: YYYY-MM-DD），按日期降序排列
  Future<List<String>> getAvailableDates() async {
    try {
      final db = await _db;
      final result = await db.rawQuery(
        'SELECT DISTINCT date FROM $_tableName ORDER BY date DESC',
      );
      return result.map((row) => row['date'] as String).toList();
    } catch (e) {
      throw Exception('获取有订单日期列表失败: $e');
    }
  }
}