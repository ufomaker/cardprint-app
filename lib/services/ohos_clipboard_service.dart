import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 鸿蒙原生剪贴板服务
/// 通过 MethodChannel 调用 HarmonyOS 原生 Pasteboard API
class OhosClipboardService {
  static const MethodChannel _channel = MethodChannel('com.cardflow.ohos_clipboard');

  /// 读取剪贴板文本
  static Future<String?> getText() async {
    try {
      final result = await _channel.invokeMethod<String>('getText');
      return result?.isNotEmpty == true ? result : null;
    } catch (e) {
      debugPrint('OhosClipboardService.getText error: $e');
      return null;
    }
  }

  /// 设置剪贴板文本
  static Future<bool> setText(String text) async {
    try {
      final result = await _channel.invokeMethod<bool>('setText', {
        'text': text,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('OhosClipboardService.setText error: $e');
      return false;
    }
  }

  /// 检查剪贴板是否有文本
  static Future<bool> hasText() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasText');
      return result ?? false;
    } catch (e) {
      debugPrint('OhosClipboardService.hasText error: $e');
      return false;
    }
  }
}
