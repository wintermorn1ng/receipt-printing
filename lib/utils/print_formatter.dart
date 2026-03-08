import 'package:intl/intl.dart';

/// ESC/POS 指令生成工具
///
/// 用于生成小票打印的 ESC/POS 指令
class PrintFormatter {
  /// ESC/POS 指令常量
  static const int esc = 0x1B;
  static const int gs = 0x1D;
  static const int lf = 0x0A;

  /// 初始化打印机
  static List<int> initPrinter() {
    return [esc, 0x40]; // ESC @
  }

  /// 设置居中对齐
  static List<int> alignCenter() {
    return [esc, 0x61, 0x01]; // ESC a 1
  }

  /// 设置左对齐
  static List<int> alignLeft() {
    return [esc, 0x61, 0x00]; // ESC a 0
  }

  /// 设置常规字体（取餐号后恢复）
  static List<int> normalFont() {
    return [gs, 0x21, 0x00]; // GS ! 0
  }

  /// 设置双倍宽高字体（取餐号使用）
  static List<int> doubleFont() {
    return [gs, 0x21, 0x11]; // GS ! 17 (double width and height)
  }

  /// 设置加粗
  static List<int> boldOn() {
    return [esc, 0x45, 0x01]; // ESC E 1
  }

  /// 关闭加粗
  static List<int> boldOff() {
    return [esc, 0x45, 0x00]; // ESC E 0
  }

  /// 换行
  static List<int> lineFeed() {
    return [lf];
  }

  /// 切纸（完整切纸）
  static List<int> cutPaper() {
    return [gs, 0x56, 0x00]; // GS V 0 (full cut)
  }

  /// 进纸并切纸（部分切纸）
  static List<int> feedAndCut() {
    return [gs, 0x56, 0x01]; // GS V 1 (partial cut)
  }

  /// 生成小票内容指令
  ///
  /// [ticketNumber] - 取餐号
  /// [dishName] - 菜品名称
  /// [shopName] - 店名（可选）
  /// [printDateTime] - 是否打印日期时间
  static List<int> formatTicket({
    required int ticketNumber,
    required String dishName,
    String? shopName,
    bool printDateTime = false,
  }) {
    final List<int> bytes = [];

    // 初始化打印机
    bytes.addAll(initPrinter());

    // 打印店名（如果提供）
    if (shopName != null && shopName.isNotEmpty) {
      bytes.addAll(alignCenter());
      bytes.addAll(normalFont());
      bytes.addAll(boldOn());
      bytes.addAll(_stringToBytes(shopName));
      bytes.addAll(lineFeed());
      bytes.addAll(boldOff());
    }

    // 分隔线
    bytes.addAll(alignCenter());
    bytes.addAll(_stringToBytes('-' * 20));
    bytes.addAll(lineFeed());

    // 取餐号（大字）
    bytes.addAll(alignCenter());
    bytes.addAll(doubleFont());
    bytes.addAll(boldOn());
    bytes.addAll(_stringToBytes('#$ticketNumber'));
    bytes.addAll(lineFeed());
    bytes.addAll(boldOff());
    bytes.addAll(normalFont());

    // 分隔线
    bytes.addAll(alignCenter());
    bytes.addAll(_stringToBytes('-' * 20));
    bytes.addAll(lineFeed());

    // 菜品名称
    bytes.addAll(alignCenter());
    bytes.addAll(_stringToBytes(dishName));
    bytes.addAll(lineFeed());

    // 空行
    bytes.addAll(lineFeed());

    // 日期时间（如果需要）
    if (printDateTime) {
      bytes.addAll(alignCenter());
      bytes.addAll(_stringToBytes(_formatDateTime(DateTime.now())));
      bytes.addAll(lineFeed());
    }

    // 空行
    bytes.addAll(lineFeed());

    // 进纸并切纸
    bytes.addAll(feedAndCut());

    return bytes;
  }

  /// 将字符串转换为 GBK 编码的字节列表
  /// 对于 ASCII 字符直接使用，对于中文尝试 UTF-8
  static List<int> _stringToBytes(String text) {
    final List<int> bytes = [];
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code < 128) {
        // ASCII 字符
        bytes.add(code);
      } else {
        // 中文字符，使用 UTF-8 编码
        bytes.addAll(_encodeUtf8Char(text[i]));
      }
    }
    return bytes;
  }

  /// 编码单个 UTF-8 字符
  static List<int> _encodeUtf8Char(String char) {
    final code = char.codeUnitAt(0);
    if (code < 0x800) {
      // 2 字节 UTF-8
      return [
        0xC0 | (code >> 6),
        0x80 | (code & 0x3F),
      ];
    } else {
      // 3 字节 UTF-8
      return [
        0xE0 | (code >> 12),
        0x80 | ((code >> 6) & 0x3F),
        0x80 | (code & 0x3F),
      ];
    }
  }

  /// 格式化日期时间为字符串
  static String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }
}