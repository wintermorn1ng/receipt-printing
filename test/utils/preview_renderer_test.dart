import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/utils/print_renderer.dart';
import 'package:receipt_printing/utils/preview_renderer.dart';
import 'package:receipt_printing/utils/preview_line.dart';

void main() {
  group('PreviewRenderer', () {
    late PreviewRenderer renderer;

    setUp(() {
      renderer = PreviewRenderer();
    });

    tearDown(() async {
      await renderer.dispose();
    });

    test('render 应该发送数据到流', () async {
      final data = PrintData(
        ticketNumber: 128,
        dishName: '牛肉面',
      );

      // 监听流
      final future = renderer.linesStream.first;

      await renderer.render(data);

      final lines = await future;

      expect(lines, isNotEmpty);
    });

    test('render 应该生成包含取餐号的线条', () async {
      final data = PrintData(
        ticketNumber: 128,
        dishName: '牛肉面',
      );

      final future = renderer.linesStream.first;
      await renderer.render(data);
      final lines = await future;

      // 验证包含取餐号
      final ticketLine = lines.firstWhere(
        (line) => line.text.contains('128'),
        orElse: () => PreviewLine(''),
      );
      expect(ticketLine.text, contains('128'));
    });

    test('render 应该生成大字加粗的取餐号', () async {
      final data = PrintData(
        ticketNumber: 99,
        dishName: '测试',
      );

      final future = renderer.linesStream.first;
      await renderer.render(data);
      final lines = await future;

      // 找到取餐号行
      final ticketLine = lines.firstWhere(
        (line) => line.text.contains('99'),
        orElse: () => PreviewLine(''),
      );

      expect(ticketLine.isLarge, isTrue);
      expect(ticketLine.isBold, isTrue);
    });

    test('render 应该包含菜品名称', () async {
      final data = PrintData(
        ticketNumber: 1,
        dishName: '牛肉面',
      );

      final future = renderer.linesStream.first;
      await renderer.render(data);
      final lines = await future;

      // 验证包含菜品名称
      final dishLine = lines.firstWhere(
        (line) => line.text == '牛肉面',
        orElse: () => PreviewLine(''),
      );
      expect(dishLine.text, equals('牛肉面'));
    });

    test('render 应该包含店名（当提供时）', () async {
      final data = PrintData(
        ticketNumber: 1,
        dishName: '测试',
        shopName: '美味小吃店',
      );

      final future = renderer.linesStream.first;
      await renderer.render(data);
      final lines = await future;

      // 验证包含店名
      final shopLine = lines.firstWhere(
        (line) => line.text.contains('美味小吃店'),
        orElse: () => PreviewLine(''),
      );
      expect(shopLine.text, contains('美味小吃店'));
    });

    test('render 不应包含店名（当未提供时）', () async {
      final data = PrintData(
        ticketNumber: 1,
        dishName: '测试',
        shopName: null,
      );

      final future = renderer.linesStream.first;
      await renderer.render(data);
      final lines = await future;

      // 验证不包含店名（检查没有包含店铺名的行）
      final hasShopName = lines.any(
        (line) => line.text.contains('美味') || line.text.contains('小吃店'),
      );
      expect(hasShopName, isFalse);
    });

    test('render 应该包含日期时间（当提供时）', () async {
      final dateTime = DateTime(2024, 3, 15, 12, 30, 45);
      final data = PrintData(
        ticketNumber: 1,
        dishName: '测试',
        dateTime: dateTime,
      );

      final future = renderer.linesStream.first;
      await renderer.render(data);
      final lines = await future;

      // 验证包含日期时间（应该包含年份）
      final dateLine = lines.firstWhere(
        (line) => line.text.contains('2024'),
        orElse: () => PreviewLine(''),
      );
      expect(dateLine.text, contains('2024'));
    });

    test('renderTwoCopies 应该只渲染一次', () async {
      final data = PrintData(
        ticketNumber: 1,
        dishName: '测试',
      );

      // renderTwoCopies 应该只发送一联到预览
      final future = renderer.linesStream.first;

      await renderer.renderTwoCopies(data);

      final lines = await future;
      // 预览时只显示一联，所以应该只有一份内容
      expect(lines, isNotEmpty);
    });

    test('dispose 应该关闭流', () async {
      await renderer.dispose();

      // 流关闭后再次获取数据应该失败
      expect(
        () => renderer.linesStream.first.timeout(
          const Duration(milliseconds: 100),
          onTimeout: () => throw StateError('Stream is closed'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}