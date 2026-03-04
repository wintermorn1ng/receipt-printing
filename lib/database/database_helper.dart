import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库帮助类
///
/// 使用单例模式管理 SQLite 数据库连接
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // 数据库版本号，用于升级管理
  static const int _version = 1;

  // 数据库名称
  static const String _dbName = 'receipt_printing.db';

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
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
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 后续版本升级时在此处理
    if (oldVersion < 2) {
      // 版本 1 升级到版本 2 的操作
    }
  }

  /// 关闭数据库连接
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
