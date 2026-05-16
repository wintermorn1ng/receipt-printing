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
  static const Duration _connectTimeout = Duration(seconds: 8);
  static const Duration _scanTimeout = Duration(seconds: 5);

  // ── 状态 ──

  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  String? _savedAddress;
  String? _savedName;
  BluetoothDevice? _lastKnownDevice;

  final _stateController =
      StreamController<BluetoothConnectionEvent>.broadcast();
  Timer? _retryTimer;

  /// 重试计数器（单次连接会话内的连续失败次数，成功或取消时重置）
  int _retryAttempt = 0;

  /// 取消令牌：外部调用 cancel 时置 true，_connectWithRetry 检测到后退出循环
  bool _cancelled = false;

  /// 连接锁：确保同一时间只有一个连接操作在进行
  bool _connectLocked = false;

  /// 连接完成句柄：并发调用者通过它等待正在进行的连接操作完成
  Completer<void>? _connectCompleter;

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
  /// 先写持久化，成功后再更新内存（保证一致性）
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

    // 取消正在进行的连接操作
    _cancelCurrentOperation();

    // 保存新地址（持久化优先）
    await _saveAddress(address, name);

    // 开始连接（内部处理锁等待）
    await _connectWithRetry(address);
  }

  /// 确保已连接，如果断开则用保存的地址重连
  ///
  /// 用于打印前的保活检查。
  /// 保证返回时连接已建立，或已耗尽所有重试（抛出异常）。
  Future<void> ensureConnected() async {
    _log('ensureConnected: 当前状态=$state');

    // 已连接，直接返回
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

    // 如果有连接操作正在进行，等待它完成
    if (_connectLocked) {
      _log('ensureConnected: 连接操作进行中，等待完成...');
      try {
        await _connectCompleter!.future;
        // 等待的操作成功了
        if (_state == BluetoothConnectionState.connected) {
          return;
        }
      } catch (_) {
        // 等待的操作失败了，继续往下走，发起新的连接
        _log('ensureConnected: 等待的连接操作失败，发起新连接');
      }
    }

    // 发起连接（_connectWithRetry 内部管理锁和并发）
    await _connectWithRetry(_savedAddress!);
  }

  /// 主动断开连接（不清除保存的地址）
  Future<void> disconnect() async {
    _log('disconnect: 主动断开');

    _cancelCurrentOperation();

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

    _cancelCurrentOperation();

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
    final devices = await BluetoothPrintPlus.startScan(timeout: timeout)
        as List<BluetoothDevice>;
    return devices.where((d) => d.address.isNotEmpty).toList();
  }

  // ── 内部连接逻辑 ──

  /// 取消当前正在进行的连接操作（Timer 延迟 + 取消令牌）
  void _cancelCurrentOperation() {
    _cancelled = true;
    _retryTimer?.cancel();
    _retryTimer = null;
    // 注意：不重置 _retryAttempt。
    // _retryAttempt 在 _connectWithRetry 开始时重置，语义上属于单次连接会话。
    // 如果外部取消后又启动新会话，_connectWithRetry 会自己重置。
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
        timeout: _scanTimeout,
      );

      BluetoothDevice? target;
      for (final d in devices) {
        if (d.address == address) {
          target = d;
          break;
        }
      }

      if (target == null) {
        _log('_connectDirect: 在 ${_scanTimeout.inSeconds}s 扫描中未找到目标设备');
        return false;
      }

      _lastKnownDevice = target;

      // 带超时的连接
      await BluetoothPrintPlus.connect(target).timeout(
        _connectTimeout,
        onTimeout: () {
          _log('_connectDirect: 连接超时 (${_connectTimeout.inSeconds}s)');
          // 尝试清理
          try {
            BluetoothPrintPlus.disconnect();
          } catch (_) {}
          throw TimeoutException(
            '蓝牙连接超时 (${_connectTimeout.inSeconds}s)',
            _connectTimeout,
          );
        },
      );

      await Future.delayed(const Duration(milliseconds: 500));

      _log('_connectDirect: 连接成功，isConnected=${BluetoothPrintPlus.isConnected}');
      return BluetoothPrintPlus.isConnected;
    } on TimeoutException {
      _log('_connectDirect: 连接超时');
      return false;
    } catch (e) {
      _log('_connectDirect: 连接失败: $e');
      return false;
    }
  }

  /// 带重试的连接（阻塞直到成功或耗尽所有重试）
  ///
  /// 内部管理连接锁：同一时间只有一个 _connectWithRetry 运行。
  /// 新的调用会先等待上一个完成（通过 _connectCompleter）。
  Future<void> _connectWithRetry(String address) async {
    _log('_connectWithRetry: address=$address');

    // 等待正在进行中的连接操作
    if (_connectLocked) {
      _log('_connectWithRetry: 已有连接操作在进行，等待完成...');
      try {
        await _connectCompleter!.future;
      } catch (_) {
        // 上一个操作失败，继续
      }
    }

    // 获取锁
    _connectLocked = true;
    _connectCompleter = Completer<void>();
    _cancelled = false;
    _retryAttempt = 0;

    try {
      _emit(BluetoothConnectionState.connecting, address: address,
          message: '开始连接');

      while (!_cancelled) {
        final success = await _attemptConnect(address);

        if (success) {
          _retryAttempt = 0;
          _emit(BluetoothConnectionState.connected, address: address,
              message: '连接成功');
          _connectCompleter!.complete();
          return;
        }

        _retryAttempt++;

        if (_retryAttempt > _maxRetryAttempts) {
          _emit(BluetoothConnectionState.connectionError,
              address: address,
              message: '连接失败，已达最大重试次数 $_maxRetryAttempts');
          final ex = const PrintException(
            PrintErrorType.printerNotConnected,
            '无法连接到打印机，已达最大重试次数',
          );
          _connectCompleter!.completeError(ex);
          throw ex;
        }

        // 计算退避延迟
        final delay = _computeRetryDelay(_retryAttempt);
        _emit(BluetoothConnectionState.connectionError,
            address: address,
            message: '连接失败，${delay.inSeconds}s 后第 $_retryAttempt 次重试');

        // 可取消的延迟等待
        await _cancellableDelay(delay);

        if (_cancelled) {
          _log('_connectWithRetry: 连接已取消');
          final ex = const PrintException(
            PrintErrorType.printerNotConnected,
            '连接已取消',
          );
          _connectCompleter!.completeError(ex);
          throw ex;
        }
      }

      // _cancelled 为 true 但循环条件未触发（边缘情况）
      final ex = const PrintException(
        PrintErrorType.printerNotConnected,
        '连接已取消',
      );
      _connectCompleter!.completeError(ex);
      throw ex;
    } catch (e) {
      // 如果 completer 尚未完成（非正常路径的异常），完成它
      if (_connectCompleter != null && !_connectCompleter!.isCompleted) {
        _connectCompleter!.completeError(e);
      }
      rethrow;
    } finally {
      _connectLocked = false;
      _connectCompleter = null;
    }
  }

  /// 计算退避延迟：1s, 2s, 4s, 8s, 16s, 上限 30s
  Duration _computeRetryDelay(int attempt) {
    // attempt 从 1 开始，所以 shift amount = attempt - 1
    final delay = _initialRetryDelay * (1 << (attempt - 1));
    return delay > _maxRetryDelay ? _maxRetryDelay : delay;
  }

  /// 可被 _cancelCurrentOperation 中断的延迟等待
  Future<void> _cancellableDelay(Duration delay) async {
    final completer = Completer<void>();
    _retryTimer = Timer(delay, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });
    await completer.future;
  }

  /// 单次连接尝试（包异常处理）
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

  /// 释放资源
  void dispose() {
    _cancelCurrentOperation();
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
