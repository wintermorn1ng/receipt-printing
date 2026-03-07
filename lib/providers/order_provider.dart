import 'package:flutter/foundation.dart';
import '../database/order_dao.dart';
import '../models/dish.dart';
import '../models/order.dart' as model;
import '../services/order_service.dart';
import '../services/ticket_service.dart';

/// 订单状态管理类
///
/// 使用 ChangeNotifier 提供响应式的订单和取餐号数据管理
class OrderProvider extends ChangeNotifier {
  final OrderService _orderService;
  final TicketService _ticketService;

  int _currentTicketNumber = 1;
  bool _isPlacingOrder = false;
  String? _error;
  int _todayOrderCount = 0;

  OrderProvider(this._orderService, this._ticketService);

  /// 当前取餐号
  int get currentTicketNumber => _currentTicketNumber;

  /// 是否正在下单
  bool get isPlacingOrder => _isPlacingOrder;

  /// 错误信息
  String? get error => _error;

  /// 今日订单数
  int get todayOrderCount => _todayOrderCount;

  /// 加载取餐号
  Future<void> loadTicketNumber() async {
    try {
      _currentTicketNumber = await _ticketService.getCurrentTicketNumber();
      notifyListeners();
    } catch (e) {
      _setError('加载取餐号失败: $e');
    }
  }

  /// 加载今日订单数
  Future<void> loadTodayOrderCount() async {
    try {
      _todayOrderCount = await _orderService.getTodayOrderCount();
      notifyListeners();
    } catch (e) {
      _setError('加载订单数失败: $e');
    }
  }

  /// 初始化（应用启动时调用）
  Future<void> initialize() async {
    await _ticketService.checkDailyReset();
    await loadTicketNumber();
    await loadTodayOrderCount();
  }

  /// 下单
  ///
  /// [dish] 要下单的菜品
  /// 返回创建的订单，失败返回 null
  Future<Order?> placeOrder(Dish dish) async {
    if (_isPlacingOrder) return null;

    _setPlacingOrder(true);
    _clearError();

    try {
      final order = await _orderService.placeOrder(dish);
      _currentTicketNumber = await _ticketService.getCurrentTicketNumber();
      _todayOrderCount++;
      notifyListeners();
      return order;
    } catch (e) {
      _setError('下单失败: $e');
      return null;
    } finally {
      _setPlacingOrder(false);
    }
  }

  /// 重置取餐号
  Future<void> resetTicketNumber() async {
    _clearError();

    try {
      await _ticketService.resetTicketNumber();
      _currentTicketNumber = 1;
      notifyListeners();
    } catch (e) {
      _setError('重置取餐号失败: $e');
    }
  }

  /// 设置取餐号
  ///
  /// [number] 要设置的取餐号，必须大于0
  Future<void> setTicketNumber(int number) async {
    _clearError();

    try {
      await _ticketService.setTicketNumber(number);
      _currentTicketNumber = number;
      notifyListeners();
    } catch (e) {
      _setError('设置取餐号失败: $e');
    }
  }

  void _setPlacingOrder(bool value) {
    _isPlacingOrder = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}