import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/order.dart';
import '../models/printer_config.dart';
import '../utils/print_renderer.dart';
import '../utils/escpos_renderer.dart';

/// 打印服务
///
/// 管理打印配置和蓝牙打印机连接。
///
/// 注意：蓝牙连接状态由 [BluetoothConnectionManager] 统一管理。
/// 本服务只负责打印指令的渲染和发送。
class PrintService {
  PrintRenderer? _renderer;
  final ESCPOSRenderer _escposRenderer = ESCPOSRenderer();

  /// 存储键名
  static const String _configKey = 'printer_config';

  /// 当前的渲染器
  PrintRenderer get renderer => _renderer ?? _escposRenderer;

  /// 是否已连接（委托给底层）
  bool get isConnected => _escposRenderer.isConnected;

  /// 获取已保存的打印机配置
  Future<PrinterConfig> getPrinterConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);

    if (jsonString == null) {
      return PrinterConfig.defaultConfig;
    }

    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return PrinterConfig.fromJson(json);
    } catch (e) {
      return PrinterConfig.defaultConfig;
    }
  }

  /// 保存打印机配置
  Future<void> savePrinterConfig(PrinterConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(config.toJson());
    await prefs.setString(_configKey, jsonString);
  }

  /// 打印小票
  ///
  /// 调用方应先通过 [BluetoothConnectionManager.ensureConnected] 确保连接。
  Future<void> printTicket(Order order, PrinterConfig config) async {
    _switchToEscposRenderer();

    final printData = PrintData(
      ticketNumber: order.ticketNumber,
      dishName: order.dishName,
      shopName: config.printShopName ? config.shopName : null,
      dateTime: config.printDateTime ? order.createdAt : null,
      gapLines: config.printGapLines,
      ticketGapLines: config.printTicketGapLines,
    );

    await renderer.render(printData);
  }

  /// 打印两联
  Future<void> printTwoCopies(Order order, PrinterConfig config) async {
    _switchToEscposRenderer();

    final printData = PrintData(
      ticketNumber: order.ticketNumber,
      dishName: order.dishName,
      shopName: config.printShopName ? config.shopName : null,
      dateTime: config.printDateTime ? order.createdAt : null,
      gapLines: config.printGapLines,
      ticketGapLines: config.printTicketGapLines,
    );

    await renderer.renderTwoCopies(printData);
  }

  void _switchToEscposRenderer() {
    if (_renderer != null && _renderer != _escposRenderer) {
      _renderer!.dispose();
    }
    _renderer = _escposRenderer;
  }

  /// 切换渲染器（预览用）
  void setRenderer(PrintRenderer renderer) {
    _renderer = renderer;
  }

  /// 释放资源
  Future<void> dispose() async {
    await _renderer?.dispose();
    _renderer = null;
  }
}
