import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'database_repository.dart';
import 'sqflite_repository.dart';
import 'in_memory_repository.dart';

/// 数据库仓库工厂
///
/// 根据平台返回对应的数据库仓库实现
class DatabaseRepositoryFactory {
  /// 根据当前平台创建数据库仓库
  static DatabaseRepository create() {
    if (Platform.isIOS ||
        Platform.isAndroid ||
        Platform.isMacOS ||
        Platform.isLinux ||
        Platform.isWindows) {
      return SqfliteRepository(
        dbName: 'receipt_printing.db',
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } else {
      // Web 平台使用内存数据库
      final repository = InMemoryRepository();
      _initInMemoryTables(repository);
      return repository;
    }
  }

  /// 创建 SQLite 仓库（用于测试或明确的 IO 平台）
  static DatabaseRepository createSqflite() {
    return SqfliteRepository(
      dbName: 'receipt_printing.db',
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建内存仓库（用于 Web 平台或测试）
  static DatabaseRepository createInMemory() {
    final repository = InMemoryRepository();
    _initInMemoryTables(repository);
    return repository;
  }

  /// 初始化内存数据库的表结构
  static void _initInMemoryTables(InMemoryRepository repository) {
    repository.createTable('dishes');
    repository.createTable('orders');
    repository.createTable('settings');
  }

  /// 创建数据库表（SQLite）
  static Future<void> _onCreate(Database db, int version) async {
    // dishes 表 - 菜品信息
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

    // orders 表 - 订单记录
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ticket_number INTEGER NOT NULL,
        dish_id INTEGER NOT NULL,
        dish_name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // orders 表的日期索引，用于快速统计
    await db.execute('''
      CREATE INDEX idx_orders_date ON orders(date)
    ''');

    // settings 表 - 应用设置
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  /// 数据库升级
  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // 后续版本升级时在此处理
    if (oldVersion < 2) {
      // 版本 1 升级到版本 2 的操作
    }
  }
}

/// 全局默认数据库仓库单例
class _DefaultRepository {
  static DatabaseRepository? _instance;

  static Future<DatabaseRepository> getInstance() async {
    if (_instance != null) {
      await _instance!.open();
      return _instance!;
    }
    _instance = DatabaseRepositoryFactory.create();
    await _instance!.open();
    return _instance!;
  }
}

/// 获取默认数据库仓库
///
/// 这是 DAO 层获取默认仓库的推荐方式
Future<DatabaseRepository> getDefaultRepository() {
  return _DefaultRepository.getInstance();
}

/// 数据库帮助类（已废弃，请使用 DatabaseRepositoryFactory）
///
/// 使用单例模式管理 SQLite 数据库连接
/// [Deprecated] 使用 DatabaseRepositoryFactory.create() 代替
@Deprecated('请使用 DatabaseRepositoryFactory 创建数据库仓库')
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseRepository? _repository;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// 获取数据库仓库实例
  Future<DatabaseRepository> get repository async {
    _repository ??= DatabaseRepositoryFactory.create();
    await _repository!.open();
    return _repository!;
  }

  /// 获取数据库实例（已废弃）
  @Deprecated('请使用 repository 属性')
  Future<dynamic> get database async {
    return repository;
  }

  /// 关闭数据库连接
  Future<void> close() async {
    await _repository?.close();
    _repository = null;
  }
}