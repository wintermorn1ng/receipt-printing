import 'package:flutter/foundation.dart';

/// 打印机配置数据模型
///
/// 管理蓝牙打印机设置和小票打印选项
@immutable
class PrinterConfig {
  /// 蓝牙设备MAC地址
  final String? deviceAddress;

  /// 设备名称（用于显示）
  final String? deviceName;

  /// 是否打印店名
  final bool printShopName;

  /// 店名内容
  final String? shopName;

  /// 是否打印日期时间
  final bool printDateTime;

  /// 是否打印两联
  final bool printTwoCopies;

  /// 是否双打印机模式（预留）
  final bool dualPrinterMode;

  /// 顾客联打印机MAC地址（预留）
  final String? customerPrinterAddress;

  /// 厨房联打印机MAC地址（预留）
  final String? kitchenPrinterAddress;

  /// 打印后进纸行数（切纸前空出空白）
  /// 58mm纸一般设 3~5 行，约 3~5mm
  final int printGapLines;

  /// 打印两联时，两张票之间的间距行数
  /// 58mm纸一般设 3~5 行，约 3~5mm
  final int printTicketGapLines;

  /// 是否在小票末尾打印古诗词
  final bool printPoetry;

  const PrinterConfig({
    this.deviceAddress,
    this.deviceName,
    this.printShopName = true,
    this.shopName,
    this.printDateTime = true,
    this.printTwoCopies = false,
    this.dualPrinterMode = false,
    this.customerPrinterAddress,
    this.kitchenPrinterAddress,
    this.printGapLines = 3,
    this.printTicketGapLines = 3,
    this.printPoetry = true,
  });

  /// 默认配置
  static const PrinterConfig defaultConfig = PrinterConfig();

  /// 从 JSON (Map) 反序列化
  factory PrinterConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConfig(
      deviceAddress: json['device_address'] as String?,
      deviceName: json['device_name'] as String?,
      printShopName: json['print_shop_name'] as bool? ?? true,
      shopName: json['shop_name'] as String?,
      printDateTime: json['print_date_time'] as bool? ?? true,
      printTwoCopies: json['print_two_copies'] as bool? ?? false,
      dualPrinterMode: json['dual_printer_mode'] as bool? ?? false,
      customerPrinterAddress: json['customer_printer_address'] as String?,
      kitchenPrinterAddress: json['kitchen_printer_address'] as String?,
      printGapLines: json['print_gap_lines'] as int? ?? 3,
      printTicketGapLines: json['print_ticket_gap_lines'] as int? ?? 3,
      printPoetry: json['print_poetry'] as bool? ?? true,
    );
  }

  /// 序列化为 JSON (Map)
  Map<String, dynamic> toJson() {
    return {
      'device_address': deviceAddress,
      'device_name': deviceName,
      'print_shop_name': printShopName,
      'shop_name': shopName,
      'print_date_time': printDateTime,
      'print_two_copies': printTwoCopies,
      'dual_printer_mode': dualPrinterMode,
      'customer_printer_address': customerPrinterAddress,
      'kitchen_printer_address': kitchenPrinterAddress,
      'print_gap_lines': printGapLines,
      'print_ticket_gap_lines': printTicketGapLines,
      'print_poetry': printPoetry,
    };
  }

  /// 创建副本并更新指定字段
  ///
  /// 使用 [Value] 包装器来区分 null 值和未设置值
  PrinterConfig copyWith({
    Value<String?>? deviceAddress,
    Value<String?>? deviceName,
    bool? printShopName,
    Value<String?>? shopName,
    bool? printDateTime,
    bool? printTwoCopies,
    bool? dualPrinterMode,
    Value<String?>? customerPrinterAddress,
    Value<String?>? kitchenPrinterAddress,
    int? printGapLines,
    int? printTicketGapLines,
    bool? printPoetry,
  }) {
    return PrinterConfig(
      deviceAddress:
          deviceAddress != null ? deviceAddress.value : this.deviceAddress,
      deviceName: deviceName != null ? deviceName.value : this.deviceName,
      printShopName: printShopName ?? this.printShopName,
      shopName: shopName != null ? shopName.value : this.shopName,
      printDateTime: printDateTime ?? this.printDateTime,
      printTwoCopies: printTwoCopies ?? this.printTwoCopies,
      dualPrinterMode: dualPrinterMode ?? this.dualPrinterMode,
      customerPrinterAddress: customerPrinterAddress != null
          ? customerPrinterAddress.value
          : this.customerPrinterAddress,
      kitchenPrinterAddress: kitchenPrinterAddress != null
          ? kitchenPrinterAddress.value
          : this.kitchenPrinterAddress,
      printGapLines: printGapLines ?? this.printGapLines,
      printTicketGapLines: printTicketGapLines ?? this.printTicketGapLines,
      printPoetry: printPoetry ?? this.printPoetry,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterConfig &&
          runtimeType == other.runtimeType &&
          deviceAddress == other.deviceAddress &&
          deviceName == other.deviceName &&
          printShopName == other.printShopName &&
          shopName == other.shopName &&
          printDateTime == other.printDateTime &&
          printTwoCopies == other.printTwoCopies &&
          dualPrinterMode == other.dualPrinterMode &&
          customerPrinterAddress == other.customerPrinterAddress &&
          kitchenPrinterAddress == other.kitchenPrinterAddress &&
          printGapLines == other.printGapLines &&
          printTicketGapLines == other.printTicketGapLines &&
          printPoetry == other.printPoetry;

  @override
  int get hashCode => Object.hash(
        deviceAddress,
        deviceName,
        printShopName,
        shopName,
        printDateTime,
        printTwoCopies,
        dualPrinterMode,
        customerPrinterAddress,
        kitchenPrinterAddress,
        printGapLines,
        printTicketGapLines,
        printPoetry,
      );

  @override
  String toString() {
    return 'PrinterConfig(deviceAddress: $deviceAddress, deviceName: $deviceName, '
        'printShopName: $printShopName, shopName: $shopName, '
        'printDateTime: $printDateTime, printTwoCopies: $printTwoCopies, '
        'dualPrinterMode: $dualPrinterMode, '
        'customerPrinterAddress: $customerPrinterAddress, '
        'kitchenPrinterAddress: $kitchenPrinterAddress, '
        'printGapLines: $printGapLines, '
        'printTicketGapLines: $printTicketGapLines, '
        'printPoetry: $printPoetry)';
  }
}

/// 用于区分 null 值和未设置值的包装类
@immutable
class Value<T> {
  final T value;
  const Value(this.value);
}
