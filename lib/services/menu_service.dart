import 'package:receipt_printing/database/dish_dao.dart';

/// 菜单服务类
///
/// 提供菜品管理的高层业务逻辑，包括增删改查和排序功能
class MenuService {
  final DishDao _dishDao;

  MenuService(this._dishDao);

  /// 获取所有菜品
  ///
  /// 返回按 sort_order 排序的菜品列表
  Future<List<Dish>> getAllDishes() async {
    return await _dishDao.getAll();
  }

  /// 添加新菜品
  ///
  /// [name] 菜品名称（必填）
  /// [price] 价格（可选）
  /// [imagePath] 图片路径（可选）
  ///
  /// 抛出 [ArgumentError] 当名称为空时
  Future<Dish> addDish(String name, double? price, String? imagePath) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('菜品名称不能为空');
    }

    final now = DateTime.now();
    final dish = Dish(
      name: name.trim(),
      price: price,
      imagePath: imagePath,
      createdAt: now,
      updatedAt: now,
    );

    final id = await _dishDao.insert(dish);
    return dish.copyWith(id: id);
  }

  /// 更新菜品信息
  ///
  /// 抛出 [ArgumentError] 当 dish.id 为 null 时
  Future<void> updateDish(Dish dish) async {
    if (dish.id == null) {
      throw ArgumentError('更新操作需要 dish.id');
    }

    await _dishDao.update(dish);
  }

  /// 删除菜品
  ///
  /// [id] 菜品ID
  Future<void> deleteDish(int id) async {
    await _dishDao.delete(id);
  }

  /// 重新排序菜品
  ///
  /// [dishes] 按新顺序排列的菜品列表
  /// 根据列表索引更新每个菜品的 sort_order
  Future<void> reorderDishes(List<Dish> dishes) async {
    await _dishDao.updateSortOrder(dishes);
  }
}
