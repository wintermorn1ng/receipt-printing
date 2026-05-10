import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/providers/menu_provider.dart';
import 'package:receipt_printing/screens/dish_edit_screen.dart';
import 'package:receipt_printing/widgets/dish_grid_item.dart';

/// 菜单管理页面
///
/// 提供菜品的增删改查和排序功能
class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  bool _isEditMode = false;

  // 内嵌添加表单
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;

  // 临时存储解析出的待添加菜品预览
  List<String> _previewNames = [];

  @override
  void initState() {
    super.initState();
    // 加载菜品数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MenuProvider>().loadDishes();
    });

    // 监听名称输入，实时解析逗号分隔的菜品
    _nameController.addListener(_updatePreviewNames);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updatePreviewNames);
    _nameController.dispose();
    super.dispose();
  }

  /// 更新预览的菜品名称列表
  void _updatePreviewNames() {
    final text = _nameController.text;
    if (text.isEmpty) {
      setState(() => _previewNames = []);
      return;
    }

    // 按逗号分隔，支持中英文逗号
    final names = text
        .split(RegExp(r'[,，]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // 只在变化时更新
    if (names.length != _previewNames.length ||
        !_listEquals(names, _previewNames)) {
      setState(() => _previewNames = names);
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('菜单管理'),
        actions: [
          // 排序/完成按钮
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
              });
            },
            icon: Icon(_isEditMode ? Icons.check : Icons.sort),
            label: Text(_isEditMode ? '完成' : '排序'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 内嵌添加表单
          _buildInlineAddForm(),

          // 菜品网格
          Expanded(
            child: Consumer<MenuProvider>(
              builder: (context, menuProvider, child) {
                if (menuProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final dishes = menuProvider.dishes;

                if (dishes.isEmpty) {
                  return _buildEmptyState();
                }

                return _isEditMode
                    ? _buildReorderableGrid(dishes)
                    : _buildNormalGrid(dishes);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 内嵌添加表单
  Widget _buildInlineAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 名称输入框 + 添加按钮
            Row(
              children: [
                // 名称输入框
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: '输入菜名（逗号分隔多个）',
                      prefixIcon: const Icon(Icons.restaurant_menu),
                      suffixIcon: _nameController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _nameController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _addDishes(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入菜名';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // 添加按钮
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _isAdding ? null : _addDishes,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: const Text('添加'),
                  ),
                ),
              ],
            ),

            // 批量添加预览
            if (_previewNames.length > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    '将添加 ${_previewNames.length} 个菜品：',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  ..._previewNames.take(5).map(
                        (name) => Chip(
                          label: Text(
                            name,
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  if (_previewNames.length > 5)
                    Text(
                      '...等${_previewNames.length}个',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 添加菜品
  Future<void> _addDishes() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final text = _nameController.text.trim();
    if (text.isEmpty) return;

    // 解析菜品名称列表
    final names = text
        .split(RegExp(r'[,，]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (names.isEmpty) return;

    setState(() => _isAdding = true);

    try {
      final count = await context.read<MenuProvider>().addDishes(
            names: names,
          );

      if (mounted) {
        // 清空表单
        _nameController.clear();

        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 1 ? '已添加 $count 个菜品' : '已添加: ${names.first}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('添加失败: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  /// 构建空状态提示
  Widget _buildEmptyState() {
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
            '在上方输入框添加菜品',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 构建普通网格（非编辑模式）
  Widget _buildNormalGrid(List<Dish> dishes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 根据屏幕宽度计算列数
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final aspectRatio = constraints.maxWidth > 600 ? 1.0 : 0.85;

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
            return DishGridItem(
              dish: dish,
              onTap: () => _navigateToEditDish(dish),
              onLongPress: () => _showDishOptions(dish),
            );
          },
        );
      },
    );
  }

  /// 构建可重排网格（编辑模式）
  Widget _buildReorderableGrid(List<Dish> dishes) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final aspectRatio = constraints.maxWidth > 600 ? 1.0 : 0.85;

        return ReorderableGridView.builder(
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
            return DishGridItem(
              key: ValueKey(dish.id),
              dish: dish,
              isDragging: false,
            );
          },
          onReorder: (oldIndex, newIndex) {
            context.read<MenuProvider>().reorderDishes(
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                );
          },
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Material(
                  elevation: 8 * animation.value,
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                );
              },
              child: child,
            );
          },
        );
      },
    );
  }

  /// 显示菜品操作选项
  void _showDishOptions(Dish dish) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToEditDish(dish);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(dish);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 确认删除对话框
  void _confirmDelete(Dish dish) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除"${dish.name}"吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteDish(dish.id!);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  /// 删除菜品
  Future<void> _deleteDish(int id) async {
    try {
      await context.read<MenuProvider>().deleteDish(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('菜品已删除')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  /// 导航到编辑菜品页面
  Future<void> _navigateToEditDish(Dish dish) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DishEditScreen(dish: dish),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('菜品已更新')),
      );
    }
  }
}

/// 可重排的网格视图
///
/// 包装 Flutter 的 ReorderableListView 实现网格拖拽排序
class ReorderableGridView extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ReorderCallback onReorder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsetsGeometry? padding;
  final ReorderItemProxyDecorator? proxyDecorator;

  const ReorderableGridView.builder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.onReorder,
    required this.gridDelegate,
    this.padding,
    this.proxyDecorator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding ?? EdgeInsets.zero,
          sliver: SliverGrid(
            gridDelegate: gridDelegate,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return ReorderableDragStartListener(
                  index: index,
                  child: itemBuilder(context, index),
                );
              },
              childCount: itemCount,
            ),
          ),
        ),
      ],
    );
  }
}
