import 'package:flutter/material.dart';

/// 点单首页
///
/// 展示取餐号和菜品网格，是应用的核心界面
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('点单助手'),
      ),
      body: const Center(
        child: Text('欢迎使用点单助手'),
      ),
    );
  }
}
