import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/printer_config.dart';
import '../utils/print_renderer.dart';
import '../utils/escpos_renderer.dart';

/// 打印服务
///
/// 管理打印配置和蓝牙打印机连接
class PrintService {
  PrintRenderer? _renderer;
  final ESCPOSRenderer _escposRenderer = ESCPOSRenderer();

  /// 存储键名
  static const String _configKey = 'printer_config';

  /// 当前的渲染器
  PrintRenderer get renderer => _renderer ?? _escposRenderer;

  /// 是否已连接
  bool get isConnected => _escposRenderer.isConnected;

  /// 获取已保存的打印机配置
  Future<PrinterConfig> getPrinterConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_configKey);

    if (jsonString == null) {
      return PrinterConfig.defaultConfig;
    }

    try {
      // 简单的 JSON 解析
      final Map<String, dynamic> json = _parseJson(jsonString);
      return PrinterConfig.fromJson(json);
    } catch (e) {
      return PrinterConfig.defaultConfig;
    }
  }

  /// 简单的 JSON 字符串解析
  Map<String, dynamic> _parseJson(String jsonString) {
    final Map<String, dynamic> result = {};
    // 移除首尾大括号
    final content = jsonString.trim();
    if (content.isEmpty || content == '{}') {
      return result;
    }

    // 简单的键值对解析（不支持嵌套）
    final pattern = RegExp(r'"([^"]+)":\s*("([^"]*)"|(\d+\.?\d*)|(true|false)|null)');
    for (final match in pattern.allMatches(content)) {
      final key = match.group(1)!;
      final stringValue = match.group(3);
      final numberValue = match.group(4);
      final boolValue = match.group(5);
      final nullValue = match.group(6);

      if (stringValue != null) {
        result[key] = stringValue;
      } else if (numberValue != null) {
        if (numberValue.contains('.')) {
          result[key] = double.parse(numberValue);
        } else {
          result[key] = int.parse(numberValue);
        }
      } else if (boolValue != null) {
        result[key] = boolValue == 'true';
      } else if (nullValue != null) {
        result[key] = null;
      }
    }

    return result;
  }

  /// 保存打印机配置
  Future<void> savePrinterConfig(PrinterConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = _encodeJson(config.toJson());
    await prefs.setString(_configKey, jsonString);
  }

  /// 简单的 JSON 编码
  String _encodeJson(Map<String, dynamic> json) {
    final buffer = StringBuffer('{');
    var first = true;

    json.forEach((key, value) {
      if (!first) {
        buffer.write(',');
      }
      first = false;

      buffer.write('"$key":');
      if (value == null) {
        buffer.write('null');
      } else if (value is String) {
        buffer.write('"$value"');
      } else if (value is bool) {
        buffer.write(value.toString());
      } else if (value is num) {
        buffer.write(value.toString());
      }
    });

    buffer.write('}');
    return buffer.toString();
  }

  /// 连接打印机
  Future<bool> connect(String address) async {
    return await _escposRenderer.connect(address);
  }

  /// 断开连接
  Future<void> disconnect() async {
    await _escposRenderer.disconnect();
  }

  /// 打印小票
  Future<void> printTicket(Order order, PrinterConfig config) async {
    // 如果需要切换到真正的打印机渲染器
    if (_renderer != null && _renderer != _escposRenderer) {
      _renderer!.dispose();
      _renderer = _escposRenderer;
    } else {
      _renderer = _escposRenderer;
    }

    // 如果未连接且有保存的地址，自动连接
    if (!_escposRenderer.isConnected && config.deviceAddress != null) {
      await connect(config.deviceAddress!);
    }

    final printData = PrintData(
      ticketNumber: order.ticketNumber,
      dishName: order.dishName,
      shopName: config.printShopName ? config.shopName : null,
      dateTime: config.printDateTime ? order.createdAt : null,
    );

    await _renderer!.render(printData);
  }

  /// 打印两联
  Future<void> printTwoCopies(Order order, PrinterConfig config) async {
    // 如果需要切换到真正的打印机渲染器
    if (_renderer != null && _renderer != _escposRenderer) {
      _renderer!.dispose();
      _renderer = _escposRenderer;
    } else {
      _renderer = _escposRenderer;
    }

    // 如果未连接且有保存的地址，自动连接
    if (!_escposRenderer.isConnected && config.deviceAddress != null) {
      await connect(config.deviceAddress!);
    }

    final printData = PrintData(
      ticketNumber: order.ticketNumber,
      dishName: order.dishName,
      shopName: config.printShopName ? config.shopName : null,
      dateTime: config.printDateTime ? order.createdAt : null,
    );

    await _renderer!.renderTwoCopies(printData);
  }

  /// 尝试自动连接上次打印机
  Future<bool> autoConnectLastPrinter() async {
    final config = await getPrinterConfig();
    if (config.deviceAddress != null) {
      return await connect(config.deviceAddress!);
    }
    return false;
  }

  /// 切换渲染器
  void setRenderer(PrintRenderer renderer) {
    _renderer = renderer;
  }

  /// 释放资源
  Future<void> dispose() async {
    await _renderer?.dispose();
    _renderer = null;
  }
}