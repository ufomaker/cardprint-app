import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'ohos_image_picker_service.dart';

/// 图片选择服务
/// 封装图片选择器功能并提供图片信息
/// 自动检测平台：鸿蒙使用原生 API，其他平台使用 image_picker 插件
class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  /// 检测是否为鸿蒙平台
  static bool _isOhosPlatform() {
    try {
      final os = Platform.operatingSystem.toLowerCase();
      return os == 'ohos' || os == 'harmonyos' || os == 'openharmony';
    } catch (e) {
      return false;
    }
  }

  /// 从相册选择图片
  /// 返回图片字节数据和尺寸信息
  static Future<ImagePickResult?> pickFromGallery({
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    // 鸿蒙平台使用原生 API
    if (_isOhosPlatform()) {
      debugPrint('ImagePickerService: Using OHOS native API for gallery');
      final result = await OhosImagePickerService.pickFromGallery();
      if (result != null) {
        return ImagePickResult(
          bytes: result.bytes,
          width: result.width,
          height: result.height,
          fileName: 'ohos_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
      return null;
    }
    
    // 其他平台使用 image_picker 插件
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (image == null) return null;
      
      return await _processImage(image);
    } catch (e) {
      debugPrint('从相册选择图片失败: $e');
      return null;
    }
  }

  /// 拍照获取图片
  static Future<ImagePickResult?> pickFromCamera({
    int maxWidth = 1920,
    int maxHeight = 1920,
    int imageQuality = 85,
  }) async {
    // 鸿蒙平台使用原生 API
    if (_isOhosPlatform()) {
      debugPrint('ImagePickerService: Using OHOS native API for camera');
      final result = await OhosImagePickerService.pickFromCamera();
      if (result != null) {
        return ImagePickResult(
          bytes: result.bytes,
          width: result.width,
          height: result.height,
          fileName: 'ohos_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      }
      return null;
    }
    
    // 其他平台使用 image_picker 插件
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (image == null) return null;
      
      return await _processImage(image);
    } catch (e) {
      debugPrint('拍照获取图片失败: $e');
      return null;
    }
  }

  /// 处理选中的图片，获取字节数据和尺寸
  static Future<ImagePickResult?> _processImage(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      
      // 解码图片获取尺寸
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final width = frame.image.width.toDouble();
      final height = frame.image.height.toDouble();
      frame.image.dispose();
      
      return ImagePickResult(
        bytes: bytes,
        width: width,
        height: height,
        fileName: image.name,
      );
    } catch (e) {
      debugPrint('处理图片失败: $e');
      return null;
    }
  }
}

/// 图片选择结果
class ImagePickResult {
  final Uint8List bytes;
  final double width;
  final double height;
  final String fileName;

  ImagePickResult({
    required this.bytes,
    required this.width,
    required this.height,
    required this.fileName,
  });
}

