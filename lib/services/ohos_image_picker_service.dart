import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 鸿蒙原生图片选择服务
/// 通过 MethodChannel 调用 HarmonyOS 原生图片选择 API
class OhosImagePickerService {
  static const MethodChannel _channel = MethodChannel('com.cardflow.ohos_image_picker');

  /// 从相册选择图片
  /// 返回图片字节数据和尺寸信息
  static Future<OhosImageResult?> pickFromGallery() async {
    try {
      debugPrint('OhosImagePickerService: Calling pickFromGallery');
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickFromGallery');
      
      if (result == null) {
        debugPrint('OhosImagePickerService: No image selected');
        return null;
      }
      
      return _parseResult(result);
    } catch (e) {
      debugPrint('OhosImagePickerService.pickFromGallery error: $e');
      return null;
    }
  }

  /// 拍照获取图片
  static Future<OhosImageResult?> pickFromCamera() async {
    try {
      debugPrint('OhosImagePickerService: Calling pickFromCamera');
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('pickFromCamera');
      
      if (result == null) {
        debugPrint('OhosImagePickerService: No image captured');
        return null;
      }
      
      return _parseResult(result);
    } catch (e) {
      debugPrint('OhosImagePickerService.pickFromCamera error: $e');
      return null;
    }
  }

  /// 解析原生返回的结果
  static OhosImageResult? _parseResult(Map<dynamic, dynamic> result) {
    try {
      final bytesData = result['bytes'];
      final width = result['width'] as num?;
      final height = result['height'] as num?;
      
      if (bytesData == null || width == null || height == null) {
        debugPrint('OhosImagePickerService: Invalid result data');
        return null;
      }
      
      // 将 List<dynamic> 转换为 Uint8List
      Uint8List bytes;
      if (bytesData is List) {
        bytes = Uint8List.fromList(bytesData.cast<int>());
      } else if (bytesData is Uint8List) {
        bytes = bytesData;
      } else {
        debugPrint('OhosImagePickerService: Unknown bytes type: ${bytesData.runtimeType}');
        return null;
      }
      
      debugPrint('OhosImagePickerService: Parsed image ${width.toDouble()}x${height.toDouble()}, ${bytes.length} bytes');
      
      return OhosImageResult(
        bytes: bytes,
        width: width.toDouble(),
        height: height.toDouble(),
      );
    } catch (e) {
      debugPrint('OhosImagePickerService._parseResult error: $e');
      return null;
    }
  }
}

/// 鸿蒙图片选择结果
class OhosImageResult {
  final Uint8List bytes;
  final double width;
  final double height;

  OhosImageResult({
    required this.bytes,
    required this.width,
    required this.height,
  });
}
