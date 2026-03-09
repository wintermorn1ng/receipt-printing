import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/utils/preview_line.dart';

void main() {
  group('PreviewLine', () {
    test('应该使用默认参数创建实例', () {
      final line = PreviewLine('测试');

      expect(line.text, equals('测试'));
      expect(line.alignment, equals(TextAlign.center));
      expect(line.isLarge, isFalse);
      expect(line.isBold, isFalse);
    });

    test('应该接受自定义参数', () {
      final line = PreviewLine(
        '测试',
        alignment: TextAlign.left,
        isLarge: true,
        isBold: true,
      );

      expect(line.text, equals('测试'));
      expect(line.alignment, equals(TextAlign.left));
      expect(line.isLarge, isTrue);
      expect(line.isBold, isTrue);
    });

    test('相等性判断应正确工作', () {
      final line1 = PreviewLine('测试', isLarge: true);
      final line2 = PreviewLine('测试', isLarge: true);
      final line3 = PreviewLine('测试', isLarge: false);

      expect(line1, equals(line2));
      expect(line1.hashCode, equals(line2.hashCode));
      expect(line1, isNot(equals(line3)));
    });

    test('toString 应该返回正确的字符串表示', () {
      final line = PreviewLine('测试', alignment: TextAlign.right);

      final str = line.toString();
      expect(str, contains('PreviewLine'));
      expect(str, contains('测试'));
      expect(str, contains('TextAlign.right'));
    });
  });
}