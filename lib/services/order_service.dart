import 'package:meta/meta.dart';
import '../database/order_dao.dart';
import '../models/dish.dart';
import '../models/models.dart';
import 'ticket_service.dart';

/// 下单服务
///
/// 协调取餐号和订单创建，提供下单业务逻辑
class OrderService {
  final OrderDao _orderDao;
  final TicketService _ticketService;

  /// 构造函数
  OrderService(this._orderDao, this._ticketService);

  /// 构造函数 - 用于测试
  @visibleForTesting
  OrderService.forTest(this._orderDao, this._ticketService);

  /// 下单
  ///
  /// 创建订单并递增取餐号
  /// 返回创建的订单对象
  Future<Order> placeOrder(Dish dish) async {
    // 获取当前取餐号
    final ticketNumber = await _ticketService.getCurrentTicketNumber();

    // 创建订单
    final order = Order(
      ticketNumber: ticketNumber,
      dishId: dish.id!,
      dishName: dish.name,
      createdAt: DateTime.now(),
    );

    // 插入订单
    final id = await _orderDao.insert(order);

    // 递增取餐号
    await _ticketService.incrementTicketNumber();

    // 返回带 id 的订单
    return order.copyWith(id: Value(id));
  }

  /// 获取今日订单数量
  Future<int> getTodayOrderCount() async {
    final today = _formatDate(DateTime.now());
    return await _orderDao.getOrderCountByDate(today);
  }

  /// 获取今日所有订单
  Future<List<Order>> getTodayOrders() async {
    final today = _formatDate(DateTime.now());
    return await _orderDao.getByDate(today);
  }

  /// 格式化日期为 YYYY-MM-DD
  String _formatDate(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}