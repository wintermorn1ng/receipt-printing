import 'package:flutter/material.dart';

/// 取餐号显示组件
///
/// 大号字体显示 #128 格式，点击弹出菜单：重置、设置起始号
class TicketNumberDisplay extends StatelessWidget {
  /// 当前取餐号
  final int ticketNumber;

  /// 重置回调
  final VoidCallback? onReset;

  /// 设置起始号回调
  final void Function(int number)? onSetNumber;

  const TicketNumberDisplay({
    super.key,
    required this.ticketNumber,
    this.onReset,
    this.onSetNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'reset',
          child: Row(
            children: [
              Icon(Icons.refresh),
              SizedBox(width: 12),
              Text('重置为1'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'set_number',
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 12),
              Text('设置起始号'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.confirmation_number,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              '#$ticketNumber',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'reset':
        _showResetConfirmDialog(context);
        break;
      case 'set_number':
        _showSetNumberDialog(context);
        break;
    }
  }

  void _showResetConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认重置'),
        content: const Text('确定要将取餐号重置为1吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onReset?.call();
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showSetNumberDialog(BuildContext context) {
    final controller = TextEditingController(text: ticketNumber.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置起始号'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '取餐号',
            hintText: '请输入起始号',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final number = int.tryParse(controller.text);
              if (number != null && number > 0) {
                Navigator.pop(context);
                onSetNumber?.call(number);
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }
}