import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/printer_provider.dart';
import 'print_preview_screen.dart';

/// 打印机设置页面
///
/// 管理蓝牙设备连接和小票打印配置
class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final TextEditingController _shopNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PrinterProvider>();
      _shopNameController.text = provider.config.shopName ?? '';
      provider.scanDevices();
    });
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('打印设置'),
      ),
      body: Consumer<PrinterProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 蓝牙打印机部分
              _buildSectionTitle('蓝牙打印机'),
              _buildBluetoothSection(provider),
              const SizedBox(height: 24),

              // 小票设置部分
              _buildSectionTitle('小票设置'),
              _buildTicketSettingsSection(provider),
              const SizedBox(height: 24),

              // 测试打印部分
              _buildSectionTitle('测试打印'),
              _buildTestPrintSection(provider),
              const SizedBox(height: 24),

              // 高级设置部分（预留）
              _buildSectionTitle('高级设置（预留）'),
              _buildAdvancedSection(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildBluetoothSection(PrinterProvider provider) {
    return Card(
      child: Column(
        children: [
          // 搜索按钮
          ListTile(
            leading: const Icon(Icons.bluetooth_searching),
            title: Text(provider.isScanning ? '搜索中...' : '搜索设备'),
            trailing: provider.isScanning
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onTap: provider.isScanning ? null : () => provider.scanDevices(),
          ),
          const Divider(height: 1),

          // 设备列表
          if (provider.devices.isEmpty && !provider.isScanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '未发现蓝牙设备，请点击搜索',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...provider.devices.map((device) {
              final isConnected = provider.connectedDeviceAddress == device.address;
              final isConnecting = provider.isConnecting;

              return ListTile(
                leading: Icon(
                  Icons.bluetooth,
                  color: isConnected ? Colors.green : Colors.blue,
                ),
                title: Text(device.name ?? '未知设备'),
                subtitle: Text(device.address),
                trailing: isConnected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : isConnecting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                onTap: isConnected || isConnecting
                    ? null
                    : () => _connectDevice(provider, device),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _connectDevice(PrinterProvider provider, BluetoothDevice device) async {
    final success = await provider.connect(device);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已连接到 ${device.name ?? "设备"}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('连接 ${device.name ?? "设备"} 失败'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildTicketSettingsSection(PrinterProvider provider) {
    return Card(
      child: Column(
        children: [
          // 打印店名开关
          SwitchListTile(
            title: const Text('打印店名'),
            value: provider.config.printShopName,
            onChanged: (value) => provider.togglePrintShopName(value),
          ),

          // 店名输入框
          if (provider.config.printShopName)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _shopNameController,
                decoration: const InputDecoration(
                  labelText: '店名',
                  hintText: '请输入店名',
                  isDense: true,
                ),
                onChanged: (value) => provider.updateShopName(value),
              ),
            ),

          const Divider(),

          // 打印日期时间开关
          SwitchListTile(
            title: const Text('打印日期时间'),
            value: provider.config.printDateTime,
            onChanged: (value) => provider.togglePrintDateTime(value),
          ),

          const Divider(),

          // 打印两联开关
          SwitchListTile(
            title: const Text('打印两联小票'),
            value: provider.config.printTwoCopies,
            onChanged: (value) => provider.togglePrintTwoCopies(value),
          ),
        ],
      ),
    );
  }

  Widget _buildTestPrintSection(PrinterProvider provider) {
    return Card(
      child: Column(
        children: [
          // 打印测试小票
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('打印测试小票'),
            subtitle: Text(
              provider.isConnected ? '已连接打印机' : '请先连接打印机',
              style: TextStyle(
                color: provider.isConnected ? Colors.green : Colors.orange,
              ),
            ),
            enabled: provider.isConnected,
            onTap: provider.isConnected
                ? () => _testPrint(provider)
                : null,
          ),
          const Divider(height: 1),
          // 预览测试小票
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('预览测试小票'),
            subtitle: const Text('查看小票样式'),
            onTap: () => _showPreview(),
          ),
        ],
      ),
    );
  }

  Future<void> _testPrint(PrinterProvider provider) async {
    try {
      await provider.testPrint();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('测试打印已发送'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('测试打印失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 显示预览测试小票
  void _showPreview() {
    // 创建一个测试订单用于预览
    final testOrder = Order(
      ticketNumber: 999,
      dishId: 0,
      dishName: '测试菜品',
      createdAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PrintPreviewScreen(order: testOrder),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: SwitchListTile(
        title: const Text('启用双打印机模式'),
        subtitle: const Text('（预留功能，暂不可用）'),
        value: false,
        onChanged: null, // 禁用
      ),
    );
  }
}