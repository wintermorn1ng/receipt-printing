import 'database_repository.dart';

/// 内存数据库仓库实现
///
/// 用于 Web 平台，使用内存 Map 模拟数据库
class InMemoryRepository implements DatabaseRepository {
  final Map<String, List<Map<String, dynamic>>> _tables = {};
  final Map<String, int> _autoIncrements = {};
  bool _isOpen = false;

  /// 初始化表结构
  void createTable(String tableName, {String? primaryKey}) {
    if (!_tables.containsKey(tableName)) {
      _tables[tableName] = [];
      _autoIncrements[tableName] = 0;
    }
  }

  /// 设置表数据（用于测试或初始化数据）
  void setTableData(String tableName, List<Map<String, dynamic>> data) {
    _tables[tableName] = List.from(data);
    if (data.isNotEmpty) {
      // 找到最大的 id 作为起始值
      int maxId = 0;
      for (var row in data) {
        if (row['id'] != null && row['id'] > maxId) {
          maxId = row['id'] as int;
        }
      }
      _autoIncrements[tableName] = maxId;
    } else {
      _autoIncrements[tableName] = 0;
    }
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    _ensureTableExists(table);
    final list = _tables[table]!;
    final currentId = _autoIncrements[table] ?? 0;
    _autoIncrements[table] = currentId + 1;
    final id = currentId + 1;
    final newRow = Map<String, dynamic>.from(values);
    newRow['id'] = id;
    list.add(newRow);
    return id;
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
    _ensureTableExists(table);
    var results = List<Map<String, dynamic>>.from(_tables[table]!);

    // 处理 WHERE 条件
    if (where != null && whereArgs != null) {
      results = _applyWhere(results, where, whereArgs);
    }

    // 处理排序
    if (orderBy != null && orderBy.isNotEmpty) {
      results = _applyOrderBy(results, orderBy);
    }

    // 处理列选择
    if (columns != null && columns.isNotEmpty) {
      results = results
          .map((row) => {
                for (var col in columns) if (row.containsKey(col)) col: row[col]
              })
          .toList();
    }

    // 处理 LIMIT
    if (limit != null && limit > 0) {
      results = results.take(limit).toList();
    }

    return results;
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    _ensureTableExists(table);
    var results = _tables[table]!;

    if (where != null && whereArgs != null) {
      final toUpdate = _applyWhere(results, where, whereArgs);
      final count = toUpdate.length;
      for (var row in toUpdate) {
        row.addAll(values);
      }
      return count;
    } else {
      // 更新所有行
      final count = results.length;
      for (var row in results) {
        row.addAll(values);
      }
      return count;
    }
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    _ensureTableExists(table);
    final list = _tables[table]!;

    if (where != null && whereArgs != null) {
      final toDelete = _applyWhere(list, where, whereArgs);
      final count = toDelete.length;
      for (var row in toDelete) {
        list.remove(row);
      }
      return count;
    } else {
      // 删除所有行
      final count = list.length;
      list.clear();
      return count;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    // 简化的 SQL 解析，仅支持基本查询
    final sqlLower = sql.toLowerCase().trim();

    // 处理 COUNT 查询
    if (sqlLower.startsWith('select count(*)')) {
      final match = RegExp(r'from\s+(\w+)').firstMatch(sqlLower);
      if (match != null) {
        final tableName = match.group(1)!;
        _ensureTableExists(tableName);
        var results = _tables[tableName]!;

        // 处理 WHERE 条件
        if (sqlLower.contains('where') && arguments != null) {
          final whereMatch = RegExp(r'where\s+(.+?)(?:\s+group|\s+order|\s+limit|$)',
                  caseSensitive: false)
              .firstMatch(sqlLower);
          if (whereMatch != null) {
            final where = whereMatch.group(1)!;
            results = _applyWhere(results, where, arguments);
          }
        }

        return [{'count': results.length}];
      }
    }

    // 处理 MAX 查询
    if (sqlLower.contains('max(')) {
      final tableMatch = RegExp(r'from\s+(\w+)').firstMatch(sqlLower);
      if (tableMatch != null) {
        final tableName = tableMatch.group(1)!;
        _ensureTableExists(tableName);
        final colMatch = RegExp(r'max\((\w+)\)').firstMatch(sqlLower);
        if (colMatch != null) {
          final colName = colMatch.group(1)!;
          final list = _tables[tableName]!;
          int? maxValue;
          for (var row in list) {
            if (row.containsKey(colName)) {
              final value = row[colName] as int?;
              if (value != null && (maxValue == null || value > maxValue)) {
                maxValue = value;
              }
            }
          }
          return [{'max': maxValue}];
        }
      }
    }

    // 处理 SELECT 查询
    if (sqlLower.startsWith('select')) {
      final tableMatch = RegExp(r'from\s+(\w+)').firstMatch(sqlLower);
      if (tableMatch != null) {
        final tableName = tableMatch.group(1)!;
        _ensureTableExists(tableName);
        var results = List<Map<String, dynamic>>.from(_tables[tableName]!);

        // 处理 WHERE 条件
        if (sqlLower.contains('where') && arguments != null) {
          final whereMatch = RegExp(
                  r'where\s+(.+?)(?:\s+group|\s+order|\s+limit|\s+as|$)',
                  caseSensitive: false)
              .firstMatch(sqlLower);
          if (whereMatch != null) {
            final where = whereMatch.group(1)!;
            results = _applyWhere(results, where, arguments);
          }
        }

        // 处理 GROUP BY
        if (sqlLower.contains('group by')) {
          final groupMatch =
              RegExp(r'group by\s+(\w+)', caseSensitive: false)
                  .firstMatch(sqlLower);
          if (groupMatch != null) {
            final groupCol = groupMatch.group(1)!;
            final grouped = <String, List<Map<String, dynamic>>>{};
            for (var row in results) {
              final key = row[groupCol]?.toString() ?? '';
              grouped.putIfAbsent(key, () => []).add(row);
            }
            // 聚合计算
            final countMatch =
                RegExp(r'count\(\*\)', caseSensitive: false).firstMatch(sqlLower);
            if (countMatch != null) {
              results = grouped.entries
                  .map((e) => {groupCol: e.key, 'count': e.value.length})
                  .toList();
            }
          }
        }

        // 处理 ORDER BY
        if (sqlLower.contains('order by')) {
          final orderMatch =
              RegExp(r'order by\s+(.+?)(?:\s+limit|\s+group|$)',
                      caseSensitive: false)
                  .firstMatch(sqlLower);
          if (orderMatch != null) {
            results = _applyOrderBy(results, orderMatch.group(1)!);
          }
        }

        // 处理 LIMIT
        if (sqlLower.contains('limit') && arguments != null) {
          final limitMatch =
              RegExp(r'limit\s+\?', caseSensitive: false).firstMatch(sqlLower);
          if (limitMatch != null && arguments.isNotEmpty) {
            final limit = arguments.last as int?;
            if (limit != null) {
              results = results.take(limit).toList();
            }
          }
        }

        return results;
      }
    }

    // 不支持的 SQL 类型
    throw UnimplementedError('Unsupported SQL: $sql');
  }

  @override
  Future<T> transaction<T>(
    Future<T> Function(Transaction txn) action,
  ) async {
    final txn = _InMemoryTransaction(this);
    return action(txn);
  }

  @override
  Future<void> close() async {
    _tables.clear();
    _autoIncrements.clear();
    _isOpen = false;
  }

  @override
  Future<void> open() async {
    _isOpen = true;
  }

  void _ensureTableExists(String table) {
    if (!_tables.containsKey(table)) {
      _tables[table] = [];
      _autoIncrements[table] = 0;
    }
  }

  List<Map<String, dynamic>> _applyWhere(
    List<Map<String, dynamic>> results,
    String where,
    List<Object?> args,
  ) {
    // 简单解析 WHERE 条件，支持 =, <, >, <=, >=, LIKE
    String processedWhere = where;

    // 处理 ? 占位符
    int argIndex = 0;
    processedWhere = processedWhere.replaceAllMapped(RegExp(r'\?'), (match) {
      final arg = args[argIndex++];
      if (arg is String) {
        return "'$arg'";
      }
      return arg?.toString() ?? 'NULL';
    });

    // 处理 AND
    final conditions = processedWhere.split(RegExp(r'\s+AND\s+', caseSensitive: false));

    return results.where((row) {
      for (var condition in conditions) {
        if (!_matchesCondition(row, condition.trim())) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool _matchesCondition(Map<String, dynamic> row, String condition) {
    // 处理 =
    var match = RegExp(r'(\w+)\s*=\s*(\S+)').firstMatch(condition);
    if (match != null) {
      final col = match.group(1)!;
      final value = _parseValue(match.group(2)!);
      return row[col] == value;
    }

    // 处理 !=
    match = RegExp(r'(\w+)\s*!=\s*(\S+)').firstMatch(condition);
    if (match != null) {
      final col = match.group(1)!;
      final value = _parseValue(match.group(2)!);
      return row[col] != value;
    }

    // 处理 LIKE
    match = RegExp(r'(\w+)\s+LIKE\s+(\S+)', caseSensitive: false).firstMatch(condition);
    if (match != null) {
      final col = match.group(1)!;
      final pattern = _parseValue(match.group(2)!).toString();
      final rowValue = row[col]?.toString() ?? '';
      final regexPattern = pattern.replaceAll('%', '.*');
      return RegExp(regexPattern).hasMatch(rowValue);
    }

    return true;
  }

  Object? _parseValue(String value) {
    if (value.startsWith("'") && value.endsWith("'")) {
      return value.substring(1, value.length - 1);
    }
    if (value.startsWith('"') && value.endsWith('"')) {
      return value.substring(1, value.length - 1);
    }
    final intValue = int.tryParse(value);
    if (intValue != null) return intValue;
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) return doubleValue;
    return value;
  }

  List<Map<String, dynamic>> _applyOrderBy(
    List<Map<String, dynamic>> results,
    String orderBy,
  ) {
    // 按逗号分割多个排序条件
    final orderByParts = orderBy.split(',');
    if (orderByParts.isEmpty) return results;

    // 处理第一个排序字段
    final firstPart = orderByParts[0].trim();
    final parts = firstPart.split(' ');
    if (parts.isEmpty) return results;

    final column = parts[0];
    final ascending = parts.length < 2 || parts[1].toLowerCase() == 'asc';

    final sorted = List<Map<String, dynamic>>.from(results);
    sorted.sort((a, b) {
      final aValue = a[column];
      final bValue = b[column];

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return ascending ? 1 : -1;
      if (bValue == null) return ascending ? -1 : 1;

      int comparison;
      if (aValue is int && bValue is int) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      // 如果相等，尝试使用后续排序字段
      if (comparison == 0 && orderByParts.length > 1) {
        // 递归处理后续字段（简化处理：只考虑第二个字段）
        final secondPart = orderByParts[1].trim();
        final secondParts = secondPart.split(' ');
        if (secondParts.isNotEmpty) {
          final secondColumn = secondParts[0];
          final secondAscending = secondParts.length < 2 || secondParts[1].toLowerCase() == 'asc';
          final aValue2 = a[secondColumn];
          final bValue2 = b[secondColumn];
          if (aValue2 != null && bValue2 != null) {
            int comparison2;
            if (aValue2 is int && bValue2 is int) {
              comparison2 = aValue2.compareTo(bValue2);
            } else {
              comparison2 = aValue2.toString().compareTo(bValue2.toString());
            }
            comparison = secondAscending ? comparison2 : -comparison2;
          }
        }
      }

      return ascending ? comparison : -comparison;
    });

    return sorted;
  }
}

/// 内存数据库事务实现
class _InMemoryTransaction implements Transaction {
  final InMemoryRepository _repository;

  _InMemoryTransaction(this._repository);

  @override
  Future<int> insert(String table, Map<String, dynamic> values) {
    return _repository.insert(table, values);
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
    return _repository.query(
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
    return _repository.update(
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
    return _repository.delete(
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
    return _repository.rawQuery(sql, arguments);
  }
}