import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../models/order.dart';
import '../models/printer_config.dart';
import '../services/print_service.dart';

/// 打印机状态管理 Provider
///
/// 管理蓝牙设备搜索、连接和打印配置
class PrinterProvider extends ChangeNotifier {
  final PrintService _printService;

  List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  bool _isConnecting = false;
  PrinterConfig _config = PrinterConfig.defaultConfig;

  PrinterProvider(this._printService);

  /// 已发现的蓝牙设备列表
  List<BluetoothDevice> get devices => _devices;

  /// 是否正在搜索
  bool get isScanning => _isScanning;

  /// 是否正在连接
  bool get isConnecting => _isConnecting;

  /// 打印机配置
  PrinterConfig get config => _config;

  /// 是否已连接打印机
  bool get isConnected => _printService.isConnected;

  /// 当前连接的设备地址
  String? get connectedDeviceAddress => _config.deviceAddress;

  /// 加载保存的配置
  Future<void> loadConfig() async {
    _config = await _printService.getPrinterConfig();

    // 尝试自动连接
    if (_config.deviceAddress != null) {
      try {
        await _printService.connect(_config.deviceAddress!);
      } catch (e) {
        // 静默失败，不阻塞应用启动
        debugPrint('自动连接失败: $e');
      }
    }

    notifyListeners();
  }

  /// 搜索蓝牙设备
  Future<void> scanDevices() async {
    if (_isScanning) return;

    _isScanning = true;
    _devices = [];
    notifyListeners();

    try {
      // 获取已配对设备
      final bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();

      _devices = bondedDevices.where((device) {
        // 过滤掉没有地址的设备
        return device.address.isNotEmpty;
      }).toList();

      notifyListeners();
    } catch (e) {
      debugPrint('搜索蓝牙设备失败: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// 连接设备
  Future<bool> connect(BluetoothDevice device) async {
    if (_isConnecting) return false;

    _isConnecting = true;
    notifyListeners();

    try {
      final success = await _printService.connect(device.address);

      if (success) {
        // 保存配置
        _config = _config.copyWith(
          deviceAddress: Value(device.address),
          deviceName: Value(device.name ?? '未知设备'),
        );
        await _printService.savePrinterConfig(_config);
      }

      return success;
    } catch (e) {
      debugPrint('连接失败: $e');
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _printService.disconnect();
    notifyListeners();
  }

  /// 更新配置
  Future<void> updateConfig(PrinterConfig config) async {
    _config = config;
    await _printService.savePrinterConfig(config);
    notifyListeners();
  }

  /// 切换打印店名
  Future<void> togglePrintShopName(bool value) async {
    _config = _config.copyWith(printShopName: value);
    await _printService.savePrinterConfig(_config);
    notifyListeners();
  }

  /// 更新店名
  Future<void> updateShopName(String name) async {
    _config = _config.copyWith(shopName: Value(name));
    await _printService.savePrinterConfig(_config);
    notifyListeners();
  }

  /// 切换打印日期时间
  Future<void> togglePrintDateTime(bool value) async {
    _config = _config.copyWith(printDateTime: value);
    await _printService.savePrinterConfig(_config);
    notifyListeners();
  }

  /// 切换打印两联
  Future<void> togglePrintTwoCopies(bool value) async {
    _config = _config.copyWith(printTwoCopies: value);
    await _printService.savePrinterConfig(_config);
    notifyListeners();
  }

  /// 测试打印
  Future<void> testPrint() async {
    if (!isConnected) {
      throw Exception('请先连接打印机');
    }

    // 创建一个测试订单
    final testOrder = Order(
      ticketNumber: 999,
      dishId: 0,
      dishName: '测试菜品',
      createdAt: DateTime.now(),
    );

    await _printService.printTicket(testOrder, _config);
  }
}