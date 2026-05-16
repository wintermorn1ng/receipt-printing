import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';

import 'print_renderer.dart';
import 'print_formatter.dart';
import '../services/bluetooth_connection_manager.dart';

void _log(String message) {
  developer.log(message, name: 'ESCPOSRenderer');
}

/// ESC/POS 蓝牙打印机渲染器
///
/// 实现 [PrintRenderer] 接口，用于通过蓝牙发送 ESC/POS 指令打印小票。
///
/// 连接状态由 [BluetoothConnectionManager] 统一管理，这里的 [isConnected]
/// 只是对底层蓝牙库状态的反射，不持有独立的状态。
class ESCPOSRenderer implements PrintRenderer {
  /// 是否已连接（反射底层蓝牙库状态）
  bool get isConnected => BluetoothPrintPlus.isConnected;

  /// 连接蓝牙打印机（已知地址，直接连接）
  ///
  /// [address] 蓝牙设备 MAC 地址
  /// 返回是否连接成功
  ///
  /// 已废弃：推荐使用 [BluetoothConnectionManager.configureAddress]，
  /// 它会负责地址持久化、重试和状态管理。本方法委托给 ConnectionManager。
  @Deprecated('Use BluetoothConnectionManager.instance.configureAddress()')
  Future<bool> connect(String address) async {
    _log('ESCPOSRenderer.connect: address=$address (委托给 ConnectionManager)');
    try {
      await BluetoothConnectionManager.instance.configureAddress(address);
      return BluetoothConnectionManager.instance.isConnected;
    } catch (e) {
      _log('ESCPOSRenderer.connect 失败: $e');
      return false;
    }
  }

  /// 断开蓝牙连接
  ///
  /// 已废弃：推荐使用 [BluetoothConnectionManager.disconnect]。
  @Deprecated('Use BluetoothConnectionManager.instance.disconnect()')
  Future<void> disconnect() async {
    await BluetoothConnectionManager.instance.disconnect();
  }

  @override
  Future<void> render(PrintData data) async {
    _log('ESCPOSRenderer.render: isConnected=${BluetoothPrintPlus.isConnected}');

    if (!BluetoothPrintPlus.isConnected) {
      throw const PrintException(
        PrintErrorType.printerNotConnected,
        '打印机未连接',
      );
    }

    try {
      final formatter = PrintFormatter();
      final bytes = await formatter.formatTicket(
        ticketNumber: data.ticketNumber,
        dishName: data.dishName,
        shopName: data.shopName,
        printDateTime: data.dateTime != null,
        dateTime: data.dateTime,
        gapLines: data.gapLines,
        poetryText: data.poetryText,
        poetryAuthor: data.poetryAuthor,
      );

      final dataToSend = Uint8List.fromList(bytes);
      await BluetoothPrintPlus.write(dataToSend);
      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      if (e is PrintException) rethrow;
      throw PrintException(
        PrintErrorType.printFailed,
        '打印失败: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> renderTwoCopies(PrintData data) async {
    // 第一联
    await render(data);
    await Future.delayed(const Duration(milliseconds: 500));

    // 在打印第二联前验证连接是否仍然有效
    if (!BluetoothPrintPlus.isConnected) {
      throw const PrintException(
        PrintErrorType.printerDisconnected,
        '打印机在第一联后断开连接，第二联未打印',
      );
    }

    // 在两张票之间插入间距（仅进纸，不切纸）
    if (data.ticketGapLines > 0) {
      try {
        final bytes = PrintFormatter.feedLines(data.ticketGapLines);
        await BluetoothPrintPlus.write(Uint8List.fromList(bytes));
        await Future.delayed(
            Duration(milliseconds: 100 + data.ticketGapLines * 50));
      } catch (e) {
        _log('renderTwoCopies 插入票间间距失败: $e，忽略错误继续打印');
      }
    }

    // 第二联
    await render(data);
  }

  @override
  Future<void> dispose() async {
    try {
      await BluetoothPrintPlus.disconnect();
    } catch (e) {
      _log('ESCPOSRenderer.dispose 忽略错误: $e');
    }
  }
}
