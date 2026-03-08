import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/printer_config.dart';
import '../services/print_service.dart';
import '../utils/print_renderer.dart';
import '../utils/preview_renderer.dart';
import '../utils/preview_line.dart';
import '../utils/escpos_renderer.dart';

/// 打印预览页面
///
/// 展示小票预览样式并支持打印
class PrintPreviewScreen extends StatefulWidget {
  final Order order;

  const PrintPreviewScreen({
    super.key,
    required this.order,
  });

  @override
  State<PrintPreviewScreen> createState() => _PrintPreviewScreenState();
}

class _PrintPreviewScreenState extends State<PrintPreviewScreen> {
  late final PreviewRenderer _previewRenderer;
  late final PrintService _printService;
  PrinterConfig? _config;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _previewRenderer = PreviewRenderer();
    _printService = PrintService();

    // 加载预览数据
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    // 获取打印机配置
    _config = await _printService.getPrinterConfig();

    // 生成预览数据
    final printData = PrintData(
      ticketNumber: widget.order.ticketNumber,
      dishName: widget.order.dishName,
      shopName: _config?.printShopName == true ? _config?.shopName : null,
      dateTime: _config?.printDateTime == true ? widget.order.createdAt : null,
    );

    await _previewRenderer.render(printData);
  }

  @override
  void dispose() {
    _previewRenderer.dispose();
    _printService.dispose();
    super.dispose();
  }

  Widget _buildPreviewLine(PreviewLine line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        line.text,
        textAlign: line.alignment,
        style: TextStyle(
          fontSize: line.isLarge ? 24 : 14,
          fontWeight: line.isBold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _handlePrint() async {
    if (_isPrinting) return;

    setState(() {
      _isPrinting = true;
    });

    // 切换到真正的打印机渲染器
    final escposRenderer = ESCPOSRenderer();
    _printService.setRenderer(escposRenderer);

    try {
      // 如果未连接，先尝试连接
      if (!escposRenderer.isConnected && _config?.deviceAddress != null) {
        await escposRenderer.connect(_config!.deviceAddress!);
      }

      if (_config?.printTwoCopies == true) {
        await _printService.printTwoCopies(widget.order, _config!);
      } else {
        await _printService.printTicket(widget.order, _config!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('打印成功'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打印失败: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      await escposRenderer.dispose();
      setState(() {
        _isPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('打印预览'),
      ),
      body: StreamBuilder<List<PreviewLine>>(
        stream: _previewRenderer.linesStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lines = snapshot.data!;

          return Center(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 小票头部
                    const Icon(
                      Icons.receipt_long,
                      size: 32,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '预览',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const Divider(),
                    // 预览内容
                    ...lines.map((line) => _buildPreviewLine(line)),
                    const Divider(),
                    // 小票底部
                    Text(
                      _config?.deviceName ?? '未连接打印机',
                      style: TextStyle(
                        color: _config?.deviceName != null
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('返回'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isPrinting ? null : _handlePrint,
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print),
                  label: Text(_isPrinting ? '打印中...' : '打印'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}