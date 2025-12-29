import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 鸿蒙原生持久化存储服务
/// 通过 MethodChannel 调用 HarmonyOS 原生 Preferences API
class OhosPreferencesService {
  static const MethodChannel _channel = MethodChannel('com.cardflow.ohos_preferences');

  /// 存储字符串
  static Future<bool> setString(String key, String value) async {
    try {
      final result = await _channel.invokeMethod<bool>('setString', {
        'key': key,
        'value': value,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('OhosPreferencesService.setString error: $e');
      return false;
    }
  }

  /// 获取字符串
  static Future<String> getString(String key, {String defaultValue = ''}) async {
    try {
      final result = await _channel.invokeMethod<String>('getString', {
        'key': key,
        'defaultValue': defaultValue,
      });
      return result ?? defaultValue;
    } catch (e) {
      debugPrint('OhosPreferencesService.getString error: $e');
      return defaultValue;
    }
  }

  /// 存储整数
  static Future<bool> setInt(String key, int value) async {
    try {
      final result = await _channel.invokeMethod<bool>('setInt', {
        'key': key,
        'value': value,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('OhosPreferencesService.setInt error: $e');
      return false;
    }
  }

  /// 获取整数
  static Future<int?> getInt(String key) async {
    try {
      // 使用 num 类型接收后转换，避免类型转换问题
      final result = await _channel.invokeMethod<num>('getInt', {
        'key': key,
      });
      return result?.toInt();
    } catch (e) {
      debugPrint('OhosPreferencesService.getInt error: $e');
      return null;
    }
  }

  /// 存储浮点数
  static Future<bool> setDouble(String key, double value) async {
    try {
      final result = await _channel.invokeMethod<bool>('setDouble', {
        'key': key,
        'value': value,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('OhosPreferencesService.setDouble error: $e');
      return false;
    }
  }

  /// 获取浮点数
  static Future<double?> getDouble(String key) async {
    try {
      // 原生可能返回 int 或 double，使用 num 类型接收后转换
      final result = await _channel.invokeMethod<num>('getDouble', {
        'key': key,
      });
      return result?.toDouble();
    } catch (e) {
      debugPrint('OhosPreferencesService.getDouble error: $e');
      return null;
    }
  }

  /// 存储布尔值
  static Future<bool> setBool(String key, bool value) async {
    try {
      final result = await _channel.invokeMethod<bool>('setBool', {
        'key': key,
        'value': value,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('OhosPreferencesService.setBool error: $e');
      return false;
    }
  }

  /// 获取布尔值
  static Future<bool?> getBool(String key) async {
    try {
      final result = await _channel.invokeMethod<bool>('getBool', {
        'key': key,
      });
      return result;
    } catch (e) {
      debugPrint('OhosPreferencesService.getBool error: $e');
      return null;
    }
  }

  /// 删除键
  static Future<bool> remove(String key) async {
    try {
      final result = await _channel.invokeMethod<bool>('remove', {
        'key': key,
      });
      return result ?? false;
    } catch (e) {
      debugPrint('OhosPreferencesService.remove error: $e');
      return false;
    }
  }

  /// 清空所有数据
  static Future<bool> clear() async {
    try {
      final result = await _channel.invokeMethod<bool>('clear');
      return result ?? false;
    } catch (e) {
      debugPrint('OhosPreferencesService.clear error: $e');
      return false;
    }
  }
}
