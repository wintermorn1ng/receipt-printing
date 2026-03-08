import 'package:meta/meta.dart';
import '../database/database_repository.dart';
import '../database/database_helper.dart';

/// 取餐号管理服务
///
/// 使用 settings 表存储取餐号配置：
/// - current_ticket_number: 当前取餐号
/// - last_reset_date: 上次重置日期（YYYY-MM-DD）
class TicketService {
  final DatabaseRepository? _repository;
  final DatabaseRepository? _testRepository;

  static const String _keyCurrentTicketNumber = 'current_ticket_number';
  static const String _keyLastResetDate = 'last_reset_date';

  /// 构造函数 - 使用默认数据库
  TicketService() : _repository = null, _testRepository = null;

  /// 构造函数 - 使用指定的数据库仓库
  TicketService.withRepository(DatabaseRepository repository)
      : _repository = repository,
        _testRepository = null;

  /// 构造函数 - 使用测试仓库
  @visibleForTesting
  TicketService.withTestRepository(DatabaseRepository repository)
      : _testRepository = repository,
        _repository = null;

  /// 获取数据库仓库实例
  Future<DatabaseRepository> get _db async {
    if (_testRepository != null) return _testRepository;
    if (_repository != null) return _repository;
    return getDefaultRepository();
  }

  /// 获取当前取餐号
  ///
  /// 如果不存在则返回1
  Future<int> getCurrentTicketNumber() async {
    try {
      final db = await _db;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [_keyCurrentTicketNumber],
      );

      if (result.isEmpty) {
        return 1;
      }

      return int.parse(result.first['value'] as String);
    } catch (e) {
      throw Exception('获取取餐号失败: $e');
    }
  }

  /// 递增取餐号并返回新值
  ///
  /// 返回递增后的取餐号
  Future<int> incrementTicketNumber() async {
    try {
      final db = await _db;
      final currentNumber = await getCurrentTicketNumber();
      final newNumber = currentNumber + 1;

      await _upsertSetting(db, _keyCurrentTicketNumber, newNumber.toString());

      return newNumber;
    } catch (e) {
      throw Exception('递增取餐号失败: $e');
    }
  }

  /// 重置取餐号为1
  Future<void> resetTicketNumber() async {
    try {
      final db = await _db;
      await _upsertSetting(db, _keyCurrentTicketNumber, '1');
      await _updateLastResetDate(db);
    } catch (e) {
      throw Exception('重置取餐号失败: $e');
    }
  }

  /// 设置取餐号起始号
  ///
  /// [number] 要设置的取餐号，必须大于0
  Future<void> setTicketNumber(int number) async {
    if (number < 1) {
      throw ArgumentError('取餐号必须大于0');
    }

    try {
      final db = await _db;
      await _upsertSetting(db, _keyCurrentTicketNumber, number.toString());
    } catch (e) {
      throw Exception('设置取餐号失败: $e');
    }
  }

  /// 检查并执行每日重置
  ///
  /// 如果上次重置日期不是今天，则重置取餐号为1
  Future<void> checkDailyReset() async {
    try {
      final db = await _db;
      final today = _formatDate(DateTime.now());

      // 获取上次重置日期
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [_keyLastResetDate],
      );

      final lastResetDate = result.isEmpty ? null : result.first['value'] as String?;

      // 如果日期不同，执行重置
      if (lastResetDate != today) {
        await _upsertSetting(db, _keyCurrentTicketNumber, '1');
        await _upsertSetting(db, _keyLastResetDate, today);
      }
    } catch (e) {
      throw Exception('每日重置检查失败: $e');
    }
  }

  /// 获取上次重置日期
  ///
  /// 返回 YYYY-MM-DD 格式的日期字符串，如果不存在则返回 null
  Future<String?> getLastResetDate() async {
    try {
      final db = await _db;
      final result = await db.query(
        'settings',
        where: 'key = ?',
        whereArgs: [_keyLastResetDate],
      );

      if (result.isEmpty) {
        return null;
      }

      return result.first['value'] as String;
    } catch (e) {
      throw Exception('获取上次重置日期失败: $e');
    }
  }

  /// 插入或更新设置项
  Future<void> _upsertSetting(DatabaseRepository db, String key, String value) async {
    // 先查询是否存在
    final existing = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (existing.isEmpty) {
      // 不存在则插入
      await db.insert(
        'settings',
        {'key': key, 'value': value},
      );
    } else {
      // 存在则更新
      await db.update(
        'settings',
        {'key': key, 'value': value},
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }

  /// 更新上次重置日期为今天
  Future<void> _updateLastResetDate(DatabaseRepository db) async {
    final today = _formatDate(DateTime.now());
    await _upsertSetting(db, _keyLastResetDate, today);
  }

  /// 格式化日期为 YYYY-MM-DD
  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}