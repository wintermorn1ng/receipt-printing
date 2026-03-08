import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_printing/models/dish.dart';
import 'package:receipt_printing/models/order.dart';
import 'package:receipt_printing/providers/menu_provider.dart';
import 'package:receipt_printing/providers/order_provider.dart';
import 'package:receipt_printing/screens/daily_summary_screen.dart';
import 'package:receipt_printing/screens/menu_management_screen.dart';
import 'package:receipt_printing/screens/print_preview_screen.dart';
import 'package:receipt_printing/screens/printer_settings_screen.dart';
import 'package:receipt_printing/widgets/dish_grid_item.dart';
import 'package:receipt_printing/widgets/ticket_number_display.dart';

/// 点单首页
///
/// 展示取餐号和菜品网格，是应用的核心界面
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    try {
      final orderProvider = context.read<OrderProvider>();
      final menuProvider = context.read<MenuProvider>();

      // 初始化订单状态（包含每日重置检查）
      await orderProvider.initialize();
      // 加载菜品
      await menuProvider.loadDishes();
    } catch (e) {
      debugPrint('初始化失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('点单助手'),
        actions: [
          // 取餐号显示
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TicketNumberDisplay(
                  ticketNumber: orderProvider.currentTicketNumber,
                  onReset: () => _handleReset(orderProvider),
                  onSetNumber: (number) => _handleSetNumber(orderProvider, number),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildOrderView();
      case 1:
        return const MenuManagementScreen();
      case 2:
        return const PrinterSettingsScreen();
      case 3:
        return const DailySummaryScreen();
      default:
        return _buildOrderView();
    }
  }

  /// 构建点单视图
  Widget _buildOrderView() {
    return Consumer2<OrderProvider, MenuProvider>(
      builder: (context, orderProvider, menuProvider, child) {
        if (menuProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final dishes = menuProvider.dishes;

        if (dishes.isEmpty) {
          return _buildEmptyMenuState();
        }

        return Column(
          children: [
            // 今日订单数统计
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '今日订单: ${orderProvider.todayOrderCount} 单',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            // 菜品网格
            Expanded(
              child: _buildDishGrid(dishes, orderProvider),
            ),
          ],
        );
      },
    );
  }

  /// 构建菜品网格
  Widget _buildDishGrid(List<Dish> dishes, OrderProvider orderProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕宽度计算列数
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        // 计算卡片高度，确保最小高度为 100dp
        final itemHeight = constraints.maxWidth > 600 ? 140.0 : 120.0;
        final itemWidth = (constraints.maxWidth - 32 - (crossAxisCount - 1) * 12) / crossAxisCount;
        final aspectRatio = itemWidth / itemHeight;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: dishes.length,
          itemBuilder: (context, index) {
            final dish = dishes[index];
            final isPlacingOrder = orderProvider.isPlacingOrder;

            return DishGridItem(
              dish: dish,
              onTap: isPlacingOrder
                  ? null
                  : () => _placeOrder(dish, orderProvider),
            );
          },
        );
      },
    );
  }

  /// 构建空菜单状态
  Widget _buildEmptyMenuState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无菜品',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '请先在「菜单管理」中添加菜品',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => setState(() => _currentIndex = 1),
            icon: const Icon(Icons.add),
            label: const Text('添加菜品'),
          ),
        ],
      ),
    );
  }

  /// 构建占位页面
  Widget _buildPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '$title功能开发中',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建底部导航栏
  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: '点单',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: '菜单管理',
        ),
        NavigationDestination(
          icon: Icon(Icons.print_outlined),
          selectedIcon: Icon(Icons.print),
          label: '打印设置',
        ),
        NavigationDestination(
          icon: Icon(Icons.summarize_outlined),
          selectedIcon: Icon(Icons.summarize),
          label: '日总结',
        ),
      ],
    );
  }

  /// 下单
  Future<void> _placeOrder(Dish dish, OrderProvider orderProvider) async {
    final order = await orderProvider.placeOrder(dish);

    if (mounted) {
      if (order != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('#${order.ticketNumber} ${dish.name} 下单成功'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '预览',
              onPressed: () => _showPreview(order),
            ),
          ),
        );
      } else if (orderProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(orderProvider.error!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// 显示打印预览
  void _showPreview(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrintPreviewScreen(order: order),
      ),
    );
  }

  /// 处理重置取餐号
  Future<void> _handleReset(OrderProvider orderProvider) async {
    await orderProvider.resetTicketNumber();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('取餐号已重置为1'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 处理设置取餐号
  Future<void> _handleSetNumber(OrderProvider orderProvider, int number) async {
    await orderProvider.setTicketNumber(number);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('取餐号已设置为 $number'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}