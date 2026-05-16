import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/database/order_dao.dart';
import 'package:receipt_printing/providers/menu_provider.dart';
import 'package:receipt_printing/providers/order_provider.dart';
import 'package:receipt_printing/providers/printer_provider.dart';
import 'package:receipt_printing/screens/home_screen.dart';
import 'package:receipt_printing/services/bluetooth_connection_manager.dart';
import 'package:receipt_printing/services/menu_service.dart';
import 'package:receipt_printing/services/order_service.dart';
import 'package:receipt_printing/services/print_service.dart';
import 'package:receipt_printing/services/ticket_service.dart';

/// 应用根组件
///
/// 配置 MaterialApp 主题和路由。
///
/// 蓝牙生命周期：当 App 从后台恢复时，自动尝试重连打印机。
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // 创建服务实例
    final dishDao = DishDao();
    final orderDao = OrderDao();
    final ticketService = TicketService();
    final menuService = MenuService(dishDao);
    final orderService = OrderService(orderDao, ticketService);

    return _AppLifecycleObserver(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<MenuProvider>(
            create: (_) => MenuProvider(menuService),
          ),
          ChangeNotifierProvider<OrderProvider>(
            create: (_) => OrderProvider(orderService, ticketService),
          ),
          ChangeNotifierProvider<PrinterProvider>(
            create: (_) {
              final printService = PrintService();
              final provider = PrinterProvider(printService);
              // 启动时加载配置并尝试自动连接
              provider.initialize();
              return provider;
            },
          ),
        ],
        child: MaterialApp(
          title: '点单助手',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.orange,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}

/// 监听 App 生命周期，在 resumed 时自动重连蓝牙打印机
class _AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const _AppLifecycleObserver({required this.child});

  @override
  State<_AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<_AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final manager = BluetoothConnectionManager.instance;
      // 有保存地址且当前未连接时，自动尝试重连
      if (manager.savedAddress != null && !manager.isConnected) {
        manager.ensureConnected().catchError((_) {
          // 后台重连失败不打扰用户，下次打印时 ensureConnected 会再次尝试
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
