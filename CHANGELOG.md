# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-05-16

### Added
- feat: 支持调整点单页面菜品网格列数（默认2列，可切换为3列/4列），偏好通过 SharedPreferences 持久化

## [1.0.0] - 2026-05-16

### Added
- 优化 APK 体积

### Changed
- feat: 支持小票显示诗词
- feat: update add dish logic

### Fixed
- fix: add gap in two ticket
- fix: test code issues
- fix: 蓝牙连接状态机重构 + 修复中文打印乱码
  - 新增 BluetoothConnectionManager 单例，统一管理连接状态机（disconnected/connecting/connected/connectionError）、持久化和指数退避自动重连
  - PrinterProvider 代理 ConnectionManager 状态，职责分离
  - 修复 startScan 返回值类型推断为 dynamic 导致设备列表为空
  - 反编译 EscCommand.class 确认 addText() 使用 GB18030 编码，PrintFormatter 全部改为 CharsetConverter.encode(gbk)
  - EscposRenderer/PrintService 移除冗余自动连接逻辑

## [0.1.0] - 2026-03-09

### Added
- feat: 实现 T8 蓝牙打印机设置功能
  - 添加蓝牙权限到 AndroidManifest.xml（BLUETOOTH、BLUETOOTH_ADMIN 等）
  - 在主页添加蓝牙连接状态图标，显示打印机连接状态
  - 添加 PrinterProvider 单元测试，覆盖配置、连接、打印等场景
- feat: 实现日总结功能
  - 新增 DailySummaryScreen 页面，展示订单统计
  - 新增 SummaryService 服务层，提供日总结数据查询
  - OrderDao 新增 getAvailableDates 方法支持日期列表查询
  - 添加 SummaryService 单元测试，覆盖正常路径和异常情况
  - 添加 mockito 依赖用于测试
- feat: 实现 T6 小票打印功能
  - 添加打印工具类（ESC/POS 指令生成、渲染器模式）
  - 添加打印服务和 Provider
  - 添加打印预览页面和打印机设置页面
  - 集成到下单流程，下单成功后可预览
  - 添加单元测试覆盖
- feat: add print preview feature to T6 spec
  - Add renderer pattern for print functionality: Abstract PrintRenderer base class, ESCPOSRenderer for Bluetooth printing, PreviewRenderer for on-screen preview
- docs: 添加 Patrol E2E 测试配置说明
  - 在 T9 集成测试文档中添加 Patrol 测试框架的配置指南，包括安装步骤、示例测试代码、运行命令和适用场景
- 添加数据库抽象层，支持 Web 平台
  - 新增 DatabaseRepository 抽象接口
  - 实现 SqfliteRepository (IO 平台) 和 InMemoryRepository (Web 平台)
  - DAO 层现在与具体数据库实现解耦

## [0.0.1] - 2026-03-01

### Added
- init repo
- add spec
