import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order.dart';
import '../providers/printer_provider.dart';
import '../services/poetry_service.dart';
import '../utils/print_renderer.dart';
import '../utils/preview_renderer.dart';
import '../utils/preview_line.dart';
import '../services/bluetooth_connection_manager.dart';

/// 打印预览页面
///
/// 展示小票预览样式并支持打印。
///
/// 打印时通过 [PrinterProvider.ensureConnected] 确保连接后发送。
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
  final PoetryService _poetryService = PoetryService();
  bool _isPrinting = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _previewRenderer = PreviewRenderer();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    final provider = context.read<PrinterProvider>();
    final config = provider.config;

    final poem = config.printPoetry ? _poetryService.getPoem(date: DateTime.now()) : null;

    final printData = PrintData(
      ticketNumber: widget.order.ticketNumber,
      dishName: widget.order.dishName,
      shopName: config.printShopName ? config.shopName : null,
      dateTime: config.printDateTime ? widget.order.createdAt : null,
      gapLines: config.printGapLines,
      poetryText: poem?.text,
    );

    await _previewRenderer.render(printData);
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  @override
  void dispose() {
    _previewRenderer.dispose();
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
          color: line.isDimmed ? Colors.grey : Colors.black,
        ),
      ),
    );
  }

  Future<void> _handlePrint() async {
    if (_isPrinting) return;

    final provider = context.read<PrinterProvider>();

    setState(() => _isPrinting = true);

    try {
      // 确保已连接
      await provider.ensureConnected();

      // 打印
      if (provider.config.printTwoCopies) {
        await provider.printOrderTwoCopies(widget.order);
      } else {
        await provider.printOrder(widget.order);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('打印成功'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on PrintException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打印失败: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('打印失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
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
          if (!_isInitialized || !snapshot.hasData) {
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
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long, size: 32, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text(
                      '预览',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const Divider(),
                    ...lines.map((line) => _buildPreviewLine(line)),
                    const Divider(),
                    Consumer<PrinterProvider>(
                      builder: (context, provider, _) {
                        final name = provider.savedName;
                        final state = provider.connectionState;

                        String text;
                        Color color;

                        if (state == BluetoothConnectionState.connected) {
                          text = name ?? '已连接';
                          color = Colors.green;
                        } else if (state == BluetoothConnectionState.connecting) {
                          text = '连接中...';
                          color = Colors.orange;
                        } else if (state == BluetoothConnectionState.connectionError) {
                          text = '连接失败';
                          color = Colors.red;
                        } else {
                          text = '未配置打印机';
                          color = Colors.grey;
                        }

                        return Text(
                          text,
                          style: TextStyle(color: color, fontSize: 12),
                        );
                      },
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
                child: Consumer<PrinterProvider>(
                  builder: (context, provider, _) {
                    final canPrint = provider.isConnected;

                    return FilledButton.icon(
                      onPressed: canPrint && !_isPrinting ? _handlePrint : null,
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
