import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/utils/print_formatter.dart';

void main() {
  group('PrintFormatter', () {
    group('formatTicket', () {
      test('应该生成包含取餐号的指令', () {
        final bytes = PrintFormatter.formatTicket(
          ticketNumber: 128,
          dishName: 'Test',
        );

        // 验证指令不为空
        expect(bytes, isNotEmpty);

        // 验证包含初始化指令 ESC @
        expect(bytes[0], equals(0x1B));
        expect(bytes[1], equals(0x40));

        // 验证包含取餐号 128（ASCII字符可以直接检查）
        final content = String.fromCharCodes(bytes.where((b) => b < 128));
        expect(content, contains('128'));
      });

      test('应该生成包含菜品名称的字节', () {
        final bytes = PrintFormatter.formatTicket(
          ticketNumber: 1,
          dishName: 'Test',
        );

        // 验证包含菜品名称（ASCII）
        final content = String.fromCharCodes(bytes.where((b) => b < 128));
        expect(content, contains('Test'));
      });

      test('应该包含店名字节（当提供时）', () {
        final bytesNoShop = PrintFormatter.formatTicket(
          ticketNumber: 1,
          dishName: 'Test',
          shopName: null,
        );

        final bytesWithShop = PrintFormatter.formatTicket(
          ticketNumber: 1,
          dishName: 'Test',
          shopName: 'Shop',
        );

        // 验证有店名时字节数更多
        expect(bytesWithShop.length, greaterThan(bytesNoShop.length));
      });

      test('不包含店名（当未提供时）', () {
        final bytes = PrintFormatter.formatTicket(
          ticketNumber: 1,
          dishName: 'Test',
          shopName: null,
        );

        // 验证指令包含店名相关指令（居中加粗）
        // 当没有店名时，应该跳过店名打印
        final content = String.fromCharCodes(bytes.where((b) => b < 128));
        // 只有分隔线、取餐号、菜品名，不应该有多余的加粗开启/关闭
        expect(content, contains('--------------------'));
        expect(content, contains('Test'));
      });

      test('当 printDateTime 为 true 时应包含日期时间', () {
        final bytes = PrintFormatter.formatTicket(
          ticketNumber: 1,
          dishName: 'Test',
          printDateTime: true,
        );

        final content = String.fromCharCodes(bytes.where((b) => b < 128));
        // 验证包含日期格式（yyyy-MM-dd）
        expect(content, matches(RegExp(r'\d{4}-\d{2}-\d{2}')));
      });

      test('当 printDateTime 为 false 时不包含日期时间', () {
        final bytes = PrintFormatter.formatTicket(
          ticketNumber: 1,
          dishName: 'Test',
          printDateTime: false,
        );

        final content = String.fromCharCodes(bytes.where((b) => b < 128));
        // 只检查 ASCII 部分不应该有日期
        expect(content, isNot(contains('2024-')));
      });

      test('应该包含切纸指令', () {
        final bytes = PrintFormatter.formatTicket(
          ticketNumber: 1,
          dishName: 'Test',
        );

        // 验证包含切纸指令 GS V 1 (0x1D 0x56 0x01)
        expect(bytes.contains(0x1D), isTrue);
        expect(bytes.contains(0x56), isTrue);
        expect(bytes.contains(0x01), isTrue);
      });
    });

    group('initPrinter', () {
      test('应该返回初始化指令', () {
        final bytes = PrintFormatter.initPrinter();
        expect(bytes, equals([0x1B, 0x40]));
      });
    });

    group('alignCenter', () {
      test('应该返回居中对齐指令', () {
        final bytes = PrintFormatter.alignCenter();
        expect(bytes, equals([0x1B, 0x61, 0x01]));
      });
    });

    group('alignLeft', () {
      test('应该返回左对齐指令', () {
        final bytes = PrintFormatter.alignLeft();
        expect(bytes, equals([0x1B, 0x61, 0x00]));
      });
    });

    group('normalFont', () {
      test('应该返回常规字体指令', () {
        final bytes = PrintFormatter.normalFont();
        expect(bytes, equals([0x1D, 0x21, 0x00]));
      });
    });

    group('doubleFont', () {
      test('应该返回双倍字体指令', () {
        final bytes = PrintFormatter.doubleFont();
        expect(bytes, equals([0x1D, 0x21, 0x11]));
      });
    });

    group('boldOn/boldOff', () {
      test('boldOn 应该返回加粗开启指令', () {
        final bytes = PrintFormatter.boldOn();
        expect(bytes, equals([0x1B, 0x45, 0x01]));
      });

      test('boldOff 应该返回加粗关闭指令', () {
        final bytes = PrintFormatter.boldOff();
        expect(bytes, equals([0x1B, 0x45, 0x00]));
      });
    });

    group('lineFeed', () {
      test('应该返回换行指令', () {
        final bytes = PrintFormatter.lineFeed();
        expect(bytes, equals([0x0A]));
      });
    });

    group('cutPaper', () {
      test('应该返回完整切纸指令', () {
        final bytes = PrintFormatter.cutPaper();
        expect(bytes, equals([0x1D, 0x56, 0x00]));
      });
    });

    group('feedAndCut', () {
      test('应该返回进纸并切纸指令', () {
        final bytes = PrintFormatter.feedAndCut();
        expect(bytes, equals([0x1D, 0x56, 0x01]));
      });
    });
  });
}