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

1. **地址持久化 + 自动重连（核心设计）**
   - 蓝牙地址作为配置持久化到 SharedPreferences
   - 应用启动时，`BluetoothConnectionManager` 自动加载保存的地址并尝试连接
   - 连接失败时带退避重试（1s → 2s → 4s → ... → 最大 30s，最多 5 次）
   - 重试耗尽后进入 `connectionError` 状态，UI 显示"连接失败"，用户可点击重试

2. **状态机**
   ```
   [disconnected] → [connecting] → [connected]
                          ↑            │
                          │            ↓
                    [connectionError] ─┘
                          (有保存地址时触发重试)
   ```
   - `disconnected`：无保存地址，或用户主动断开
   - `connecting`：正在连接
   - `connected`：已连接
   - `connectionError`：连接失败（有保存地址，等待重试）

3. **连接状态统一管理**
   - `BluetoothConnectionManager` 单例管理所有蓝牙连接状态
   - UI 通过 `PrinterProvider` 订阅 `stateStream`，状态变化自动触发 `notifyListeners`
   - 打印前调用 `ensureConnected()` 确保已连接

4. **首次配置**
   - 用户点击"搜索设备"扫描附近蓝牙设备
   - 从列表中选择一台设备，该地址被持久化并立即尝试连接
   - 连接成功后保存设备名称和地址

5. **连接状态展示**
   - 主界面 AppBar 蓝牙图标反映实际连接状态（connected / connecting / error / disconnected）
   - 设置页面顶部显示连接状态头（带颜色标识）
   - 已连接设备显示绿色勾选，操作按钮变为"断开"

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
| `lib/services/bluetooth_connection_manager.dart` | 蓝牙连接状态机、持久化、自动重连（核心新组件） |
| `lib/services/print_service.dart` | 打印服务（渲染和发送指令） |
| `lib/providers/printer_provider.dart` | 打印机状态管理 Provider（UI 状态桥接） |
| `lib/utils/print_renderer.dart` | 抽象渲染器基类和打印数据模型 |
| `lib/utils/escpos_renderer.dart` | ESC/POS 蓝牙打印机渲染器 |
| `lib/utils/preview_renderer.dart` | 页面预览渲染器 |
| `lib/utils/print_formatter.dart` | ESC/POS 指令生成工具 |
| `lib/utils/preview_line.dart` | 预览线条数据模型 |
| `lib/screens/print_preview_screen.dart` | 打印预览页面 |
| `lib/screens/printer_settings_screen.dart` | 打印机设置页面 |

### 依赖

- `bluetooth_print_plus: ^2.4.6` - 蓝牙打印（已替换原 `flutter_bluetooth_serial`）
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
- [x] 蓝牙地址持久化，应用启动自动连接
- [x] 连接失败带退避重试
- [x] 状态变化通过 stateStream 通知 UI
