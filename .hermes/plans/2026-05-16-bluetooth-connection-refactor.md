# 蓝牙连接管理重构计划

**目标:** 修复蓝牙连接管理中的10个问题，实现稳定可靠的连接管理，不引入回归。

**架构原则:**
- `BluetoothConnectionManager` 是连接状态的唯一真相源
- `ensureConnected()` 必须保证返回时连接已建立或明确失败
- 所有连接操作串行化，杜绝竞态
- `ESCPOSRenderer` 不再持有独立连接逻辑，完全委托给 ConnectionManager

**涉及文件:**
- `lib/services/bluetooth_connection_manager.dart` — 核心修改
- `lib/utils/escpos_renderer.dart` — 删除重复逻辑
- `lib/app.dart` — 添加生命周期监听
- `test/providers/printer_provider_test.dart` — 需要更新适配
- `CHANGELOG.md` — 记录变更

---

### 设计决策

**ConnectionManager 核心接口变更:**

```dart
// ensureConnected 新语义:
// - 返回 Future<void>: 连接成功时 complete，失败时 throw
// - 内部等待完整重试周期（所有重试完成或成功）
// - 持有连接锁，防止并发

// _connectWithRetry 新语义:
// - 返回 Future<void>: 成功 complete，所有重试耗尽 throw
// - 不再在内部调度异步 Timer 后提前返回
```

**内部状态新增:**
- `Completer<void>? _connectCompleter` — ensureConnected 的等待句柄
- `bool _connectLocked` — 防止并发连接

---

### 任务分解

### Task 1: 修复 `ensureConnected()` 语义 + 添加并发锁

改动 `bluetooth_connection_manager.dart`:

1. 添加 `_connectCompleter` 和 `_connectLocked` 字段
2. `_connectWithRetry` 改为返回 `Future<void>`，内部跑完整个重试循环
3. `ensureConnected` 使用 `_connectLocked` 防重入
4. 等待 `_connectCompleter.future`
5. `_scheduleRetry` 改为在 `_connectWithRetry` 内部循环，不再异步返回

### Task 2: 添加连接超时保护

在 `_connectDirect` 中给 `BluetoothPrintPlus.connect()` 加 `.timeout(8s)`。

### Task 3: 修复 `_saveAddress` 顺序 + `_cancelRetry`

1. `_saveAddress` 先写 SharedPreferences，成功后再更新内存
2. `_cancelRetry` 不重置 `_retryAttempt` —— 重试计数是连接会话级别的

### Task 4: 移除 ESCPOSRenderer 重复连接逻辑

1. `ESCPOSRenderer.connect()` 标记为 deprecated，委托给 ConnectionManager
2. `ESCPOSRenderer.disconnect()` 同样委托
3. `printTwoCopies` 两联之间加 `isConnected` 检查

### Task 5: 添加 App 生命周期处理

在 `app.dart` 中添加 `WidgetsBindingObserver`，`resumed` 时触发重连。

### Task 6: 运行全部测试 + 回归验证 + 更新 CHANGELOG
