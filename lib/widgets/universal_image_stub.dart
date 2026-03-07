/// Web 平台的空实现
///
/// 这个文件在 Web 平台上被使用
/// File 类型在此平台上不可用

/// 创建 File 对象 - Web 平台空实现
///
/// 这个函数不应该在 Web 平台上被调用
/// 如果被调用，会抛出异常
dynamic createFile(String path) {
  throw UnsupportedError('Cannot create File on web platform');
}