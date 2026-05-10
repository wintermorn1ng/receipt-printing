import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printing/models/printer_config.dart';
import 'package:receipt_printing/models/order.dart';
import 'package:receipt_printing/providers/printer_provider.dart';
import 'package:receipt_printing/services/print_service.dart';
import 'package:receipt_printing/utils/print_renderer.dart';

class _MockPrintService implements PrintService {
  @override
  bool get isConnected => false;

  @override
  Future<PrinterConfig> getPrinterConfig() async =>
      PrinterConfig.defaultConfig;

  @override
  Future<void> savePrinterConfig(PrinterConfig config) async {}

  @override
  Future<bool> connect(String address) async => true;

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> printTicket(Order order, PrinterConfig config) async {}

  @override
  Future<void> printTwoCopies(Order order, PrinterConfig config) async {}

  @override
  Future<void> dispose() async {}

  @override
  void setRenderer(PrintRenderer renderer) {}

  @override
  PrintRenderer get renderer => throw UnimplementedError();
}

void main() {
  late PrinterProvider printerProvider;

  setUp(() {
    printerProvider = PrinterProvider(_MockPrintService());
  });

  group('PrinterProvider', () {
    group('initial state', () {
      test('should have empty devices list', () {
        expect(printerProvider.devices, isEmpty);
      });

      test('should not be scanning', () {
        expect(printerProvider.isScanning, false);
      });

      test('should not be connected', () {
        expect(printerProvider.isConnected, false);
      });

      test('should not be connecting', () {
        expect(printerProvider.isConnecting, false);
      });

      test('should not be connection error', () {
        expect(printerProvider.isConnectionError, false);
      });

      test('should have default config', () {
        expect(printerProvider.config, PrinterConfig.defaultConfig);
      });

      test('should have null saved address', () {
        expect(printerProvider.savedAddress, isNull);
      });
    });

    group('updateConfig', () {
      test('should update config and save', () async {
        final newConfig = PrinterConfig(
          deviceAddress: '00:11:22:33:44:55',
          deviceName: 'Test Printer',
          printShopName: false,
          shopName: 'New Shop',
          printDateTime: false,
          printTwoCopies: true,
        );

        await printerProvider.updateConfig(newConfig);

        expect(printerProvider.config.printShopName, false);
        expect(printerProvider.config.shopName, 'New Shop');
        expect(printerProvider.config.printDateTime, false);
        expect(printerProvider.config.printTwoCopies, true);
      });
    });

    group('togglePrintShopName', () {
      test('should toggle printShopName to true', () async {
        await printerProvider.togglePrintShopName(true);
        expect(printerProvider.config.printShopName, true);
      });

      test('should toggle printShopName to false', () async {
        await printerProvider.togglePrintShopName(false);
        expect(printerProvider.config.printShopName, false);
      });
    });

    group('updateShopName', () {
      test('should update shop name', () async {
        await printerProvider.updateShopName('My Restaurant');
        expect(printerProvider.config.shopName, 'My Restaurant');
      });
    });

    group('togglePrintDateTime', () {
      test('should toggle printDateTime to true', () async {
        await printerProvider.togglePrintDateTime(true);
        expect(printerProvider.config.printDateTime, true);
      });

      test('should toggle printDateTime to false', () async {
        await printerProvider.togglePrintDateTime(false);
        expect(printerProvider.config.printDateTime, false);
      });
    });

    group('togglePrintTwoCopies', () {
      test('should toggle printTwoCopies to true', () async {
        await printerProvider.togglePrintTwoCopies(true);
        expect(printerProvider.config.printTwoCopies, true);
      });

      test('should toggle printTwoCopies to false', () async {
        await printerProvider.togglePrintTwoCopies(false);
        expect(printerProvider.config.printTwoCopies, false);
      });
    });
  });
}
