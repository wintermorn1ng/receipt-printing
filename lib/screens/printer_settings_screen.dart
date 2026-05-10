import 'package:flutter/material.dart';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/printer_provider.dart';
import '../services/bluetooth_connection_manager.dart';
import 'print_preview_screen.dart';

/// 打印机设置页面
///
/// 两大功能：
/// 1. [蓝牙配置] - 搜索设备、配置地址、自动重连状态展示
/// 2. [打印选项] - 店名、日期、两联等开关
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
              _buildSectionTitle('蓝牙打印机'),
              _buildBluetoothSection(provider),
              const SizedBox(height: 24),

              _buildSectionTitle('小票设置'),
              _buildTicketSettingsSection(provider),
              const SizedBox(height: 24),

              _buildSectionTitle('测试打印'),
              _buildTestPrintSection(provider),
              const SizedBox(height: 24),

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

  // ── 蓝牙配置区块 ──

  Widget _buildBluetoothSection(PrinterProvider provider) {
    return Card(
      child: Column(
        children: [
          // 连接状态头
          _buildConnectionStatusHeader(provider),
          const Divider(height: 1),

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
              final isThisDeviceConnected =
                  provider.savedAddress == device.address &&
                      provider.isConnected;
              final isThisDeviceConnecting =
                  provider.savedAddress == device.address &&
                      provider.isConnecting;

              return ListTile(
                leading: Icon(
                  Icons.bluetooth,
                  color: isThisDeviceConnected ? Colors.green : Colors.blue,
                ),
                title:
                    Text(device.name.isNotEmpty ? device.name : '未知设备'),
                subtitle: Text(device.address),
                trailing: isThisDeviceConnected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 4),
                          const Text('已连接',
                              style: TextStyle(color: Colors.green)),
                        ],
                      )
                    : isThisDeviceConnecting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                onTap: isThisDeviceConnected || isThisDeviceConnecting
                    ? null
                    : () => _configurePrinter(provider, device),
              );
            }),

          // 已连接时的操作按钮
          if (provider.isConnected) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.link_off, color: Colors.orange),
              title: const Text('断开连接'),
              subtitle: Text('当前: ${provider.savedName ?? provider.savedAddress}'),
              onTap: () => _showDisconnectDialog(provider),
            ),
          ],

          // 连接错误时显示重连按钮
          if (provider.isConnectionError) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('连接失败'),
              subtitle: Text('已保存: ${provider.savedName ?? provider.savedAddress}'),
              trailing: TextButton(
                onPressed: () => provider.ensureConnected(),
                child: const Text('重试'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 连接状态头部
  Widget _buildConnectionStatusHeader(PrinterProvider provider) {
    final state = provider.connectionState;
    final name = provider.savedName;
    final address = provider.savedAddress;

    IconData icon;
    Color color;
    String text;
    String? subtext;

    switch (state) {
      case BluetoothConnectionState.connected:
        icon = Icons.bluetooth_connected;
        color = Colors.green;
        text = '已连接';
        subtext = name ?? address;
      case BluetoothConnectionState.connecting:
        icon = Icons.bluetooth_searching;
        color = Colors.blue;
        text = '连接中...';
        subtext = address;
      case BluetoothConnectionState.connectionError:
        icon = Icons.bluetooth_disabled;
        color = Colors.red;
        text = '连接失败';
        subtext = '点击重试或搜索新设备';
      case BluetoothConnectionState.disconnected:
        if (address != null) {
          icon = Icons.bluetooth_disabled;
          color = Colors.orange;
          text = '未连接';
          subtext = '已保存: $name';
        } else {
          icon = Icons.bluetooth_disabled;
          color = Colors.grey;
          text = '未配置';
          subtext = '搜索设备以配置打印机';
        }
    }

    return Container(
      color: color.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: subtext != null ? Text(subtext) : null,
        trailing: state == BluetoothConnectionState.connectionError
            ? TextButton(
                onPressed: () => provider.ensureConnected(),
                child: const Text('重试'),
              )
            : state == BluetoothConnectionState.connected
                ? TextButton(
                    onPressed: () => provider.disconnect(),
                    child: const Text('断开'),
                  )
                : null,
      ),
    );
  }

  Future<void> _configurePrinter(
      PrinterProvider provider, BluetoothDevice device) async {
    try {
      await provider.configurePrinter(device);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '已配置打印机: ${device.name.isNotEmpty ? device.name : "设备"}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('配置失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showDisconnectDialog(PrinterProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('断开连接'),
        content: Text(
            '确定断开与 ${provider.savedName ?? provider.savedAddress} 的连接吗？\n地址仍会保存，下次打开 APP 会自动重连。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('断开'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.disconnect();
    }
  }

  // ── 打印选项区块 ──

  Widget _buildTicketSettingsSection(PrinterProvider provider) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('打印店名'),
            value: provider.config.printShopName,
            onChanged: (value) => provider.togglePrintShopName(value),
          ),
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
          SwitchListTile(
            title: const Text('打印日期时间'),
            value: provider.config.printDateTime,
            onChanged: (value) => provider.togglePrintDateTime(value),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('打印两联小票'),
            value: provider.config.printTwoCopies,
            onChanged: (value) => provider.togglePrintTwoCopies(value),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('打印诗词'),
            subtitle: const Text('小票末尾打印一句古诗词'),
            value: provider.config.printPoetry,
            onChanged: (value) => provider.togglePrintPoetry(value),
          ),
          const Divider(),
          ListTile(
            title: const Text('切纸前进纸行数'),
            subtitle: Text(
              '当前: ${provider.config.printGapLines} 行（约 ${(provider.config.printGapLines * 0.75).toStringAsFixed(1)}mm）',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('0'),
                Expanded(
                  child: Slider(
                    value: provider.config.printGapLines.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '${provider.config.printGapLines} 行',
                    onChanged: (value) =>
                        provider.updatePrintGapLines(value.round()),
                  ),
                ),
                const Text('10'),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('票间间距行数'),
            subtitle: Text(
              '打印两联时，两张票之间的间距。当前: ${provider.config.printTicketGapLines} 行（约 ${(provider.config.printTicketGapLines * 0.75).toStringAsFixed(1)}mm）',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('0'),
                Expanded(
                  child: Slider(
                    value: provider.config.printTicketGapLines.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: '${provider.config.printTicketGapLines} 行',
                    onChanged: (value) =>
                        provider.updatePrintTicketGapLines(value.round()),
                  ),
                ),
                const Text('10'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 测试打印区块 ──

  Widget _buildTestPrintSection(PrinterProvider provider) {
    final canPrint = provider.isConnected;

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('打印测试小票'),
            subtitle: Text(
              canPrint ? '已连接打印机' : '请先配置并连接打印机',
              style: TextStyle(
                color: canPrint ? Colors.green : Colors.orange,
              ),
            ),
            enabled: canPrint,
            onTap: canPrint ? () => _testPrint(provider) : null,
          ),
          const Divider(height: 1),
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
            content: Text('测试打印失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPreview() {
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

  // ── 高级设置区块 ──

  Widget _buildAdvancedSection() {
    return Card(
      child: SwitchListTile(
        title: const Text('启用双打印机模式'),
        subtitle: const Text('（预留功能，暂不可用）'),
        value: false,
        onChanged: null,
      ),
    );
  }
}
