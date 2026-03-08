import 'dart:async';

/// 数据库仓库抽象接口
///
/// 定义 DAO 层需要的所有数据库操作
abstract class DatabaseRepository {
  /// 插入记录
  ///
  /// [table] 表名
  /// [values] 要插入的数据
  /// 返回插入记录的 ID
  Future<int> insert(String table, Map<String, dynamic> values);

  /// 查询记录
  ///
  /// [table] 表名
  /// [columns] 要查询的列，null 表示所有列
  /// [where] WHERE 条件
  /// [whereArgs] WHERE 参数
  /// [orderBy] 排序方式
  /// [limit] 限制返回数量
  /// 返回查询结果列表
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  });

  /// 更新记录
  ///
  /// [table] 表名
  /// [values] 要更新的数据
  /// [where] WHERE 条件
  /// [whereArgs] WHERE 参数
  /// 返回受影响的行数
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// 删除记录
  ///
  /// [table] 表名
  /// [where] WHERE 条件
  /// [whereArgs] WHERE 参数
  /// 返回受影响的行数
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// 执行原生 SQL 查询
  ///
  /// [sql] SQL 语句
  /// [arguments] SQL 参数
  /// 返回查询结果列表
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]);

  /// 执行事务
  ///
  /// [action] 事务回调，在回调中执行多个数据库操作
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action,
  );

  /// 关闭数据库连接
  Future<void> close();

  /// 打开数据库连接
  Future<void> open();
}

/// 事务句柄
///
/// 用于在事务中执行数据库操作
abstract class Transaction {
  /// 插入记录
  Future<int> insert(String table, Map<String, dynamic> values);

  /// 查询记录
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
    int? limit,
  });

  /// 更新记录
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// 删除记录
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  });

  /// 执行原生 SQL
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]);
}