import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/database/order_dao.dart';
import 'package:receipt_printing/providers/menu_provider.dart';
import 'package:receipt_printing/providers/order_provider.dart';
import 'package:receipt_printing/providers/printer_provider.dart';
import 'package:receipt_printing/screens/home_screen.dart';
import 'package:receipt_printing/services/menu_service.dart';
import 'package:receipt_printing/services/order_service.dart';
import 'package:receipt_printing/services/print_service.dart';
import 'package:receipt_printing/services/ticket_service.dart';

/// 应用根组件
///
/// 配置 MaterialApp 主题和路由
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

    return MultiProvider(
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
            provider.loadConfig();
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
    );
  }
}