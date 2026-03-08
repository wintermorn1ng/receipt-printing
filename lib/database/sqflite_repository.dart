import 'package:sqflite/sqflite.dart' as sqflite;
import 'database_repository.dart';

/// SQLite 数据库仓库实现
///
/// 用于 IO 平台（iOS、Android、macOS、Linux、Windows）
class SqfliteRepository implements DatabaseRepository {
  sqflite.Database? _database;
  final String _dbName;
  final int _version;
  final Future<void> Function(sqflite.Database db, int version)? _onCreate;
  final Future<void> Function(sqflite.Database db, int oldVersion, int newVersion)?
      _onUpgrade;

  SqfliteRepository({
    String dbName = 'receipt_printing.db',
    int version = 1,
    Future<void> Function(sqflite.Database db, int version)? onCreate,
    Future<void> Function(sqflite.Database db, int oldVersion, int newVersion)?
        onUpgrade,
  })  : _dbName = dbName,
        _version = version,
        _onCreate = onCreate,
        _onUpgrade = onUpgrade;

  /// 获取数据库实例
  Future<sqflite.Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<sqflite.Database> _initDatabase() async {
    final databasesPath = await sqflite.getDatabasesPath();
    final path = '$databasesPath/$_dbName';

    return sqflite.openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return db.insert(table, values);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await database;
    return db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, arguments);
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final db = await database;
    return db.transaction((txn) => action(_SqfliteTransaction(txn)));
  }

  @override
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  @override
  Future<void> open() async {
    await database;
  }
}

/// Sqflite 事务包装类
class _SqfliteTransaction implements Transaction {
  final sqflite.Transaction _txn;

  _SqfliteTransaction(this._txn);

  @override
  Future<int> insert(String table, Map<String, dynamic> values) {
    return _txn.insert(table, values);
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  }) {
    return _txn.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _txn.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) {
    return _txn.delete(
      table,
      where: where,
      whereArgs: whereArgs,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) {
    return _txn.rawQuery(sql, arguments);
  }
}