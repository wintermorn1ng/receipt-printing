import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'print_renderer.dart';
import 'print_formatter.dart';

/// 打印错误类型
enum PrintErrorType {
  /// 蓝牙未开启
  bluetoothNotEnabled,

  /// 打印机未连接
  printerNotConnected,

  /// 打印中断开
  printerDisconnected,

  /// 打印指令失败
  printFailed,

  /// 连接超时
  connectionTimeout,
}

/// 打印异常
class PrintException implements Exception {
  final PrintErrorType error;
  final String message;

  const PrintException(this.error, this.message);

  @override
  String toString() => message;
}

/// ESC/POS 蓝牙打印机渲染器
///
/// 实现 PrintRenderer 接口，用于通过蓝牙发送 ESC/POS 指令打印小票
class ESCPOSRenderer implements PrintRenderer {
  BluetoothConnection? _connection;
  String? _deviceAddress;
  bool _isConnected = false;

  /// 连接超时时间（秒）
  static const int connectionTimeoutSeconds = 5;

  /// 是否已连接
  bool get isConnected => _isConnected;

  /// 获取设备地址
  String? get deviceAddress => _deviceAddress;

  /// 连接蓝牙打印机
  ///
  /// [address] - 蓝牙设备 MAC 地址
  /// 返回是否连接成功
  Future<bool> connect(String address) async {
    try {
      // 如果已连接到同一设备，直接返回成功
      if (_isConnected && _deviceAddress == address) {
        return true;
      }

      // 断开之前的连接
      await disconnect();

      // 创建新连接（带超时）
      _connection = await BluetoothConnection.toAddress(
        address,
      ).timeout(
        const Duration(seconds: connectionTimeoutSeconds),
        onTimeout: () {
          throw const PrintException(
            PrintErrorType.connectionTimeout,
            '连接打印机超时，请检查设备是否在范围内',
          );
        },
      );

      _deviceAddress = address;
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      _deviceAddress = null;
      _connection = null;

      if (e is PrintException) {
        rethrow;
      }

      throw PrintException(
        PrintErrorType.printerNotConnected,
        '连接打印机失败: ${e.toString()}',
      );
    }
  }

  /// 断开蓝牙连接
  Future<void> disconnect() async {
    if (_connection != null) {
      try {
        await _connection!.close();
      } catch (e) {
        // 忽略断开连接时的错误
      }
    }
    _connection = null;
    _deviceAddress = null;
    _isConnected = false;
  }

  @override
  Future<void> render(PrintData data) async {
    if (!_isConnected || _connection == null) {
      throw const PrintException(
        PrintErrorType.printerNotConnected,
        '打印机未连接',
      );
    }

    try {
      // 生成 ESC/POS 指令
      final bytes = PrintFormatter.formatTicket(
        ticketNumber: data.ticketNumber,
        dishName: data.dishName,
        shopName: data.shopName,
        printDateTime: data.dateTime != null,
      );

      // 发送数据（转换为 Uint8List）
      _connection!.output.add(Uint8List.fromList(bytes));
      await _connection!.output.allSent;
    } catch (e) {
      if (e is PrintException) {
        rethrow;
      }
      throw const PrintException(
        PrintErrorType.printFailed,
        '打印失败',
      );
    }
  }

  @override
  Future<void> renderTwoCopies(PrintData data) async {
    // 打印第一联
    await render(data);

    // 等待一小段时间确保打印机处理完第一联
    await Future.delayed(const Duration(milliseconds: 500));

    // 打印第二联
    await render(data);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
  }
}