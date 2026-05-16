# APK 体积优化

## 优化结果

| 版本 | APK 大小 | 架构 |
|------|----------|------|
| 原始 | 56.8MB | armeabi-v7a, arm64-v8a, x86_64 |
| 移除 x86_64 | 33.2MB | armeabi-v7a, arm64-v8a |
| 移除 armeabi-v7a | 18.5MB | arm64-v8a |

**总计节省：38.3MB（67%）**

## 优化方案

### 1. 禁用 Flutter Gradle Plugin 自动添加 abiFilters

在 `android/gradle.properties` 中添加：

```properties
disable-abi-filtering=true
```

这行配置阻止 Flutter Gradle Plugin 自动添加 `ndk.abiFilters`，让项目自己的配置生效。

### 2. 在 build.gradle.kts 中指定目标架构

在 `android/app/build.gradle.kts` 的 `defaultConfig` 中配置：

```kotlin
ndk {
    abiFilters.addAll(listOf("arm64-v8a"))
}
```

### 关键原理

Flutter Gradle Plugin 默认会自动设置 `ndk.abiFilters` 包含三个架构：
- armeabi-v7a (32位 ARM)
- arm64-v8a (64位 ARM)
- x86_64 (模拟器用)

当用户在 `defaultConfig` 中设置 `abiFilters` 时，Flutter Gradle Plugin 会检查是否已经设置过，如果设置过就跳过。但实际上它在 `buildType` 级别还会重新覆盖，导致配置失效。

通过 `disable-abi-filtering=true` 可以完全禁用这个行为，让用户的配置生效。

## APK 构成（优化后 18.5MB）

| 组成 | 大小 | 占比 |
|------|------|------|
| libflutter.so | 11.3MB | 61% |
| libapp.so | 5.8MB | 31% |
| classes.dex | 1.4MB | 7.6% |
| assets + resources | ~0.8MB | 4.3% |

## 兼容性说明

仅保留 `arm64-v8a` 架构意味着：
- **不支持** 32 位 ARM 设备（老旧低端机）
- **不支持** x86/x86_64 模拟器
- **支持** 2018 年以后的大多数 Android 设备

如果需要兼容老旧设备，可以改为：

```kotlin
ndk {
    abiFilters.addAll(listOf("armeabi-v7a", "arm64-v8a"))
}
```

这样 APK 会变成 33.2MB，只节省了 x86_64 的部分（约 18MB）。

## 其他优化方向

1. **移除未使用的 cupertino_icons**：如果没用到 iOS 风格图标，可在 pubspec.yaml 中移除
2. **压缩资源文件**：APK 内有 250 个 PNG 图片，可使用 tinypng 等工具压缩
3. **代码混淆**：使用 `--split-debug-info` 分离调试信息，可减小 libapp.so 体积
