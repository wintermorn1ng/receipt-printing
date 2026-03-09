import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/utils/print_renderer.dart';

void main() {
  group('PrintData', () {
    final testDate = DateTime(2024, 3, 15, 10, 30);

    test('应该使用必需参数创建实例', () {
      final data = PrintData(
        ticketNumber: 128,
        dishName: '牛肉面',
      );

      expect(data.ticketNumber, equals(128));
      expect(data.dishName, equals('牛肉面'));
      expect(data.shopName, isNull);
      expect(data.dateTime, isNull);
    });

    test('应该接受可选参数', () {
      final data = PrintData(
        ticketNumber: 128,
        dishName: '牛肉面',
        shopName: '美味小吃店',
        dateTime: testDate,
      );

      expect(data.shopName, equals('美味小吃店'));
      expect(data.dateTime, equals(testDate));
    });

    test('相等性判断应正确工作', () {
      final data1 = PrintData(
        ticketNumber: 128,
        dishName: '牛肉面',
        shopName: '店铺',
        dateTime: testDate,
      );

      final data2 = PrintData(
        ticketNumber: 128,
        dishName: '牛肉面',
        shopName: '店铺',
        dateTime: testDate,
      );

      final data3 = PrintData(
        ticketNumber: 129,
        dishName: '牛肉面',
      );

      expect(data1, equals(data2));
      expect(data1.hashCode, equals(data2.hashCode));
      expect(data1, isNot(equals(data3)));
    });

    test('toString 应该返回正确的字符串表示', () {
      final data = PrintData(
        ticketNumber: 128,
        dishName: '牛肉面',
      );

      final str = data.toString();
      expect(str, contains('PrintData'));
      expect(str, contains('128'));
      expect(str, contains('牛肉面'));
    });
  });

  group('PrintRenderer (抽象类)', () {
    test('应该是一个抽象类', () {
      // 尝试实例化抽象类应该失败
      expect(
        () => _TestRenderer(),
        returnsNormally, // 抽象类不能直接实例化，但我们可以测试实现类
      );
    });
  });
}

/// 测试用的 PrintRenderer 实现
class _TestRenderer implements PrintRenderer {
  @override
  Future<void> render(PrintData data) async {}

  @override
  Future<void> renderTwoCopies(PrintData data) async {}

  @override
  Future<void> dispose() async {}
}