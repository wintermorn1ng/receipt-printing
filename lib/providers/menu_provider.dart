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
    String? abbreviation,
  }) async {
    _clearError();

    try {
      final dish = await _menuService.addDish(name, price, imagePath, abbreviation);
      _dishes.add(dish);
      notifyListeners();
    } catch (e) {
      _setError('添加菜品失败: $e');
      rethrow;
    }
  }

  /// 批量添加菜品
  ///
  /// [names] 菜品名称列表（支持逗号分隔）
  /// [price] 价格（可选，所有菜品共用）
  ///
  /// 返回成功添加的数量
  Future<int> addDishes({
    required List<String> names,
    double? price,
  }) async {
    _clearError();

    try {
      final dishes = await _menuService.addDishes(names, price);
      _dishes.addAll(dishes);
      notifyListeners();
      return dishes.length;
    } catch (e) {
      _setError('批量添加菜品失败: $e');
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

  /// 上移菜品
  ///
  /// 将指定索引的菜品与上一个交换位置
  Future<void> moveDishUp(int index) async {
    if (index <= 0 || index >= _dishes.length) return;

    final item = _dishes.removeAt(index);
    _dishes.insert(index - 1, item);

    try {
      await _menuService.reorderDishes(_dishes);
      notifyListeners();
    } catch (e) {
      _setError('上移失败: $e');
      await loadDishes();
      rethrow;
    }
  }

  /// 下移菜品
  ///
  /// 将指定索引的菜品与下一个交换位置
  Future<void> moveDishDown(int index) async {
    if (index < 0 || index >= _dishes.length - 1) return;

    final item = _dishes.removeAt(index);
    _dishes.insert(index + 1, item);

    try {
      await _menuService.reorderDishes(_dishes);
      notifyListeners();
    } catch (e) {
      _setError('下移失败: $e');
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
