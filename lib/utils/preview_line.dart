import 'package:flutter/material.dart';

/// 预览线条数据模型
///
/// 用于预览页面展示小票内容
class PreviewLine {
  /// 文本内容
  final String text;

  /// 对齐方式
  final TextAlign alignment;

  /// 是否大号字体（取餐号）
  final bool isLarge;

  /// 是否粗体
  final bool isBold;

  const PreviewLine(
    this.text, {
    this.alignment = TextAlign.center,
    this.isLarge = false,
    this.isBold = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewLine &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          alignment == other.alignment &&
          isLarge == other.isLarge &&
          isBold == other.isBold;

  @override
  int get hashCode => Object.hash(text, alignment, isLarge, isBold);

  @override
  String toString() {
    return 'PreviewLine(text: $text, alignment: $alignment, '
        'isLarge: $isLarge, isBold: $isBold)';
  }
}