import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 字体加载服务
class FontService {
  /// 选择并导入字体文件
  /// 返回字体家族名称和文件路径
  static Future<Map<String, String>?> pickAndImportFont() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fontName = p.basenameWithoutExtension(fileName);
        
        // 将文件保存到应用文档目录以便持久化使用
        final appDir = await getApplicationDocumentsDirectory();
        final fontsDir = Directory(p.join(appDir.path, 'fonts'));
        if (!await fontsDir.exists()) {
          await fontsDir.create(recursive: true);
        }
        
        final savedPath = p.join(fontsDir.path, fileName);
        await file.copy(savedPath);
        
        // 加载字体到 Flutter 引擎
        await loadFont(fontName, savedPath);
        
        return {
          'name': fontName,
          'path': savedPath,
        };
      }
    } catch (e) {
      print('导入字体失败: $e');
    }
    return null;
  }

  /// 加载指定路径的字体到引擎
  static Future<void> loadFont(String fontName, String filePath) async {
    try {
      final fontData = await File(filePath).readAsBytes();
      final fontLoader = FontLoader(fontName);
      fontLoader.addFont(Future.value(ByteData.view(fontData.buffer)));
      await fontLoader.load();
    } catch (e) {
      print('加载字体到引擎失败: $e');
    }
  }

  /// 扫描并加载所有已保存的自定义字体
  static Future<List<Map<String, String>>> loadSavedFonts() async {
    List<Map<String, String>> fonts = [];
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fontsDir = Directory(p.join(appDir.path, 'fonts'));
      
      if (await fontsDir.exists()) {
        final files = fontsDir.listSync();
        for (var file in files) {
          if (file is File && (file.path.endsWith('.ttf') || file.path.endsWith('.otf'))) {
            final fontName = p.basenameWithoutExtension(file.path);
            await loadFont(fontName, file.path);
            fonts.add({
              'name': fontName,
              'path': file.path,
            });
          }
        }
      }
    } catch (e) {
      print('读取已保存字体失败: $e');
    }
    return fonts;
  }
}
