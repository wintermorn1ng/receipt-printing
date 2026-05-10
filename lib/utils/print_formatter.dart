import 'package:charset_converter/charset_converter.dart';
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
    return [
      esc, 0x40, // ESC @ - 初始化打印机
    ];
  }

  /// 设置居中对齐
  static List<int> alignCenter() {
    return [esc, 0x61, 0x01]; // ESC a 1
  }

  /// 设置左对齐
  static List<int> alignLeft() {
    return [esc, 0x61, 0x00]; // ESC a 0
  }

  /// 设置常规字体
  static List<int> normalFont() {
    return [gs, 0x21, 0x00]; // GS ! 0
  }

  /// 设置双倍宽高字体
  static List<int> doubleFont() {
    return [gs, 0x21, 0x11]; // GS ! 17
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

  /// 进纸 n 行（用于切纸前留白）
  /// ESC d n: 打印并进纸 n 行
  static List<int> feedLines(int n) {
    return [esc, 0x64, n];
  }

  /// 进纸并切纸（部分切纸）
  static List<int> feedAndCut() {
    return [gs, 0x56, 0x01]; // GS V 1
  }

  /// 将字符串编码为 GBK 字节（打印机使用 GB18030，兼容 GBK）
  Future<List<int>> _encodeGbk(String text) async {
    return await CharsetConverter.encode('gbk', text);
  }

  /// 生成小票内容指令
  ///
  /// [ticketNumber] 取餐号
  /// [dishName] 菜品名称
  /// [shopName] 店名（可选）
  /// [printDateTime] 是否打印日期时间
  /// [dateTime] 指定日期时间（可选，默认使用当前时间）
  /// [gapLines] 切纸前进纸行数（留白），默认 0
  Future<List<int>> formatTicket({
    required int ticketNumber,
    required String dishName,
    String? shopName,
    bool printDateTime = false,
    DateTime? dateTime,
    int gapLines = 0,
  }) async {
    final List<int> bytes = [];

    // 初始化打印机
    bytes.addAll(initPrinter());

    // 打印店名
    if (shopName != null && shopName.isNotEmpty) {
      bytes.addAll(alignCenter());
      bytes.addAll(normalFont());
      bytes.addAll(boldOn());
      bytes.addAll(await _encodeGbk(shopName));
      bytes.addAll(lineFeed());
      bytes.addAll(boldOff());
    }

    // 分隔线
    bytes.addAll(alignCenter());
    bytes.addAll(await _encodeGbk('-' * 20));
    bytes.addAll(lineFeed());

    // 取餐号
    bytes.addAll(alignCenter());
    bytes.addAll(doubleFont());
    bytes.addAll(boldOn());
    bytes.addAll(await _encodeGbk('#$ticketNumber'));
    bytes.addAll(lineFeed());
    bytes.addAll(boldOff());
    bytes.addAll(normalFont());

    // 分隔线
    bytes.addAll(alignCenter());
    bytes.addAll(await _encodeGbk('-' * 20));
    bytes.addAll(lineFeed());

    // 菜品名称
    bytes.addAll(alignCenter());
    bytes.addAll(await _encodeGbk(dishName));
    bytes.addAll(lineFeed());

    bytes.addAll(lineFeed());

    // 日期时间
    if (printDateTime) {
      bytes.addAll(alignCenter());
      bytes.addAll(await _encodeGbk(_formatDateTime(dateTime ?? DateTime.now())));
      bytes.addAll(lineFeed());
    }

    bytes.addAll(lineFeed());
    // 进纸留白（切纸前空白）
    if (gapLines > 0) {
      bytes.addAll(feedLines(gapLines));
    }
    bytes.addAll(feedAndCut());

    return bytes;
  }

  String _formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    return formatter.format(dateTime);
  }
}
