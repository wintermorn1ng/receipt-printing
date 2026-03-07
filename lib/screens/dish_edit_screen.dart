import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:receipt_printing/database/dish_dao.dart';
import 'package:receipt_printing/providers/menu_provider.dart';
import 'package:receipt_printing/widgets/universal_image.dart';

/// 菜品编辑页面
///
/// 支持新增和编辑两种模式
/// - 新增模式：标题"添加菜品"
/// - 编辑模式：标题"编辑菜品"，填充已有数据
class DishEditScreen extends StatefulWidget {
  /// 要编辑的菜品（null 表示新增模式）
  final Dish? dish;

  const DishEditScreen({
    super.key,
    this.dish,
  });

  @override
  State<DishEditScreen> createState() => _DishEditScreenState();
}

class _DishEditScreenState extends State<DishEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String? _imagePath;
  bool _isSaving = false;

  bool get isEditMode => widget.dish != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _nameController.text = widget.dish!.name;
      if (widget.dish!.price != null) {
        // Format price: show as integer if no decimal part
        final price = widget.dish!.price!;
        _priceController.text = price == price.toInt()
            ? price.toInt().toString()
            : price.toString();
      }
      _imagePath = widget.dish!.imagePath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? '编辑菜品' : '添加菜品'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 图片选择区域
            _buildImageSection(),
            const SizedBox(height: 24),
            // 名称输入
            _buildNameField(),
            const SizedBox(height: 16),
            // 价格输入
            _buildPriceField(),
            const SizedBox(height: 32),
            // 保存按钮
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  /// 构建图片选择区域
  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: _imagePath != null && _imagePath!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: UniversalImage(
                  path: _imagePath!,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击添加图片（可选）',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 构建名称输入字段
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: '菜品名称',
        hintText: '请输入菜品名称',
        prefixIcon: const Icon(Icons.restaurant_menu),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '菜品名称不能为空';
        }
        return null;
      },
    );
  }

  /// 构建价格输入字段
  Widget _buildPriceField() {
    return TextFormField(
      controller: _priceController,
      decoration: InputDecoration(
        labelText: '价格（可选）',
        hintText: '请输入价格',
        prefixIcon: const Icon(Icons.attach_money),
        prefixText: '¥',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final price = double.tryParse(value);
          if (price == null) {
            return '请输入有效的数字';
          }
          if (price < 0) {
            return '价格不能为负数';
          }
        }
        return null;
      },
    );
  }

  /// 构建保存按钮
  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _saveDish,
      icon: _isSaving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.save),
      label: Text(_isSaving ? '保存中...' : '保存'),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// 选择图片
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  /// 保存菜品
  Future<void> _saveDish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      final priceText = _priceController.text.trim();
      final price = priceText.isEmpty ? null : double.parse(priceText);

      final menuProvider = context.read<MenuProvider>();

      if (isEditMode) {
        // 更新现有菜品
        final updatedDish = widget.dish!.copyWith(
          name: name,
          price: Value(price),
          imagePath: Value(_imagePath),
        );
        await menuProvider.updateDish(updatedDish);
      } else {
        // 添加新菜品
        await menuProvider.addDish(
          name: name,
          price: price,
          imagePath: _imagePath,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
