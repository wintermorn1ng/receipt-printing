import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:receipt_printing/database/order_dao.dart';
import 'package:receipt_printing/models/daily_summary.dart';
import 'package:receipt_printing/services/summary_service.dart';

import 'summary_service_test.mocks.dart';

@GenerateMocks([OrderDao])
void main() {
  late MockOrderDao mockOrderDao;
  late SummaryService summaryService;

  setUp(() {
    mockOrderDao = MockOrderDao();
    summaryService = SummaryService.forTest(mockOrderDao);
  });

  group('SummaryService', () {
    group('getDailySummary', () {
      test('应该返回正确的日总结数据', () async {
        // Arrange
        final date = DateTime(2026, 3, 8);
        when(mockOrderDao.getOrderCountByDate('2026-03-08')).thenAnswer((_) async => 10);
        when(mockOrderDao.getDishCountByDate('2026-03-08')).thenAnswer((_) async => {
              '牛肉面': 5,
              '炸酱面': 3,
              '清蒸鱼': 2,
            });
        when(mockOrderDao.getHourlyDistribution('2026-03-08')).thenAnswer((_) async => {
              12: 4,
              18: 6,
            });

        // Act
        final summary = await summaryService.getDailySummary(date);

        // Assert
        expect(summary.totalOrders, 10);
        expect(summary.dishSummaries.length, 3);
        expect(summary.dishSummaries[0].dishName, '牛肉面');
        expect(summary.dishSummaries[0].count, 5);
        expect(summary.hourlyDistribution[12], 4);
        expect(summary.hourlyDistribution[18], 6);
      });

      test('应该按销量降序排列菜品', () async {
        // Arrange
        final date = DateTime(2026, 3, 8);
        when(mockOrderDao.getOrderCountByDate('2026-03-08')).thenAnswer((_) async => 3);
        when(mockOrderDao.getDishCountByDate('2026-03-08')).thenAnswer((_) async => {
              '牛肉面': 2,
              '炸酱面': 5,
              '清蒸鱼': 1,
            });
        when(mockOrderDao.getHourlyDistribution('2026-03-08')).thenAnswer((_) async => {});

        // Act
        final summary = await summaryService.getDailySummary(date);

        // Assert
        expect(summary.dishSummaries[0].dishName, '炸酱面');
        expect(summary.dishSummaries[1].dishName, '牛肉面');
        expect(summary.dishSummaries[2].dishName, '清蒸鱼');
      });

      test('无订单时应该返回空数据', () async {
        // Arrange
        final date = DateTime(2026, 3, 8);
        when(mockOrderDao.getOrderCountByDate('2026-03-08')).thenAnswer((_) async => 0);
        when(mockOrderDao.getDishCountByDate('2026-03-08')).thenAnswer((_) async => {});
        when(mockOrderDao.getHourlyDistribution('2026-03-08')).thenAnswer((_) async => {});

        // Act
        final summary = await summaryService.getDailySummary(date);

        // Assert
        expect(summary.totalOrders, 0);
        expect(summary.dishSummaries, isEmpty);
        expect(summary.hourlyDistribution, isEmpty);
      });

      test('应该正确处理数据库异常', () async {
        // Arrange
        final date = DateTime(2026, 3, 8);
        when(mockOrderDao.getOrderCountByDate('2026-03-08'))
            .thenThrow(Exception('数据库错误'));

        // Act & Assert
        expect(
          () => summaryService.getDailySummary(date),
          throwsException,
        );
      });
    });

    group('getAvailableDates', () {
      test('应该返回正确的日期列表', () async {
        // Arrange
        when(mockOrderDao.getAvailableDates())
            .thenAnswer((_) async => ['2026-03-08', '2026-03-07', '2026-03-06']);

        // Act
        final dates = await summaryService.getAvailableDates();

        // Assert
        expect(dates.length, 3);
        expect(dates[0], DateTime(2026, 3, 8));
        expect(dates[1], DateTime(2026, 3, 7));
        expect(dates[2], DateTime(2026, 3, 6));
      });

      test('空列表应该返回空结果', () async {
        // Arrange
        when(mockOrderDao.getAvailableDates()).thenAnswer((_) async => []);

        // Act
        final dates = await summaryService.getAvailableDates();

        // Assert
        expect(dates, isEmpty);
      });

      test('应该正确处理数据库异常', () async {
        // Arrange
        when(mockOrderDao.getAvailableDates())
            .thenThrow(Exception('获取日期列表失败'));

        // Act & Assert
        expect(
          () => summaryService.getAvailableDates(),
          throwsException,
        );
      });
    });
  });
}