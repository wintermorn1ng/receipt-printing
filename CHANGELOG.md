# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-5-17

### Fixed
- fix: 修复 release build 在 Android 15 (API 35) 上蓝牙无法连接
  - 根因：`AndroidManifest.xml` 中 `BLUETOOTH_SCAN` 缺少 `android:usesPermissionFlags="neverForLocation"`
  - Android 12+ 引入此标记：未声明时系统认为蓝牙扫描依赖位置权限，用户拒绝位置权限则蓝牙扫描一并被阻断
  - Android 15 对此限制检查更严格，debug build 因 adb 自动授予权限可以工作，release 侧载安装则失败
  - 修复：为 `BLUETOOTH_SCAN` 添加 `usesPermissionFlags="neverForLocation"`，告知系统此应用不从蓝牙获取位置
  - 验证：`flutter build apk --release` 通过，`aapt` 确认 `usesPermissionFlags=0x10000` 已进入最终 APK


## [1.0.1] - 2026-05-16

### Added
- feat: 菜单管理页面新增导出按钮，点击可将所有菜名复制到剪贴板（中文逗号分隔）
- feat: 菜单管理页面支持上下箭头按钮调整菜品顺序，替换拖拽排序为更简单的上移/下移按钮
- feat: 支持调整点单页面菜品网格列数（默认2列，可切换为3列/4列），偏好通过 SharedPreferences 持久化
- feat: 菜单项支持缩写设置，默认为菜单名第一个字，可自定义
  - Dish 模型新增 `abbreviation` 字段和 `effectiveAbbreviation` getter
  - 数据库 dishes 表新增 `abbreviation` 列，版本升至 2
  - 编辑页面新增缩写输入框（最多 4 字符，可选）
  - 无图片时网格项显示缩写大字取代原来的图标占位
- feat: App 从后台恢复时自动尝试蓝牙重连（`WidgetsBindingObserver`）

### Fixed
- fix: 蓝牙连接管理器重构，修复 6 个稳定性问题
  - `ensureConnected()` 现在保证返回时连接已建立或所有重试耗尽（不再提前返回假成功）
  - 添加并发连接锁，防止多个 `ensureConnected()` 调用产生竞态
  - `_connectDirect` 添加 8 秒超时保护，防止蓝牙栈挂起
  - `_saveAddress` 先写 SharedPreferences 再更新内存，保证一致性
  - `_cancelRetry` 不再重置重试计数，退避策略保持连续性
  - 重试循环从递归 Timer 改为 `_connectWithRetry` 内部 while 循环，逻辑更清晰
- fix: `renderTwoCopies` 在第一联打印后验证连接状态，防止半截打印

### Changed
- `ESCPOSRenderer.connect()` / `disconnect()` 标记为 `@Deprecated`，委托给 `BluetoothConnectionManager`
- ci: 添加 GitHub Actions 构建 APK 工作流（`.github/workflows/build-apk.yml`）

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
