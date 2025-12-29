import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 鸿蒙原生打印服务
/// 通过 MethodChannel 调用 HarmonyOS 原生打印 API
class OhosPrintService {
  static const MethodChannel _channel = MethodChannel('com.cardflow.ohos_print');

  /// 检查当前平台是否支持鸿蒙打印
  static Future<bool> isSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } catch (e) {
      debugPrint('OhosPrintService.isSupported error: $e');
      return false;
    }
  }

  /// 打印图片
  /// [imageBytes] 图片的二进制数据（PNG 格式最佳）
  /// [fileName] 可选的文件名
  static Future<bool> printImage(Uint8List imageBytes, {String? fileName}) async {
    try {
      final result = await _channel.invokeMethod<bool>('printImage', {
        'imageBytes': imageBytes,
        'fileName': fileName ?? 'card_${DateTime.now().millisecondsSinceEpoch}.png',
      });
      return result ?? false;
    } catch (e) {
      debugPrint('OhosPrintService.printImage error: $e');
      rethrow;
    }
  }

  /// 打印 PDF
  /// [pdfBytes] PDF 的二进制数据
  /// [fileName] 可选的文件名
  static Future<bool> printPdf(Uint8List pdfBytes, {String? fileName}) async {
    try {
      final result = await _channel.invokeMethod<bool>('printPdf', {
        'pdfBytes': pdfBytes,
        'fileName': fileName ?? 'card_${DateTime.now().millisecondsSinceEpoch}.pdf',
      });
      return result ?? false;
    } catch (e) {
      debugPrint('OhosPrintService.printPdf error: $e');
      rethrow;
    }
  }
}
