import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ohos_preferences_service.dart';

/// 跨平台持久化存储服务
/// 自动检测平台并使用对应的存储实现：
/// - 鸿蒙平台：使用 OhosPreferencesService（原生 @ohos.data.preferences）
/// - 其他平台：使用 SharedPreferences
class StorageService {
  static SharedPreferences? _prefs;

  /// 检测是否为鸿蒙平台
  static bool isOhosPlatform() {
    try {
      final os = Platform.operatingSystem.toLowerCase();
      return os == 'ohos' || os == 'harmonyos' || os == 'openharmony';
    } catch (e) {
      return false;
    }
  }

  /// 初始化（非鸿蒙平台需要）
  static Future<void> init() async {
    if (!isOhosPlatform()) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  /// 存储字符串
  static Future<bool> setString(String key, String value) async {
    try {
      if (isOhosPlatform()) {
        return await OhosPreferencesService.setString(key, value);
      } else {
        _prefs ??= await SharedPreferences.getInstance();
        return await _prefs!.setString(key, value);
      }
    } catch (e) {
      debugPrint('StorageService.setString error: $e');
      return false;
    }
  }

  /// 获取字符串
  static Future<String?> getString(String key) async {
    try {
      if (isOhosPlatform()) {
        final value = await OhosPreferencesService.getString(key);
        return value.isEmpty ? null : value;
      } else {
        _prefs ??= await SharedPreferences.getInstance();
        return _prefs!.getString(key);
      }
    } catch (e) {
      debugPrint('StorageService.getString error: $e');
      return null;
    }
  }

  /// 存储整数
  static Future<bool> setInt(String key, int value) async {
    try {
      if (isOhosPlatform()) {
        return await OhosPreferencesService.setInt(key, value);
      } else {
        _prefs ??= await SharedPreferences.getInstance();
        return await _prefs!.setInt(key, value);
      }
    } catch (e) {
      debugPrint('StorageService.setInt error: $e');
      return false;
    }
  }

  /// 获取整数
  static Future<int?> getInt(String key) async {
    try {
      if (isOhosPlatform()) {
        return await OhosPreferencesService.getInt(key);
      } else {
        _prefs ??= await SharedPreferences.getInstance();
        return _prefs!.getInt(key);
      }
    } catch (e) {
      debugPrint('StorageService.getInt error: $e');
      return null;
    }
  }

  /// 存储浮点数
  static Future<bool> setDouble(String key, double value) async {
    try {
      if (isOhosPlatform()) {
        return await OhosPreferencesService.setDouble(key, value);
      } else {
        _prefs ??= await SharedPreferences.getInstance();
        return await _prefs!.setDouble(key, value);
      }
    } catch (e) {
      debugPrint('StorageService.setDouble error: $e');
      return false;
    }
  }

  /// 获取浮点数
  static Future<double?> getDouble(String key) async {
    try {
      if (isOhosPlatform()) {
        return await OhosPreferencesService.getDouble(key);
      } else {
        _prefs ??= await SharedPreferences.getInstance();
        return _prefs!.getDouble(key);
      }
    } catch (e) {
      debugPrint('StorageService.getDouble error: $e');
      return null;
    }
  }

  /// 存储布尔值
  static Future<bool> setBool(String key, bool value) async {
    try {
      if (isOhosPlatform()) {
        return await OhosPreferencesService.setBool(key, value);
      } else {
        _prefs ??= await SharedPreferences.getInstance();
        return await _prefs!.setBool(key, value);
      }
    } catch (e) {
      debugPrint('StorageService.setBool error: $e');
      return false;
    }
  }

  /// 获取布尔值
  static Future<bool?> getBool(String key) async {
    try {
      if (isOhosPlatform()) {
        return await OhosPreferencesService.getBool(key);
      } else {
        _prefs ??= await SharedPreferences.getInstance();
        return _prefs!.getBool(key);
      }
    } catch (e) {
      debugPrint('StorageService.getBool error: $e');
      return null;
    }
  }

  /// 删除键
  static Future<bool> remove(String key) async {
    try {
      if (isOhosPlatform()) {
        return await OhosPreferencesService.remove(key);
      } else {
        _prefs ??= await SharedPreferences.getInstance();
        return await _prefs!.remove(key);
      }
    } catch (e) {
      debugPrint('StorageService.remove error: $e');
      return false;
    }
  }
}
