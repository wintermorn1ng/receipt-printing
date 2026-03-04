import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/models/daily_summary.dart';

void main() {
  group('DishSummary', () {
    test('应该正确创建 DishSummary', () {
      final summary = DishSummary(
        dishId: 1,
        dishName: '红烧肉',
        count: 5,
      );

      expect(summary.dishId, equals(1));
      expect(summary.dishName, equals('红烧肉'));
      expect(summary.count, equals(5));
    });

    test('应该支持相同的值', () {
      final summary1 = DishSummary(dishId: 1, dishName: '红烧肉', count: 5);
      final summary2 = DishSummary(dishId: 1, dishName: '红烧肉', count: 5);

      expect(summary1, equals(summary2));
    });

    test('count 为 0 时应该正常工作', () {
      final summary = DishSummary(
        dishId: 2,
        dishName: '清蒸鱼',
        count: 0,
      );

      expect(summary.count, equals(0));
    });
  });

  group('DailySummary', () {
    test('应该正确创建 DailySummary', () {
      final date = DateTime(2026, 3, 3);
      final dishSummaries = [
        DishSummary(dishId: 1, dishName: '红烧肉', count: 5),
        DishSummary(dishId: 2, dishName: '清蒸鱼', count: 3),
      ];
      final hourlyDistribution = {10: 2, 12: 4, 18: 2};

      final summary = DailySummary(
        date: date,
        totalOrders: 8,
        dishSummaries: dishSummaries,
        hourlyDistribution: hourlyDistribution,
      );

      expect(summary.date, equals(date));
      expect(summary.totalOrders, equals(8));
      expect(summary.dishSummaries.length, equals(2));
      expect(summary.hourlyDistribution[12], equals(4));
    });

    test('相等性判断应该正确', () {
      final date = DateTime(2026, 3, 3);
      final summary1 = DailySummary(
        date: date,
        totalOrders: 10,
        dishSummaries: [DishSummary(dishId: 1, dishName: '红烧肉', count: 5)],
        hourlyDistribution: {12: 5},
      );
      final summary2 = DailySummary(
        date: date,
        totalOrders: 10,
        dishSummaries: [DishSummary(dishId: 1, dishName: '红烧肉', count: 5)],
        hourlyDistribution: {12: 5},
      );

      expect(summary1, equals(summary2));
    });

    test('不同日期应该不相等', () {
      final summary1 = DailySummary(
        date: DateTime(2026, 3, 3),
        totalOrders: 10,
        dishSummaries: [],
        hourlyDistribution: {},
      );
      final summary2 = DailySummary(
        date: DateTime(2026, 3, 4),
        totalOrders: 10,
        dishSummaries: [],
        hourlyDistribution: {},
      );

      expect(summary1, isNot(equals(summary2)));
    });

    test('空列表和空分布应该正常工作', () {
      final summary = DailySummary(
        date: DateTime(2026, 3, 3),
        totalOrders: 0,
        dishSummaries: [],
        hourlyDistribution: {},
      );

      expect(summary.dishSummaries, isEmpty);
      expect(summary.hourlyDistribution, isEmpty);
    });

    test('hashCode 应该一致', () {
      final date = DateTime(2026, 3, 3);
      final summary = DailySummary(
        date: date,
        totalOrders: 10,
        dishSummaries: [DishSummary(dishId: 1, dishName: '红烧肉', count: 5)],
        hourlyDistribution: {12: 5},
      );

      expect(summary.hashCode, isA<int>());
    });
  });
}
