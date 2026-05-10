import 'dart:math';
import '../data/classical_poetry.dart';

/// 诗词服务
///
/// 根据当前日期/节气，从内置诗词库中选择适合的诗句。
/// 365 条精选诗句，来自唐诗三百首 + 宋词三百首。
///
/// 选诗策略：
/// - 按二十四节气/节日 tag 匹配（春/夏/秋/冬/festival）
/// - 同一 Tag 下避免连续重复
/// - 超出 Tag 范围时 fallback 到 general / blessing
class PoetryService {
  static final _random = Random();

  /// 上次选中的诗句索引（用于去重）
  int? _lastIndex;

  /// Tag → 诗句列表的缓存
  static final Map<String, List<ClassicalPoetry>> _tagPool =
      _buildTagPool();

  /// 按 tag 分组诗句
  static Map<String, List<ClassicalPoetry>> _buildTagPool() {
    final map = <String, List<ClassicalPoetry>>{};
    for (final poem in allPoems) {
      for (final tag in poem.tags) {
        map.putIfAbsent(tag, () => []).add(poem);
      }
    }
    return map;
  }

  /// 获取当前日期对应的季节 tag
  ///
  /// 二十四节气划分：
  /// - spring:  立春 → 谷雨（2月初-4月中）
  /// - summer:   立夏 → 大暑（5月初-7月中）
  /// - autumn:   立秋 → 霜降（8月初-10月中）
  /// - winter:   立冬 → 大寒（11月初-1月中）
  String _seasonalTagFor(DateTime date) {
    final month = date.month;
    final day = date.day;
    // 粗略按月份划分季节（兼顾节气边界）
    if ((month >= 2 && month <= 4)) return 'spring';
    if ((month >= 5 && month <= 7)) return 'summer';
    if ((month >= 8 && month <= 10)) return 'autumn';
    return 'winter'; // 11, 12, 1
  }

  /// 判断是否为传统节日（返回对应 tag，无则 null）
  String? _festivalTagFor(DateTime date) {
    final month = date.month;
    final day = date.day;
    // 农历节日按公历大致对应（使用常用日期）
    if (month == 1 && day >= 1 && day <= 3) return 'festival'; // 春节
    if (month == 2 && day >= 10 && day <= 12) return 'festival'; // 元宵
    if (month == 4 && day >= 4 && day <= 6) return 'festival'; // 清明
    if (month == 5 && day >= 5 && day <= 6) return 'festival'; // 端午
    if (month == 8 && day >= 15 && day <= 17) return 'festival'; // 中秋
    if (month == 9 && day >= 9 && day <= 10) return 'festival'; // 重阳
    if (month == 12 && day >= 29 && day <= 31) return 'festival'; // 除夕
    return null;
  }

  /// 获取今日诗句
  ///
  /// [date] 可指定日期，默认为当前日期。
  /// 优先使用节日 tag，其次季节 tag。
  ClassicalPoetry getPoem({DateTime? date}) {
    date ??= DateTime.now();

    // 1. 优先节日 tag
    final festivalTag = _festivalTagFor(date);
    if (festivalTag != null) {
      final poem = _pickFrom(festivalTag);
      if (poem != null) return poem;
    }

    // 2. 季节 tag
    final seasonTag = _seasonalTagFor(date);
    final poem = _pickFrom(seasonTag);
    if (poem != null) return poem;

    // 3. fallback: blessing
    final blessing = _pickFrom('blessing');
    if (blessing != null) return blessing;

    // 4. 最后 fallback: general
    return _pickFrom('general') ?? allPoems.first;
  }

  /// 从指定 tag 中随机选一条（避免连续重复）
  ClassicalPoetry? _pickFrom(String tag) {
    final pool = _tagPool[tag];
    if (pool == null || pool.isEmpty) return null;

    if (pool.length == 1) return pool.first;

    // 避免连续两次选到同一首诗
    int idx;
    do {
      idx = _random.nextInt(pool.length);
    } while (_lastIndex == idx && pool.length > 1);

    _lastIndex = idx;
    return pool[idx];
  }

  /// 获取当前季节 tag
  String get currentSeasonTag => _seasonalTagFor(DateTime.now());

  /// 获取当前是否有节日
  bool get isFestivalDay => _festivalTagFor(DateTime.now()) != null;
}
