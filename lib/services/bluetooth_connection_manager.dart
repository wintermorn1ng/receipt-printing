import 'dart:async';
import 'dart:developer' as developer;

import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 蓝牙连接状态
enum BluetoothConnectionState {
  /// 未连接（无保存地址，或用户主动断开）
  disconnected,

  /// 正在连接
  connecting,

  /// 已连接
  connected,

  /// 连接失败（有保存地址，触发自动重试）
  connectionError,
}

/// 蓝牙连接事件（用于日志和调试）
class BluetoothConnectionEvent {
  final BluetoothConnectionState state;
  final String? address;
  final String? message;
  final Object? error;
  final DateTime timestamp;

  BluetoothConnectionEvent({
    required this.state,
    this.address,
    this.message,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'BluetoothConnectionEvent(state: $state, address: $address, '
        'message: $message, error: $error, timestamp: $timestamp)';
  }
}

void _log(String message) {
  developer.log(message, name: 'BluetoothConnectionManager');
}

/// 蓝牙连接管理器
///
/// 职责：
/// 1. 管理蓝牙连接状态机（disconnected / connecting / connected / connectionError）
/// 2. 持久化蓝牙地址（SharedPreferences）
/// 3. 自动重连带退避重试
/// 4. 对外暴露状态流，UI 可订阅
///
/// 使用方式：
/// - 单例，通过 `BluetoothConnectionManager.instance` 访问
/// - 启动 APP 时调用 `initialize()` 加载保存的地址并尝试连接
/// - 打印前调用 `ensureConnected()` 确保已连接
/// - 用户切换地址时调用 `configureAddress()`
/// - 用户主动断开时调用 `disconnect()`（不清除保存的地址）
class BluetoothConnectionManager {
  BluetoothConnectionManager._();
  static final BluetoothConnectionManager instance =
      BluetoothConnectionManager._();

  /// 存储键名
  static const String _addressKey = 'bluetooth_printer_address';
  static const String _nameKey = 'bluetooth_printer_name';

  /// 重试配置
  static const Duration _initialRetryDelay = Duration(seconds: 1);
  static const Duration _maxRetryDelay = Duration(seconds: 30);
  static const int _maxRetryAttempts = 5;

  // ── 状态 ──

  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  String? _savedAddress;
  String? _savedName;
  BluetoothDevice? _lastKnownDevice;

  final _stateController =
      StreamController<BluetoothConnectionEvent>.broadcast();
  Timer? _retryTimer;
  int _retryAttempt = 0;

  // ── 公开属性 ──

  /// 当前连接状态
  BluetoothConnectionState get state => _state;

  /// 是否已连接
  bool get isConnected => _state == BluetoothConnectionState.connected;

  /// 当前保存的蓝牙地址（持久化存储中的地址）
  String? get savedAddress => _savedAddress;

  /// 当前保存的蓝牙名称
  String? get savedName => _savedName;

  /// 实际连接状态变化流
  Stream<BluetoothConnectionEvent> get stateStream =>
      _stateController.stream;

  // ── 初始化 ──

  /// 初始化，加载保存的地址并尝试自动连接
  Future<void> initialize() async {
    await _loadSavedAddress();

    if (_savedAddress != null) {
      _log('已加载保存的地址: $_savedAddress ($_savedName)，开始自动连接');
      await _connectWithRetry(_savedAddress!);
    } else {
      _log('无保存的蓝牙地址，保持 disconnected 状态');
      _emit(BluetoothConnectionState.disconnected,
          message: '无保存的蓝牙地址');
    }
  }

  /// 加载持久化的蓝牙地址
  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    _savedAddress = prefs.getString(_addressKey);
    _savedName = prefs.getString(_nameKey);
  }

  /// 保存蓝牙地址到持久化存储
  Future<void> _saveAddress(String address, String? name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_addressKey, address);
    if (name != null) {
      await prefs.setString(_nameKey, name);
    }
    _savedAddress = address;
    _savedName = name;
  }

  /// 清除保存的蓝牙地址
  Future<void> _clearSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_addressKey);
    await prefs.remove(_nameKey);
    _savedAddress = null;
    _savedName = null;
  }

  // ── 状态迁移 ──

  void _emit(
    BluetoothConnectionState newState, {
    String? address,
    String? message,
    Object? error,
  }) {
    _state = newState;
    _stateController.add(BluetoothConnectionEvent(
      state: newState,
      address: address ?? _savedAddress,
      message: message,
      error: error,
    ));
    _log('状态迁移: $newState, address=$address, message=$message');
  }

  // ── 公开 API ──

  /// 配置并连接新的蓝牙地址（持久化地址，然后连接）
  ///
  /// 用于用户主动切换打印机场景。
  Future<void> configureAddress(String address, {String? name}) async {
    _log('configureAddress: address=$address, name=$name');

    // 取消正在进行的重试
    _cancelRetry();

    // 保存新地址
    await _saveAddress(address, name);

    // 开始连接
    await _connectWithRetry(address);
  }

  /// 确保已连接，如果断开则用保存的地址重连
  ///
  /// 用于打印前的保活检查。
  /// 如果当前已是 connected 状态，直接返回成功。
  /// 如果没有保存的地址，抛出异常。
  Future<void> ensureConnected() async {
    _log('ensureConnected: 当前状态=$state');

    if (_state == BluetoothConnectionState.connected) {
      _log('ensureConnected: 已连接，直接返回');
      return;
    }

    if (_savedAddress == null) {
      throw const PrintException(
        PrintErrorType.printerNotConnected,
        '未配置打印机地址',
      );
    }

    if (_state == BluetoothConnectionState.connecting) {
      _log('ensureConnected: 正在连接中，等待...');
      // 等待连接完成
      await for (final event in stateStream) {
        if (event.state == BluetoothConnectionState.connected) {
          return;
        }
        if (event.state == BluetoothConnectionState.connectionError) {
          throw const PrintException(
            PrintErrorType.printerNotConnected,
            '打印机连接失败',
          );
        }
      }
    }

    // disconnected 或 connectionError，触发重连
    await _connectWithRetry(_savedAddress!);
  }

  /// 主动断开连接（不清除保存的地址）
  Future<void> disconnect() async {
    _log('disconnect: 主动断开');

    _cancelRetry();

    try {
      await BluetoothPrintPlus.disconnect();
    } catch (e) {
      _log('disconnect 忽略错误: $e');
    }

    _emit(BluetoothConnectionState.disconnected, message: '用户主动断开');
  }

  /// 清除保存的地址（完全重置）
  Future<void> clearSavedAddress() async {
    _log('clearSavedAddress: 清除保存的地址');

    _cancelRetry();

    try {
      await BluetoothPrintPlus.disconnect();
    } catch (e) {
      _log('clearSavedAddress disconnect 忽略错误: $e');
    }

    await _clearSavedAddress();
    _emit(BluetoothConnectionState.disconnected, message: '已清除保存的地址');
  }

  /// 扫描附近设备（用于地址发现）
  Future<List<BluetoothDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final devices = await BluetoothPrintPlus.startScan(timeout: timeout) as List<BluetoothDevice>;
    return devices.where((d) => d.address.isNotEmpty).toList();
  }

  /// 通过地址连接设备（已知地址，直接连接，不扫描）
  Future<bool> _connectDirect(String address) async {
    _log('_connectDirect: address=$address');

    // 如果已连接同一地址，直接返回
    if (BluetoothPrintPlus.isConnected && _lastKnownDevice?.address == address) {
      _log('_connectDirect: 已连接且地址匹配，直接返回');
      return true;
    }

    // 先断开旧连接
    try {
      await BluetoothPrintPlus.disconnect();
    } catch (e) {
      _log('_connectDirect: 断开旧连接忽略错误: $e');
    }

    // 尝试直接连接（bluetooth_print_plus 可能需要先扫描才能 connect）
    // 有些蓝牙模块需要先 discovery 才能建立连接
    try {
      final devices = await BluetoothPrintPlus.startScan(
        timeout: const Duration(seconds: 5),
      );

      BluetoothDevice? target;
      for (final d in devices) {
        if (d.address == address) {
          target = d;
          break;
        }
      }

      if (target == null) {
        _log('_connectDirect: 在 5s 扫描中未找到目标设备');
        return false;
      }

      _lastKnownDevice = target;
      await BluetoothPrintPlus.connect(target);
      await Future.delayed(const Duration(milliseconds: 500));

      _log('_connectDirect: 连接成功，isConnected=${BluetoothPrintPlus.isConnected}');
      return BluetoothPrintPlus.isConnected;
    } catch (e) {
      _log('_connectDirect: 连接失败: $e');
      return false;
    }
  }

  /// 带重试的连接
  Future<void> _connectWithRetry(String address) async {
    _log('_connectWithRetry: address=$address');

    _cancelRetry();

    if (_state == BluetoothConnectionState.connecting) {
      _log('_connectWithRetry: 已在 connecting 状态');
      return;
    }

    _emit(BluetoothConnectionState.connecting, address: address,
        message: '开始连接');
    _retryAttempt = 0;

    final success = await _attemptConnect(address);

    if (success) {
      _retryAttempt = 0;
      _emit(BluetoothConnectionState.connected, address: address,
          message: '连接成功');
    } else {
      _scheduleRetry(address);
    }
  }

  /// 单次连接尝试
  Future<bool> _attemptConnect(String address) async {
    _log('_attemptConnect: address=$address, attempt=${_retryAttempt + 1}');

    try {
      final success = await _connectDirect(address);

      if (success) {
        return true;
      }

      _log('_attemptConnect: 连接返回 false');
      return false;
    } catch (e) {
      _log('_attemptConnect: 抛出异常: $e');
      return false;
    }
  }

  /// 调度重试（带退避）
  void _scheduleRetry(String address) {
    if (_retryAttempt >= _maxRetryAttempts) {
      _log('_scheduleRetry: 已达最大重试次数 $_maxRetryAttempts，停止重试');
      _emit(BluetoothConnectionState.connectionError,
          address: address,
          message: '连接失败，已停止重试');
      return;
    }

    // 计算退避延迟
    final delay = _initialRetryDelay * (1 << _retryAttempt);
    final actualDelay = delay > _maxRetryDelay ? _maxRetryDelay : delay;

    _log('_scheduleRetry: ${_retryAttempt + 1} 次尝试失败，'
        '${actualDelay.inSeconds}s 后重试...');

    _retryAttempt++;

    _emit(BluetoothConnectionState.connectionError,
        address: address,
        message: '连接失败，${actualDelay.inSeconds}s 后重试');

    _retryTimer = Timer(actualDelay, () {
      _log('_scheduleRetry: Timer 触发，开始重试');
      _attemptConnect(address).then((success) {
        if (success) {
          _retryAttempt = 0;
          _emit(BluetoothConnectionState.connected,
              address: address, message: '连接成功（重试后）');
        } else {
          _scheduleRetry(address);
        }
      });
    });
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryAttempt = 0;
  }

  /// 释放资源
  void dispose() {
    _cancelRetry();
    _stateController.close();
  }
}

/// 打印错误类型（从 escpos_renderer 迁移）
enum PrintErrorType {
  bluetoothNotEnabled,
  printerNotConnected,
  printerDisconnected,
  printFailed,
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
