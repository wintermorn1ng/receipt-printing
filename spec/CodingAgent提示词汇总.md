# Coding Agent 提示词汇总

本文档包含每个开发任务驱动 coding agent 的详细提示词。

---

## T1: 项目初始化与依赖配置

```
你是一个 Flutter 开发专家。请根据以下设计文档初始化一个 Flutter 项目：

## 参考文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/设计spec.md
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/菜单功能 spec.md
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/点单功能 spec.md
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/小票打印功能 spec.md
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/日总结功能 spec.md
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/开发计划.md

## 任务目标
创建 Flutter 项目基础结构，配置必要依赖。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 具体步骤
1. 执行 `flutter create .` 创建项目（如果已存在则跳过）
2. 修改 pubspec.yaml，添加以下依赖：
   - sqflite: ^2.3.0
   - path_provider: ^2.1.1
   - flutter_bluetooth_serial: ^0.4.0
   - provider: ^6.1.1
   - intl: ^0.18.1
   - path: ^1.8.3
3. 创建目录结构：
   - lib/models/
   - lib/database/
   - lib/services/
   - lib/providers/
   - lib/screens/
   - lib/widgets/common/
   - lib/utils/
4. 创建 lib/main.dart，包含简单的 MaterialApp 入口
5. 创建 lib/app.dart，配置应用主题（主色调建议使用橙色或蓝色，符合餐饮应用风格）

## 输出文件
- pubspec.yaml（配置好依赖）
- lib/main.dart
- lib/app.dart
- 所有目录已创建

## 注意事项
- 确保依赖版本兼容 Flutter 3.x
- 应用名称设置为"点单助手"
- 支持横屏和竖屏（平板和手机都可用）
- 执行 `flutter pub get` 验证依赖安装成功

完成后报告：创建的文件列表和依赖版本。
```

---

## T2: 数据库设计与实现

```
你是一个 Flutter 开发专家，擅长 SQLite 数据库设计。请实现数据库层。

## 参考文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/开发计划.md（T2 部分的数据库表结构）
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/菜单功能 spec.md（菜品数据结构）
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/点单功能 spec.md（订单数据结构）

## 任务目标
实现 SQLite 数据库帮助类和数据访问对象(DAO)。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 数据库表结构

### dishes 表
- id: INTEGER PRIMARY KEY AUTOINCREMENT
- name: TEXT NOT NULL（菜品名称）
- price: REAL（价格，可为null）
- image_path: TEXT（图片路径，可为null）
- sort_order: INTEGER DEFAULT 0（排序顺序）
- created_at: INTEGER NOT NULL（Unix时间戳毫秒）
- updated_at: INTEGER NOT NULL（Unix时间戳毫秒）

### orders 表
- id: INTEGER PRIMARY KEY AUTOINCREMENT
- ticket_number: INTEGER NOT NULL（取餐号）
- dish_id: INTEGER NOT NULL（菜品ID）
- dish_name: TEXT NOT NULL（菜品名称，快照）
- created_at: INTEGER NOT NULL（Unix时间戳毫秒）
- date: TEXT NOT NULL（格式：YYYY-MM-DD，用于快速按日期查询）

### settings 表
- key: TEXT PRIMARY KEY
- value: TEXT

## 需要创建的类

### 1. DatabaseHelper（单例模式）
位置：lib/database/database_helper.dart
功能：
- 数据库初始化和版本管理
- 创建表结构
- 数据库升级处理

### 2. DishDao
位置：lib/database/dish_dao.dart
方法：
- Future<int> insert(Dish dish)
- Future<int> update(Dish dish)
- Future<int> delete(int id)
- Future<Dish?> getById(int id)
- Future<List<Dish>> getAll()
- Future<List<Dish>> getAllSorted()
- Future<int> getMaxSortOrder()

### 3. OrderDao
位置：lib/database/order_dao.dart
方法：
- Future<int> insert(Order order)
- Future<List<Order>> getByDate(String date) // 格式 YYYY-MM-DD
- Future<int> getCountByDate(String date)
- Future<Map<String, int>> getDishCountByDate(String date) // key: dishName, value: count
- Future<Map<int, int>> getHourlyDistribution(String date) // key: hour(0-23), value: count

## 代码规范
- 使用 sqflite 包
- DatabaseHelper 使用单例模式
- 所有方法都要有异常处理
- 使用事务处理批量操作
- 添加适当的日志输出（debug 模式）

## 输出文件
- lib/database/database_helper.dart
- lib/database/dish_dao.dart
- lib/database/order_dao.dart

## 验收标准
- 数据库能正常初始化
- 所有 DAO 方法可通过简单测试
- 正确处理日期索引优化
```

---

## T3: 数据模型定义

```
你是一个 Flutter 开发专家，擅长数据模型设计。请定义所有数据模型类。

## 参考文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/菜单功能 spec.md（菜品数据结构）
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/点单功能 spec.md（订单数据结构）
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/日总结功能 spec.md（日总结数据结构）
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/小票打印功能 spec.md（打印机配置）

## 任务目标
创建所有数据模型类，包含序列化和不可变更新方法。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 需要创建的模型

### 1. Dish（菜品）
位置：lib/models/dish.dart
字段：
- final int? id;
- final String name;
- final double? price;
- final String? imagePath;
- final int sortOrder;
- final DateTime createdAt;
- final DateTime updatedAt;

### 2. Order（订单）
位置：lib/models/order.dart
字段：
- final int? id;
- final int ticketNumber;
- final int dishId;
- final String dishName;
- final DateTime createdAt;

方法：
- String get date => DateFormat('yyyy-MM-dd').format(createdAt);

### 3. DailySummary（日总结）
位置：lib/models/daily_summary.dart
字段：
- final DateTime date;
- final int totalOrders;
- final List<DishSummary> dishSummaries;
- final Map<int, int> hourlyDistribution;

### 4. DishSummary（菜品销量）
位置：lib/models/daily_summary.dart（内部类或独立文件）
字段：
- final int dishId;
- final String dishName;
- final int count;

### 5. PrinterConfig（打印机配置）
位置：lib/models/printer_config.dart
字段：
- final String? deviceAddress; // 蓝牙设备地址
- final String? deviceName;    // 蓝牙设备名称
- final bool printShopName;    // 是否打印店名
- final String? shopName;      // 店名内容
- final bool printTime;        // 是否打印时间
- final bool dualPrinterMode;  // 是否双打印机模式（预留）
- final String? kitchenPrinterAddress; // 厨房打印机地址（预留）

## 代码规范
- 所有字段使用 final（不可变）
- 实现 == 和 hashCode（可使用 equatable 或手动实现）
- 实现 copyWith 方法用于更新
- 实现 toJson/fromJson 用于数据库序列化
- 使用 @immutable 注解
- 添加适当的文档注释

## 输出文件
- lib/models/dish.dart
- lib/models/order.dart
- lib/models/daily_summary.dart
- lib/models/printer_config.dart

## 验收标准
- 所有模型可通过 copyWith 更新
- toJson/fromJson 能正确处理 null 值
- 相等性判断工作正常
```

---

## T4: 菜单管理功能

```
你是一个 Flutter 开发专家，擅长 UI 开发和状态管理。请实现菜单管理功能。

## 参考文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/菜单功能 spec.md
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/开发计划.md（T4 部分）

## 依赖检查
请先检查以下文件是否存在，如果存在则参考：
- lib/models/dish.dart
- lib/database/dish_dao.dart
- lib/app.dart（主题配置）

## 任务目标
实现菜单管理页面，包括增删改查和排序功能。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 需要创建的组件

### 1. MenuService
位置：lib/services/menu_service.dart
功能：
- 获取所有菜品（排序后）
- 添加菜品
- 更新菜品
- 删除菜品
- 调整排序（交换两个菜品的 sort_order）

### 2. MenuProvider
位置：lib/providers/menu_provider.dart
使用 ChangeNotifier 管理状态：
- 菜品列表
- 加载状态
- 错误信息
- 当前编辑的菜品

### 3. MenuManagementScreen
位置：lib/screens/menu_management_screen.dart
UI：
- AppBar：标题"菜单管理"，右侧添加按钮(+)
- 主体：GridView 展示菜品（2-3列，根据屏幕宽度自适应）
- 每个菜品卡片显示：名称、价格（如有）、图片（如有）
- 空状态提示"暂无菜品，点击右上角添加"
- 长按菜品弹出菜单：编辑、删除、调整位置
- 拖拽排序功能（ReorderableGridView 或类似实现）

### 4. DishEditScreen / DishEditDialog
位置：lib/screens/dish_edit_screen.dart 或使用 Dialog
表单字段：
- 名称（必填，TextFormField with validator）
- 价格（可选，数字键盘）
- 图片（可选，使用 image_picker 选择本地图片）
- 底部：取消、保存按钮

### 5. DishGridItem
位置：lib/widgets/dish_grid_item.dart
- 接收 Dish 对象
- 显示名称（最多两行，溢出省略）
- 显示价格（如有）
- 显示图片（如有）或默认图标
- 支持长按菜单

## UI/UX 要求
- 网格布局：手机 2 列，平板 3-4 列
- 卡片要有足够的点击区域（最小 80x80）
- 添加/编辑成功后显示 SnackBar 提示
- 删除前显示确认对话框
- 图片使用本地文件路径，显示时使用 Image.file

## 代码规范
- 使用 Provider 进行状态管理
- 服务层处理业务逻辑，UI 层只负责展示
- 表单验证在提交时触发
- 异步操作显示加载状态

## 输出文件
- lib/services/menu_service.dart
- lib/providers/menu_provider.dart
- lib/screens/menu_management_screen.dart
- lib/screens/dish_edit_screen.dart（或 Dialog 实现）
- lib/widgets/dish_grid_item.dart

## 验收标准
- 可以添加、编辑、删除菜品
- 菜品按 sort_order 排序显示
- 可以拖拽调整顺序
- 表单验证正常工作
- 图片选择和显示正常
```

---

## T5: 点单首页（含取餐号）

```
你是一个 Flutter 开发专家，擅长 UI 开发和状态管理。请实现核心点单功能。

## 参考文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/点单功能 spec.md（核心参考）
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/开发计划.md（T5 部分）

## 依赖检查
请先检查以下文件是否存在，如果存在则参考：
- lib/models/dish.dart
- lib/models/order.dart
- lib/database/order_dao.dart
- lib/services/menu_service.dart
- lib/widgets/dish_grid_item.dart

## 任务目标
实现点单首页，这是应用的核心页面。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 界面布局（严格按照此设计）

```
┌─────────────────────────────────────┐
│  [#128] 当前取餐号        [重置▼]   │  ← 顶部区域，大号字体显示取餐号
├─────────────────────────────────────┤
│  ┌─────────┐  ┌─────────┐           │  ← 菜品网格（大按钮）
│  │         │  │         │           │
│  │  牛肉面  │  │  炸酱面  │           │
│  │  ¥15    │  │  ¥12    │           │
│  │         │  │         │           │
│  └─────────┘  └─────────┘           │
│  ┌─────────┐  ┌─────────┐           │
│  │  酸辣粉  │  │  豆浆    │           │
│  │  ¥10    │  │  ¥3     │           │
│  └─────────┘  └─────────┘           │
│           ...                       │
├─────────────────────────────────────┤
│  [菜单管理]  [打印设置]  [日总结]    │  ← 底部导航栏
└─────────────────────────────────────┘
```

## 需要创建的组件

### 1. TicketService
位置：lib/services/ticket_service.dart
功能：
- 获取当前取餐号
- 递增取餐号
- 重置取餐号（自动和手动）
- 设置起始号
- 检查是否需要自动重置（跨天检测）
- 使用 settings 表持久化存储当前取餐号和最后使用日期

方法：
- Future<int> getCurrentNumber()
- Future<int> nextNumber()
- Future<void> reset()
- Future<void> setStartNumber(int number)
- Future<void> checkAndAutoReset()

### 2. OrderService
位置：lib/services/order_service.dart
功能：
- 创建订单（传入 dishId）
- 获取今日订单数

创建订单流程：
1. 获取菜品信息
2. 获取当前取餐号
3. 创建 Order 对象
4. 保存到数据库
5. 递增取餐号
6. 触发打印（调用 PrintService）
7. 返回订单

### 3. OrderProvider
位置：lib/providers/order_provider.dart
状态：
- 当前取餐号
- 菜品列表
- 今日订单数
- 打印状态（可选）

### 4. HomeScreen
位置：lib/screens/home_screen.dart

顶部区域（TicketNumberDisplay）：
- 大号字体显示 #当前取餐号
- 右侧下拉菜单按钮：
  - 重置为 1（带确认对话框）
  - 设置起始号（弹出数字输入框）
- 每天首次启动自动重置提示（可选）

主体区域：
- GridView 展示菜品（与菜单管理类似，但更大按钮）
- 每个按钮占满网格单元，文字居中
- 点击菜品立即执行下单流程

底部导航栏：
- 使用 BottomNavigationBar 或自定义
- 三个选项：菜单管理、打印设置、日总结
- 点击切换到对应页面

下单反馈：
- 显示 Toast："#128 牛肉面 下单成功"
- 使用 fluttertoast 或自定义 Overlay

### 5. TicketNumberDisplay
位置：lib/widgets/ticket_number_display.dart
- 显示格式："#128"
- 字体要大而醒目（建议 48-64pt）
- 包含下拉菜单按钮

## 取餐号逻辑

### 自动重置检测
```dart
// 伪代码
Future<void> checkAndAutoReset() async {
  final lastDate = await getLastUsedDate(); // 从 settings 读取
  final today = DateTime.now().toDateString();
  if (lastDate != today) {
    await reset(); // 重置为 1
    await setLastUsedDate(today);
  }
}
```

### 重置确认对话框
```
┌────────────────────────────┐
│        确认重置            │
│  当前取餐号为 #15          │
│  重置后将变为 #1           │
│                            │
│   [取消]      [确认重置]   │
└────────────────────────────┘
```

## 代码规范
- 下单操作要异步执行，不阻塞 UI
- 显示加载指示器（可选，因为很快）
- 错误处理：显示 AlertDialog

## 输出文件
- lib/services/ticket_service.dart
- lib/services/order_service.dart
- lib/providers/order_provider.dart
- lib/screens/home_screen.dart
- lib/widgets/ticket_number_display.dart

## 验收标准
- 点击菜品立即创建订单
- 取餐号正确递增
- 每天首次启动自动重置
- 手动重置有二次确认
- 可以设置起始号
- 下单有成功反馈
- 底部导航可切换页面
```

---

## T6: 小票打印功能

```
你是一个 Flutter 开发专家，熟悉 ESC/POS 打印协议。请实现蓝牙打印功能。

## 参考文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/小票打印功能 spec.md（核心参考）
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/开发计划.md（T6 部分）

## 依赖检查
请先检查以下文件是否存在，如果存在则参考：
- lib/models/order.dart
- lib/models/printer_config.dart

## 任务目标
实现 ESC/POS 蓝牙打印服务。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 技术方案

使用 flutter_bluetooth_serial 包进行蓝牙通信，手动构建 ESC/POS 指令。

ESC/POS 关键指令：
- 初始化：0x1B 0x40
- 对齐：0x1B 0x61 (0左 1中 2右)
- 字体大小：0x1D 0x21 (0x00正常 0x11双倍高宽)
- 切纸：0x1D 0x56 0x00
- 换行：0x0A

## 需要创建的组件

### 1. PrintFormatter
位置：lib/utils/print_formatter.dart
功能：构建 ESC/POS 字节数据

方法：
- List<int> buildTicketContent(Order order, PrinterConfig config)
  - 店名（如配置）：居中，正常大小
  - 分隔线：--------
  - 取餐号：居中大号字体（双倍高宽）
  - 分隔线
  - 菜品名：居中
  - 时间（如配置）：居中小字体
  - 换行 + 切纸指令

### 2. PrintService
位置：lib/services/print_service.dart

状态：
- BluetoothConnection? currentConnection
- bool isConnected
- PrinterConfig config

方法：
- Future<bool> connect(String address)
- Future<void> disconnect()
- Future<void> printTicket(Order order)
- Future<List<BluetoothDevice>> scanDevices()
- Future<void> loadSavedPrinter()
- Future<void> savePrinterConfig(PrinterConfig config)
- Future<PrintResult> checkStatus()

打印流程：
1. 检查连接状态，未连接则尝试重连
2. 构建打印内容
3. 发送数据到打印机
4. 如配置两联，发送两次（中间加换行）
5. 返回结果

错误处理：
定义 PrintResult 枚举/类：
- success
- bluetoothNotEnabled
- printerNotConnected
- printFailed
- paperOut

### 3. 集成到 OrderService
修改 lib/services/order_service.dart：
- 注入 PrintService
- 创建订单后调用 printTicket
- 处理打印失败（显示警告但不阻止订单创建）

## UI 状态显示

在 HomeScreen 顶部显示打印机状态图标：
- 已连接：绿色图标
- 未连接：灰色图标，点击跳转到设置

## 打印失败处理

错误弹窗示例：
```
┌────────────────────────────┐
│        打印失败            │
│                            │
│  打印机未连接              │
│  请前往"打印设置"连接      │
│  蓝牙打印机                │
│                            │
│        [去设置]            │
└────────────────────────────┘
```

## 输出文件
- lib/utils/print_formatter.dart
- lib/services/print_service.dart
- 修改 lib/services/order_service.dart（集成打印）

## 验收标准
- 可以搜索并连接蓝牙打印机
- 打印内容格式正确（取餐号大字体居中）
- 支持打印两联
- 打印失败显示正确错误信息
- 持久化最后连接的打印机
```

---

## T7: 日总结功能

```
你是一个 Flutter 开发专家，擅长数据展示和图表。请实现日总结功能。

## 参考文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/日总结功能 spec.md（核心参考）
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/开发计划.md（T7 部分）

## 依赖检查
请先检查以下文件是否存在，如果存在则参考：
- lib/models/order.dart
- lib/models/daily_summary.dart
- lib/database/order_dao.dart

## 任务目标
实现日总结统计页面。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 界面布局

```
┌─────────────────────────────────────┐
│  日总结                    [<返回]   │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │    2024年03月01日           │   │
│  │    [←]      [→]             │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  今日数据                           │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │     订单总数                │   │
│  │       156                   │   │
│  │                             │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  各菜品销量                         │
│  ┌─────────────────────────────┐   │
│  │  牛肉面         45份        │   │
│  │  炸酱面         38份        │   │
│  │  酸辣粉         32份        │   │
│  │  ...                        │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  时段分布 [展开▼]                   │
│  ┌─────────────────────────────┐   │
│  │  08-09时: ████████  25单    │   │
│  │  09-10时: ██████████ 30单   │   │
│  │  ...                        │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## 需要创建的组件

### 1. SummaryService
位置：lib/services/summary_service.dart

方法：
- Future<DailySummary> getSummary(DateTime date)
- Future<int> getTotalOrders(String date)
- Future<List<DishSummary>> getDishSummaries(String date)
- Future<Map<int, int>> getHourlyDistribution(String date)

统计逻辑：
- 使用 OrderDao 查询数据
- 按 dish_name 分组统计数量
- 按 hour(created_at) 分组统计时段分布

### 2. DailySummaryScreen
位置：lib/screens/daily_summary_screen.dart

顶部日期选择器：
- 大号显示当前日期
- 左右箭头切换日期（右箭头不超过今天）
- 点击日期弹出日历选择器（showDatePicker）

订单总数卡片：
- 大字居中显示
- 字体大小建议 72pt

菜品销量列表：
- ListView.builder
- 每行：菜品名（左）+ 数量+份（右）
- 按销量降序排列
- 如数据为空显示"暂无数据"

时段分布（可折叠）：
- ExpansionTile
- 每个时段用进度条样式展示
- 计算最大值作为 100% 基准

## 代码规范
- 日期统一使用 DateTime 和 String (YYYY-MM-DD) 转换
- 使用 FutureBuilder 处理异步数据加载
- 显示加载指示器
- 错误时显示重试按钮

## 输出文件
- lib/services/summary_service.dart
- lib/screens/daily_summary_screen.dart

## 验收标准
- 可以切换日期查看历史数据
- 订单总数显示正确
- 菜品销量按数量降序排列
- 时段分布可视化正确
- 空数据状态处理得当
```

---

## T8: 蓝牙打印机设置

```
你是一个 Flutter 开发专家，擅长蓝牙设备管理。请实现打印机设置页面。

## 参考文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/小票打印功能 spec.md（蓝牙部分）
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/开发计划.md（T8 部分）

## 依赖检查
请先检查以下文件是否存在，如果存在则参考：
- lib/models/printer_config.dart
- lib/services/print_service.dart

## 任务目标
实现打印机设置页面，包括蓝牙配对和打印配置。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 界面布局

```
┌─────────────────────────────────────┐
│  打印设置                  [<返回]   │
├─────────────────────────────────────┤
│  蓝牙状态: [未连接 / 已连接: XXX]    │
├─────────────────────────────────────┤
│  蓝牙设备                           │
│  ┌─────────────────────────────┐   │
│  │  [🔍 搜索设备]              │   │
│  │                             │   │
│  │  已配对设备                 │   │
│  │  • 打印机-A (已连接) ✓       │   │
│  │                             │   │
│  │  可用设备                   │   │
│  │  • 打印机-B (点击连接)       │   │
│  │  • XX耳机                   │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  小票内容设置                       │
│  [开关] 打印店名                    │
│  ┌─────────────────────────────┐   │
│  │  店名: [美味小吃店    ]      │   │
│  └─────────────────────────────┘   │
│  [开关] 打印日期时间                │
│  [开关] 打印两联小票                │
├─────────────────────────────────────┤
│  高级设置 (预留)                    │
│  [ ] 启用双打印机模式               │
│     顾客联打印机: [未设置]           │
│     厨房联打印机: [未设置]           │
└─────────────────────────────────────┘
```

## 需要创建的组件

### 1. PrinterProvider
位置：lib/providers/printer_provider.dart
状态：
- PrinterConfig config
- bool isConnected
- List<BluetoothDevice> pairedDevices
- List<BluetoothDevice> availableDevices
- bool isScanning

方法：
- Future<void> scanDevices()
- Future<void> connect(String address)
- Future<void> disconnect()
- Future<void> updateConfig(PrinterConfig newConfig)

### 2. PrinterSettingsScreen
位置：lib/screens/printer_settings_screen.dart

蓝牙设备区域：
- 显示当前连接状态
- 搜索按钮（带加载动画）
- 已配对设备列表（优先显示）
- 可用设备列表
- 每个设备显示：名称、地址、连接状态
- 点击未连接设备进行配对和连接

设置选项：
- SwitchListTile: 打印店名
- TextField: 店名输入（仅在开启时可用）
- SwitchListTile: 打印日期时间
- SwitchListTile: 打印两联小票

自动保存：
- 配置修改后自动保存到 SharedPreferences
- 应用启动时自动加载配置并尝试连接

## 蓝牙权限

Android 需要以下权限：
```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

需要处理运行时权限申请（Android 12+）。

## 输出文件
- lib/providers/printer_provider.dart
- lib/screens/printer_settings_screen.dart
- 可能需要更新 AndroidManifest.xml

## 验收标准
- 可以搜索附近蓝牙设备
- 可以连接/断开打印机
- 配置项可以开关和保存
- 配置变更实时生效
- 应用启动自动重连
```

---

## T9: 集成测试与 Bug 修复

```
你是一个 Flutter 开发专家，擅长测试和调试。请进行集成测试。

## 参考文档
- 所有 spec 文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/开发计划.md（T9 部分）

## 任务目标
验证各模块协同工作，修复发现的问题。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 测试场景

### 场景 1：首次使用流程
1. 首次安装应用
2. 检查取餐号是否为 1
3. 进入菜单管理，添加菜品
4. 返回首页，验证菜品显示
5. 点击菜品下单
6. 验证取餐号递增
7. 验证订单数据保存

### 场景 2：每日重置
1. 修改系统日期到明天
2. 重启应用
3. 验证取餐号自动重置为 1

### 场景 3：打印流程
1. 连接蓝牙打印机
2. 下单验证打印内容
3. 断开打印机后下单
4. 验证错误提示
5. 重新连接后验证自动重连

### 场景 4：日总结
1. 创建多个订单
2. 进入日总结查看数据
3. 切换日期查看历史
4. 验证统计数据准确性

## 常见 Bug 检查清单

- [ ] 数据库升级问题（修改 schema 后）
- [ ] 异步操作未 await 导致的竞态条件
- [ ] 内存泄漏（未 dispose 的资源）
- [ ] 空指针异常（未处理的 null）
- [ ] 布局溢出（小屏幕设备）
- [ ] 蓝牙权限问题
- [ ] 日期时区问题

## 输出

不需要创建新文件，但需要：
1. 运行应用进行手动测试
2. 修复发现的问题
3. 记录无法修复的问题

## 验收标准
- 所有测试场景通过
- 无明显卡顿或崩溃
- 错误提示清晰易懂
```

---

## T10: 代码整理与文档

```
你是一个 Flutter 开发专家，擅长代码重构和文档编写。请进行代码整理。

## 参考文档
- 所有 spec 文档
- /Users/victor/Documents/codes/flutter/receipt-printing/spec/开发计划.md（T10 部分）

## 任务目标
代码审查、重构、补充文档。

## 工作目录
/Users/victor/Documents/codes/flutter/receipt-printing

## 检查清单

### 代码规范
- [ ] 统一代码格式（使用 dart format）
- [ ] 移除未使用的 import
- [ ] 移除未使用的变量和方法
- [ ] 统一命名规范（camelCase 用于变量/方法，PascalCase 用于类）
- [ ] 常量使用全大写下划线命名

### 错误处理
- [ ] 所有异步操作有 try-catch
- [ ] 用户操作错误有友好提示
- [ ] 日志输出使用 debugPrint

### 文档注释
- [ ] 所有 public 类添加文档注释
- [ ] 复杂方法添加注释说明
- [ ] 关键业务逻辑添加行内注释

### 性能优化
- [ ] ListView 使用 builder
- [ ] 图片使用缓存
- [ ] 避免不必要的状态更新

## 输出
- 整理后的代码
- 如有 spec 变更，更新对应文档

## 验收标准
- 代码通过 `flutter analyze` 无错误
- 代码通过 `dart format` 检查
- 主要类和方法有文档注释
```
