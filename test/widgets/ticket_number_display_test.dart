import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/widgets/ticket_number_display.dart';

void main() {
  group('TicketNumberDisplay', () {
    testWidgets('should display ticket number with # prefix', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketNumberDisplay(ticketNumber: 128),
          ),
        ),
      );

      expect(find.text('#128'), findsOneWidget);
    });

    testWidgets('should show popup menu on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketNumberDisplay(ticketNumber: 1),
          ),
        ),
      );

      // 点击组件打开菜单
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.text('重置为1'), findsOneWidget);
      expect(find.text('设置起始号'), findsOneWidget);
    });

    testWidgets('should show reset confirm dialog when reset is selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketNumberDisplay(ticketNumber: 100),
          ),
        ),
      );

      // 打开菜单
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 点击重置
      await tester.tap(find.text('重置为1'));
      await tester.pumpAndSettle();

      expect(find.text('确认重置'), findsOneWidget);
      expect(find.text('确定要将取餐号重置为1吗？'), findsOneWidget);
    });

    testWidgets('should call onReset when reset is confirmed', (tester) async {
      var resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketNumberDisplay(
              ticketNumber: 100,
              onReset: () => resetCalled = true,
            ),
          ),
        ),
      );

      // 打开菜单
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 点击重置
      await tester.tap(find.text('重置为1'));
      await tester.pumpAndSettle();

      // 点击确认
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(resetCalled, true);
    });

    testWidgets('should not call onReset when reset is cancelled', (tester) async {
      var resetCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketNumberDisplay(
              ticketNumber: 100,
              onReset: () => resetCalled = true,
            ),
          ),
        ),
      );

      // 打开菜单
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 点击重置
      await tester.tap(find.text('重置为1'));
      await tester.pumpAndSettle();

      // 点击取消
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(resetCalled, false);
    });

    testWidgets('should show set number dialog when set number is selected', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketNumberDisplay(ticketNumber: 100),
          ),
        ),
      );

      // 打开菜单
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 点击设置起始号
      await tester.tap(find.text('设置起始号'));
      await tester.pumpAndSettle();

      expect(find.text('设置起始号'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should call onSetNumber with valid input', (tester) async {
      int? setNumber;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketNumberDisplay(
              ticketNumber: 100,
              onSetNumber: (number) => setNumber = number,
            ),
          ),
        ),
      );

      // 打开菜单
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 点击设置起始号
      await tester.tap(find.text('设置起始号'));
      await tester.pumpAndSettle();

      // 输入数字
      await tester.enterText(find.byType(TextField), '50');
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(setNumber, 50);
    });

    testWidgets('should not call onSetNumber with invalid input', (tester) async {
      int? setNumber;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketNumberDisplay(
              ticketNumber: 100,
              onSetNumber: (number) => setNumber = number,
            ),
          ),
        ),
      );

      // 打开菜单
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 点击设置起始号
      await tester.tap(find.text('设置起始号'));
      await tester.pumpAndSettle();

      // 输入无效数字
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('确认'));
      await tester.pumpAndSettle();

      expect(setNumber, isNull);
    });

    testWidgets('should prefill text field with current ticket number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TicketNumberDisplay(ticketNumber: 128),
          ),
        ),
      );

      // 打开菜单
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 点击设置起始号
      await tester.tap(find.text('设置起始号'));
      await tester.pumpAndSettle();

      // 检查文本框内容
      expect(find.text('128'), findsOneWidget);
    });
  });
}