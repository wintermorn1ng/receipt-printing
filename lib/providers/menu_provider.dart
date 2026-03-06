import 'package:flutter/material.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/services/menu_service.dart';

/// 菜单状态管理类
///
/// 使用 ChangeNotifier 提供响应式的菜单数据管理
class MenuProvider extends ChangeNotifier {
  final MenuService _menuService;

  List<Dish> _dishes = [];
  bool _isLoading = false;
  String? _error;

  MenuProvider(this._menuService);

  /// 当前菜品列表
  List<Dish> get dishes => List.unmodifiable(_dishes);

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 错误信息
  String? get error => _error;

  /// 加载所有菜品
  Future<void> loadDishes() async {
    _setLoading(true);
    _clearError();

    try {
      _dishes = await _menuService.getAllDishes();
      notifyListeners();
    } catch (e) {
      _setError('加载菜品失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 添加新菜品
  ///
  /// [name] 菜品名称（必填）
  /// [price] 价格（可选）
  /// [imagePath] 图片路径（可选）
  Future<void> addDish({
    required String name,
    double? price,
    String? imagePath,
  }) async {
    _clearError();

    try {
      final dish = await _menuService.addDish(name, price, imagePath);
      _dishes.add(dish);
      notifyListeners();
    } catch (e) {
      _setError('添加菜品失败: $e');
      rethrow;
    }
  }

  /// 更新菜品
  ///
  /// [dish] 要更新的菜品对象
  Future<void> updateDish(Dish dish) async {
    _clearError();

    try {
      await _menuService.updateDish(dish);
      final index = _dishes.indexWhere((d) => d.id == dish.id);
      if (index != -1) {
        _dishes[index] = dish;
        notifyListeners();
      }
    } catch (e) {
      _setError('更新菜品失败: $e');
      rethrow;
    }
  }

  /// 删除菜品
  ///
  /// [id] 菜品ID
  Future<void> deleteDish(int id) async {
    _clearError();

    try {
      await _menuService.deleteDish(id);
      _dishes.removeWhere((d) => d.id == id);
      notifyListeners();
    } catch (e) {
      _setError('删除菜品失败: $e');
      rethrow;
    }
  }

  /// 重新排序菜品
  ///
  /// [oldIndex] 原位置索引
  /// [newIndex] 新位置索引
  Future<void> reorderDishes({
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < 0 ||
        oldIndex >= _dishes.length ||
        newIndex < 0 ||
        newIndex > _dishes.length) {
      return;
    }

    // ReorderableListView 的 newIndex 行为：
    // - 向上移动（oldIndex > newIndex）：newIndex 就是目标位置
    // - 向下移动（oldIndex < newIndex）：newIndex 已经考虑了移除元素的影响
    // 所以我们需要调整：只有当向下移动时才减1
    final adjustedNewIndex = oldIndex < newIndex ? newIndex - 1 : newIndex;

    final item = _dishes.removeAt(oldIndex);
    _dishes.insert(adjustedNewIndex, item);

    // 更新数据库中的排序
    try {
      await _menuService.reorderDishes(_dishes);
      notifyListeners();
    } catch (e) {
      _setError('更新排序失败: $e');
      // 恢复原始顺序
      await loadDishes();
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
