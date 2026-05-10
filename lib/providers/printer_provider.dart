import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';

import '../models/order.dart';
import '../models/printer_config.dart';
import '../services/print_service.dart';
import '../services/bluetooth_connection_manager.dart';

/// 打印机状态管理 Provider
///
/// 管理蓝牙设备扫描、连接和打印配置。
///
/// 蓝牙连接状态统一由 [BluetoothConnectionManager] 管理，这里只做 UI 状态桥接。
/// 状态订阅关系：
/// - [BluetoothConnectionManager.stateStream] → Provider 的 notifyListeners
class PrinterProvider extends ChangeNotifier {
  final PrintService _printService;
  final BluetoothConnectionManager _connectionManager;

  /// 扫描状态
  bool _isScanning = false;

  /// 设备列表
  List<BluetoothDevice> _devices = [];

  /// 是否正在配置地址（用于保存配置时显示 loading）
  bool _isConfiguring = false;

  StreamSubscription<BluetoothConnectionEvent>? _connectionSubscription;

  PrinterProvider(this._printService)
      : _connectionManager = BluetoothConnectionManager.instance {
    // 订阅连接状态变化，驱动 UI 刷新
    _connectionSubscription = _connectionManager.stateStream.listen((_) {
      notifyListeners();
    });
  }

  // ── 蓝牙连接状态（代理自 ConnectionManager） ──

  /// 是否已连接打印机
  bool get isConnected => _connectionManager.isConnected;

  /// 当前连接状态
  BluetoothConnectionState get connectionState => _connectionManager.state;

  /// 是否正在连接
  bool get isConnecting =>
      connectionState == BluetoothConnectionState.connecting;

  /// 连接是否失败（带保存地址，等待重试）
  bool get isConnectionError =>
      connectionState == BluetoothConnectionState.connectionError;

  /// 保存的蓝牙地址
  String? get savedAddress => _connectionManager.savedAddress;

  /// 保存的蓝牙名称
  String? get savedName => _connectionManager.savedName;

  // ── 扫描状态 ──

  /// 已发现的蓝牙设备列表
  List<BluetoothDevice> get devices => _devices;

  /// 是否正在搜索
  bool get isScanning => _isScanning;

  /// 是否正在配置（保存地址）
  bool get isConfiguring => _isConfiguring;

  // ── 配置状态（打印选项，非蓝牙连接） ──

  /// 打印机配置（打印选项部分）
  PrinterConfig get config => _config;
  PrinterConfig _config = PrinterConfig.defaultConfig;

  PrinterConfig get printerConfig => _config;

  // ── 生命周期 ──

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }

  // ── 初始化 ──

  /// 初始化，加载配置并尝试自动连接
  Future<void> initialize() async {
    _config = await _printService.getPrinterConfig();
    notifyListeners();

    await _connectionManager.initialize();
  }

  // ── 蓝牙扫描（地址发现） ──

  /// 搜索蓝牙设备
  ///
  /// 用于用户主动点击"搜索设备"，找到后可调用 [configurePrinter] 保存地址。
  Future<void> scanDevices() async {
    if (_isScanning) return;

    _isScanning = true;
    _devices = [];
    notifyListeners();

    try {
      final found = await _connectionManager.scanDevices();
      _devices = found;
    } catch (e) {
      debugPrint('搜索蓝牙设备失败: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  // ── 蓝牙地址配置 ──

  /// 配置打印机地址（持久化并连接）
  ///
  /// 用于用户从设备列表中选择一台设备作为默认打印机。
  Future<void> configurePrinter(BluetoothDevice device) async {
    if (_isConfiguring) return;

    _isConfiguring = true;
    notifyListeners();

    try {
      await _connectionManager.configureAddress(
        device.address,
        name: device.name.isNotEmpty ? device.name : '未知设备',
      );

      // 同步更新打印配置中的设备信息
      _config = _config.copyWith(
        deviceAddress: Value(device.address),
        deviceName: Value(
            device.name.isNotEmpty ? device.name : '未知设备'),
      );
      await _printService.savePrinterConfig(_config);
    } catch (e) {
      debugPrint('配置打印机失败: $e');
      rethrow;
    } finally {
      _isConfiguring = false;
      notifyListeners();
    }
  }

  /// 主动断开连接（不清除保存的地址）
  Future<void> disconnect() async {
    await _connectionManager.disconnect();
  }

  /// 清除保存的蓝牙地址（完全重置）
  Future<void> clearPrinterAddress() async {
    await _connectionManager.clearSavedAddress();

    _config = _config.copyWith(
      deviceAddress: const Value(null),
      deviceName: const Value(null),
    );
    await _printService.savePrinterConfig(_config);
    notifyListeners();
  }

  /// 确保已连接（打印前调用）
  ///
  /// 如果已连接直接返回，如果断开则用保存的地址重连。
  Future<void> ensureConnected() async {
    await _connectionManager.ensureConnected();
  }

  // ── 打印选项配置 ──

  /// 更新配置
  Future<void> updateConfig(PrinterConfig config) async {
    _config = config;
    await _printService.savePrinterConfig(_config);
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

  /// 切换打印诗词
  Future<void> togglePrintPoetry(bool value) async {
    _config = _config.copyWith(printPoetry: value);
    await _printService.savePrinterConfig(_config);
    notifyListeners();
  }

  /// 更新打印间距行数
  Future<void> updatePrintGapLines(int lines) async {
    _config = _config.copyWith(printGapLines: lines);
    await _printService.savePrinterConfig(_config);
    notifyListeners();
  }

  /// 更新票间间距行数
  Future<void> updatePrintTicketGapLines(int lines) async {
    _config = _config.copyWith(printTicketGapLines: lines);
    await _printService.savePrinterConfig(_config);
    notifyListeners();
  }

  // ── 打印操作 ──

  /// 测试打印
  Future<void> testPrint() async {
    // ensureConnected 会在内部处理未连接的情况
    await ensureConnected();
    final testOrder = Order(
      ticketNumber: 999,
      dishId: 0,
      dishName: '测试菜品',
      createdAt: DateTime.now(),
    );
    await _printService.printTicket(testOrder, _config);
  }

  /// 打印订单（单联）
  Future<void> printOrder(Order order) async {
    await ensureConnected();
    await _printService.printTicket(order, _config);
  }

  /// 打印订单（两联）
  Future<void> printOrderTwoCopies(Order order) async {
    await ensureConnected();
    await _printService.printTwoCopies(order, _config);
  }
}
