import 'dart:io';

import 'package:flutter/material.dart';
import 'package:receipt_printing/database/dish_dao.dart';

/// 菜品网格项组件
///
/// 用于在网格布局中展示单个菜品信息
/// 支持点击和长按操作
class DishGridItem extends StatelessWidget {
  /// 要显示的菜品
  final Dish dish;

  /// 点击回调
  final VoidCallback? onTap;

  /// 长按回调
  final VoidCallback? onLongPress;

  /// 是否处于拖拽状态
  final bool isDragging;

  const DishGridItem({
    super.key,
    required this.dish,
    this.onTap,
    this.onLongPress,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isDragging ? 8 : 2,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 图片区域
            Expanded(
              child: _buildImageArea(theme),
            ),
            // 文字信息区域
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 菜品名称
                  Text(
                    dish.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // 价格（如果有）
                  if (dish.price != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '¥${dish.price!.toStringAsFixed(dish.price!.truncateToDouble() == dish.price! ? 0 : 1)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图片显示区域
  Widget _buildImageArea(ThemeData theme) {
    if (dish.imagePath != null && dish.imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
        child: Image.file(
          File(dish.imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(theme);
          },
        ),
      );
    }
    return _buildPlaceholder(theme);
  }

  /// 构建占位图
  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }
}
