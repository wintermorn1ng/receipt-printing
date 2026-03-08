# 小票打印功能

## 设计原则
- 打印即走，无需等待确认
- 小票信息简洁，核心内容突出
- 支持多联打印和双打印机扩展

## 小票内容格式

### 基础版小票（两联内容相同）

```
┌────────────────────┐
│    美味小吃店       │  ← 店名（可选，可在设置中配置）
├────────────────────┤
│  取餐号: #128      │  ← 核心信息：大号字体
├────────────────────┤
│  牛肉面            │  ← 菜品名称
│                    │
│  2024-03-01        │  ← 日期（可选）
│  12:30:45          │  ← 时间
└────────────────────┘
```

### 内容说明

| 内容 | 是否打印 | 说明 |
|------|----------|------|
| 店名 | 可选 | 可在打印设置中配置，默认不打印 |
| 取餐号 | 必打 | 大号字体，最醒目位置 |
| 菜品名称 | 必打 | 正常字体 |
| 日期时间 | 可选 | 可在打印设置中开关 |
| 价格 | 不打印 | 不在小票上显示 |
| 数量 | 不打印 | 由店员手写标注 |

## 打印时机

- **触发条件**：用户点击菜品按钮后
- **执行动作**：立即异步打印，不阻塞UI
- **成功反馈**：底部 Toast 提示打印成功
- **失败处理**：弹出警告弹窗，显示失败原因

## 蓝牙打印机管理

### 打印机设置页面

```
┌─────────────────────────────────────┐
│  打印设置                  [<返回]   │
├─────────────────────────────────────┤
│  蓝牙打印机                         │
│  ┌─────────────────────────────┐   │
│  │  [搜索设备...]               │   │
│  │  • 打印机-A (已连接) ✓       │   │
│  │  • 打印机-B (未配对)         │   │
│  └─────────────────────────────┘   │
├─────────────────────────────────────┤
│  小票设置                           │
│  [✓] 打印店名                       │
│  [✓] 打印日期时间                   │
│  [✓] 打印两联小票                   │
├─────────────────────────────────────┤
│  高级设置 (预留)                    │
│  [ ] 启用双打印机模式               │
│     顾客联打印机: [未设置]           │
│     厨房联打印机: [未设置]           │
└─────────────────────────────────────┘
```

### 蓝牙连接逻辑

1. **首次连接**
   - 进入打印设置页面
   - 点击搜索设备
   - 选择蓝牙打印机进行配对
   - 配对成功后自动连接

2. **持久化连接**
   - 保存最后一次连接的打印机 MAC 地址
   - 应用启动时自动尝试连接
   - 连接失败时显示提示，但不阻塞使用

3. **连接状态**
   - 主界面显示打印机连接状态图标
   - 未连接时点击可跳转设置页面

## 多联打印

### 当前实现（单打印机两联）

```dart
void printTicket(Order order) {
  // 打印顾客联
  printer.print(buildTicketContent(order, '顾客联'));
  // 打印厨房联（内容相同）
  printer.print(buildTicketContent(order, '厨房联'));
}
```

### 预留扩展（双打印机模式）

```dart
class PrinterConfig {
  BluetoothDevice? customerPrinter;  // 顾客联打印机
  BluetoothDevice? kitchenPrinter;   // 厨房联打印机
  bool dualPrinterMode = false;      // 是否启用双打印机
}

void printTicket(Order order) {
  if (config.dualPrinterMode && config.customerPrinter != null) {
    customerPrinter.print(buildTicketContent(order));
  }
  if (config.dualPrinterMode && config.kitchenPrinter != null) {
    kitchenPrinter.print(buildTicketContent(order));
  } else {
    // 单打印机模式：打印两联
    printer.print(buildTicketContent(order));
    printer.print(buildTicketContent(order));
  }
}
```

## 打印失败处理

### 失败原因分类

| 错误码 | 说明 | 处理方式 |
|--------|------|----------|
| BT_NOT_ENABLED | 蓝牙未开启 | 提示用户开启蓝牙 |
| PRINTER_NOT_CONNECTED | 打印机未连接 | 提示用户连接打印机 |
| PRINTER_DISCONNECTED | 打印中断开 | 提示重新连接 |
| PRINT_FAILED | 打印指令失败 | 提示重试 |
| PAPER_OUT | 缺纸 | 提示检查纸张 |

### 错误弹窗示例

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

## 技术规格

- **打印机协议**：ESC/POS 标准指令集
- **支持纸张宽度**：58mm 热敏纸
- **编码格式**：GBK/UTF-8（根据打印机支持）

## 实现文件

### 核心文件

| 文件路径 | 说明 |
|----------|------|
| `lib/utils/print_renderer.dart` | 抽象渲染器基类和打印数据模型 |
| `lib/utils/escpos_renderer.dart` | ESC/POS 蓝牙打印机渲染器 |
| `lib/utils/preview_renderer.dart` | 页面预览渲染器 |
| `lib/utils/print_formatter.dart` | ESC/POS 指令生成工具 |
| `lib/utils/preview_line.dart` | 预览线条数据模型 |
| `lib/services/print_service.dart` | 打印服务 |
| `lib/screens/print_preview_screen.dart` | 打印预览页面 |
| `lib/screens/printer_settings_screen.dart` | 打印机设置页面 |
| `lib/providers/printer_provider.dart` | 打印机状态管理 Provider |

### 依赖

- `flutter_bluetooth_serial: ^0.4.0` - 蓝牙串口通信
- `shared_preferences: ^2.2.2` - 本地配置存储
- `intl: ^0.19.0` - 日期时间格式化

## 验证结果

- [x] 能生成正确的 ESC/POS 指令
- [x] 能连接蓝牙打印机
- [x] 能打印小票（内容正确）
- [x] 能打印两联
- [x] 打印失败有错误提示
- [x] 预览页面能正确显示小票布局
- [x] 渲染器可替换（打印/预览）
