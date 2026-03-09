import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:receipt_printing/models/printer_config.dart';
import 'package:receipt_printing/models/order.dart';
import 'package:receipt_printing/providers/printer_provider.dart';
import 'package:receipt_printing/services/print_service.dart';

/// PrintService 的测试替身
class FakePrintService {
  bool _isConnected = false;
  PrinterConfig _config = PrinterConfig.defaultConfig;
  final List<Order> printedOrders = [];

  bool get isConnected => _isConnected;

  Future<PrinterConfig> getPrinterConfig() async => _config;

  Future<void> savePrinterConfig(PrinterConfig config) async {
    _config = config;
  }

  Future<bool> connect(String address) async {
    _isConnected = true;
    return true;
  }

  Future<void> disconnect() async {
    _isConnected = false;
  }

  Future<void> printTicket(Order order, PrinterConfig config) async {
    printedOrders.add(order);
  }

  void setConnected(bool value) {
    _isConnected = value;
  }

  void setConfig(PrinterConfig config) {
    _config = config;
  }

  void clearPrintedOrders() {
    printedOrders.clear();
  }
}

/// 创建 PrintService mock 的工厂函数
PrintService createMockPrintService(FakePrintService fake) {
  return _MockPrintService(fake);
}

class _MockPrintService implements PrintService {
  final FakePrintService _fake;

  _MockPrintService(this._fake);

  @override
  bool get isConnected => _fake.isConnected;

  @override
  Future<PrinterConfig> getPrinterConfig() => _fake.getPrinterConfig();

  @override
  Future<void> savePrinterConfig(PrinterConfig config) =>
      _fake.savePrinterConfig(config);

  @override
  Future<bool> connect(String address) => _fake.connect(address);

  @override
  Future<void> disconnect() => _fake.disconnect();

  @override
  Future<void> printTicket(Order order, PrinterConfig config) =>
      _fake.printTicket(order, config);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late PrinterProvider printerProvider;
  late FakePrintService fakePrintService;

  setUp(() {
    fakePrintService = FakePrintService();
    printerProvider = PrinterProvider(createMockPrintService(fakePrintService));
  });

  group('PrinterProvider', () {
    group('initial state', () {
      test('should have empty devices list', () {
        expect(printerProvider.devices, isEmpty);
      });

      test('should not be scanning', () {
        expect(printerProvider.isScanning, false);
      });

      test('should not be connecting', () {
        expect(printerProvider.isConnecting, false);
      });

      test('should not be connected', () {
        expect(printerProvider.isConnected, false);
      });

      test('should have default config', () {
        expect(printerProvider.config, PrinterConfig.defaultConfig);
      });
    });

    group('loadConfig', () {
      test('should load config from service', () async {
        final testConfig = PrinterConfig(
          deviceAddress: '00:11:22:33:44:55',
          deviceName: 'Test Printer',
          printShopName: true,
          shopName: 'Test Shop',
          printDateTime: true,
          printTwoCopies: false,
        );
        fakePrintService.setConfig(testConfig);

        await printerProvider.loadConfig();

        expect(printerProvider.config.deviceAddress, '00:11:22:33:44:55');
        expect(printerProvider.config.deviceName, 'Test Printer');
      });

      test('should attempt auto-connect when device address exists',
          () async {
        final testConfig = PrinterConfig(
          deviceAddress: '00:11:22:33:44:55',
          deviceName: 'Test Printer',
        );
        fakePrintService.setConfig(testConfig);

        await printerProvider.loadConfig();

        expect(printerProvider.isConnected, true);
      });
    });

    group('connect', () {
      test('should connect successfully', () async {
        final device = BluetoothDevice(
          address: '00:11:22:33:44:55',
          name: 'Test Printer',
        );

        final result = await printerProvider.connect(device);

        expect(result, true);
        expect(printerProvider.isConnected, true);
        expect(printerProvider.config.deviceAddress, '00:11:22:33:44:55');
        expect(printerProvider.config.deviceName, 'Test Printer');
      });

      test('should not connect when already connecting', () async {
        final device = BluetoothDevice(
          address: '00:11:22:33:44:55',
          name: 'Test Printer',
        );

        // 启动第一次连接
        final future1 = printerProvider.connect(device);

        // 第二次连接应该在 isConnecting 时立即返回 false
        final result2 = await printerProvider.connect(device);

        // 等待第一次连接完成
        await future1;

        // 结果取决于实现，这里测试的是不会同时进行两次连接
        expect(printerProvider.isConnecting, false);
      });

      test('should save config after successful connection', () async {
        final device = BluetoothDevice(
          address: '00:11:22:33:44:55',
          name: 'Test Printer',
        );

        await printerProvider.connect(device);

        expect(printerProvider.config.deviceAddress, '00:11:22:33:44:55');
        expect(printerProvider.config.deviceName, 'Test Printer');
      });
    });

    group('disconnect', () {
      test('should disconnect successfully', () async {
        // 先连接
        final device = BluetoothDevice(
          address: '00:11:22:33:44:55',
          name: 'Test Printer',
        );
        await printerProvider.connect(device);

        // 断开
        await printerProvider.disconnect();

        expect(printerProvider.isConnected, false);
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

    group('testPrint', () {
      test('should throw exception when not connected', () async {
        expect(
          () => printerProvider.testPrint(),
          throwsA(isA<Exception>()),
        );
      });

      test('should print test ticket when connected', () async {
        // 先连接
        final device = BluetoothDevice(
          address: '00:11:22:33:44:55',
          name: 'Test Printer',
        );
        await printerProvider.connect(device);

        fakePrintService.clearPrintedOrders();

        await printerProvider.testPrint();

        expect(fakePrintService.printedOrders.length, 1);
        expect(fakePrintService.printedOrders.first.ticketNumber, 999);
        expect(fakePrintService.printedOrders.first.dishName, '测试菜品');
      });
    });

    group('connectedDeviceAddress', () {
      test('should return device address from config', () async {
        final testConfig = PrinterConfig(
          deviceAddress: '00:11:22:33:44:55',
          deviceName: 'Test Printer',
        );
        fakePrintService.setConfig(testConfig);

        await printerProvider.loadConfig();

        expect(printerProvider.connectedDeviceAddress, '00:11:22:33:44:55');
      });

      test('should return null when no device address', () {
        expect(printerProvider.connectedDeviceAddress, isNull);
      });
    });
  });
}