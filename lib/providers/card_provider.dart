import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_content.dart';
import '../services/deepseek_service.dart';
import '../services/font_service.dart';

/// 卡片状态管理 Provider
class CardProvider extends ChangeNotifier {
  CardProvider() {
    _initFonts();
  }

  /// 当前卡片内容
  CardContent _content = CardContent();
  CardContent get content => _content;

  /// 操作历史栈（用于撤回）
  final List<CardContent> _historyStack = [];
  static const int _maxHistorySize = 20;

  /// 是否可以撤回
  bool get canUndo => _historyStack.isNotEmpty;

  /// 保存当前状态到历史栈
  void saveToHistory() {
    _historyStack.add(_content.copyWith());
    if (_historyStack.length > _maxHistorySize) {
      _historyStack.removeAt(0);
    }
  }

  /// 撤回到上一步
  void undo() {
    if (_historyStack.isNotEmpty) {
      _content = _historyStack.removeLast();
      notifyListeners();
    }
  }

  /// 是否使用 AI 解析（默认开启）
  bool _useAI = true;
  bool get useAI => _useAI;

  /// AI 解析加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 当前选中的字体名称
  String _fontFamily = 'Noto Serif SC';
  String get fontFamily => _fontFamily;

  /// 内置 Google Fonts
  final List<String> _googleFonts = [
    'Noto Serif SC',   // 思源宋体
    'Noto Sans SC',    // 思源黑体
    'ZCOOL XiaoWei',   // 站酷小薇
  ];

  /// 内置本地字体（通过 pubspec.yaml 注册）
  final List<String> _builtInFonts = [
    '千图小兔体',
    '一叶知秋行楷',
    '田英章硬笔楷书',
    '迷你简启体',
  ];

  /// 自定义导入的字体
  List<String> _customFonts = [];

  /// 获取所有可用字体列表
  List<String> get availableFonts => [..._googleFonts, ..._builtInFonts, ..._customFonts];

  /// 字体显示名称映射
  final Map<String, String> fontDisplayNames = {
    'Noto Serif SC': '思源宋体',
    'Noto Sans SC': '思源黑体',
    'ZCOOL XiaoWei': '站酷小薇',
    '千图小兔体': '千图小兔体',
    '一叶知秋行楷': '一叶知秋行楷',
    '田英章硬笔楷书': '田英章硬笔楷书',
    '迷你简启体': '迷你简启体',
  };

  /// 初始化：加载已保存的自定义字体和用户设置
  Future<void> _initFonts() async {
    final savedFonts = await FontService.loadSavedFonts();
    _customFonts = savedFonts.map((f) => f['name']!).toList();
    // 为自定义字体添加显示名称
    for (var f in savedFonts) {
      fontDisplayNames[f['name']!] = f['name']!;
    }
    
    // 加载上次保存的字体和字号设置
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载字体
      final savedFont = prefs.getString('selected_font');
      if (savedFont != null && availableFonts.contains(savedFont)) {
        _fontFamily = savedFont;
      }
      
      // 加载字号
      final savedFontSize = prefs.getDouble('selected_font_size');
      if (savedFontSize != null) {
        _fontSize = savedFontSize.clamp(12, 48);
      }
      
      // 加载 AI 模式设置
      final savedUseAI = prefs.getBool('use_ai_mode');
      if (savedUseAI != null) {
        _useAI = savedUseAI;
      }
      
      // 加载对折贺卡模式设置
      final savedFoldCard = prefs.getBool('fold_card_mode');
      if (savedFoldCard != null) {
        _isFoldCard = savedFoldCard;
      }
    } catch (e) {
      debugPrint('加载设置失败: $e');
    }
    
    notifyListeners();
  }

  /// 导入新字体
  Future<bool> importFont() async {
    final result = await FontService.pickAndImportFont();
    if (result != null) {
      final name = result['name']!;
      if (!_customFonts.contains(name)) {
        _customFonts.add(name);
        fontDisplayNames[name] = name;
        _fontFamily = name; // 自动切换到新导入的字体
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  /// 当前字号
  double _fontSize = 24;
  double get fontSize => _fontSize;

  /// 是否为自由模式（默认为锁定模式，仅 Y 轴可拖拽）
  bool _isFreeMode = false;
  bool get isFreeMode => _isFreeMode;

  /// 纸张尺寸（毫米）
  Size _paperSize = const Size(148, 105); // A6 风景尺寸
  Size get paperSize => _paperSize;

  /// 自定义尺寸缓存
  double _customWidth = 148;
  double _customHeight = 105;
  double get customWidth => _customWidth;
  double get customHeight => _customHeight;

  /// 是否是自定义模式
  bool _isCustomSize = false;
  bool get isCustomSize => _isCustomSize;

  /// 贺卡类型：true=对折，false=单页
  bool _isFoldCard = false;
  bool get isFoldCard => _isFoldCard;

  /// 预设纸张尺寸
  final Map<String, Size> presetPaperSizes = {
    'A4': const Size(297, 210),
    'A5': const Size(210, 148),
    'A6': const Size(148, 105),
    '6寸 (4R)': const Size(152, 102),
    '正方形': const Size(150, 150),
    '自定义': const Size(-1, -1), // 标记位
  };

  /// 更新卡片内容
  void updateContent(CardContent newContent) {
    _content = newContent;
    notifyListeners();
  }

  /// 切换 AI 解析模式（并保存用户选择）
  void toggleAI() async {
    _useAI = !_useAI;
    notifyListeners();
    
    // 保存用户选择
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_ai_mode', _useAI);
    } catch (e) {
      debugPrint('保存 AI 模式设置失败: $e');
    }
  }

  /// 从文本解析并更新内容（根据模式选择 AI 或规则解析）
  Future<void> parseAndUpdateContent(String text) async {
    if (_useAI) {
      _isLoading = true;
      notifyListeners();

      try {
        _content = await DeepSeekService.parseText(text);
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    } else {
      _content = CardContent.fromText(text);
      notifyListeners();
    }
  }

  /// 更新 header 偏移
  void updateHeaderOffset(double dx, double dy) {
    _content = _content.copyWith(
      headerOffsetX: _isFreeMode ? _content.headerOffsetX + dx : _content.headerOffsetX,
      headerOffsetY: _content.headerOffsetY + dy,
    );
    notifyListeners();
  }

  /// 更新 body 偏移
  void updateBodyOffset(double dx, double dy) {
    _content = _content.copyWith(
      bodyOffsetX: _isFreeMode ? _content.bodyOffsetX + dx : _content.bodyOffsetX,
      bodyOffsetY: _content.bodyOffsetY + dy,
    );
    notifyListeners();
  }

  /// 更新 footer 偏移
  void updateFooterOffset(double dx, double dy) {
    _content = _content.copyWith(
      footerOffsetX: _isFreeMode ? _content.footerOffsetX + dx : _content.footerOffsetX,
      footerOffsetY: _content.footerOffsetY + dy,
    );
    notifyListeners();
  }

  /// 更新 header 缩放和旋转
  void updateHeaderTransform({double? scale, double? rotation}) {
    if (!_isFreeMode) return;
    _content = _content.copyWith(
      headerScale: scale != null ? (_content.headerScale * scale).clamp(0.5, 3.0) : null,
      headerRotation: rotation != null ? _content.headerRotation + rotation : null,
    );
    notifyListeners();
  }

  /// 更新 body 缩放和旋转
  void updateBodyTransform({double? scale, double? rotation}) {
    if (!_isFreeMode) return;
    _content = _content.copyWith(
      bodyScale: scale != null ? (_content.bodyScale * scale).clamp(0.5, 3.0) : null,
      bodyRotation: rotation != null ? _content.bodyRotation + rotation : null,
    );
    notifyListeners();
  }

  /// 更新 footer 缩放和旋转
  void updateFooterTransform({double? scale, double? rotation}) {
    if (!_isFreeMode) return;
    _content = _content.copyWith(
      footerScale: scale != null ? (_content.footerScale * scale).clamp(0.5, 3.0) : null,
      footerRotation: rotation != null ? _content.footerRotation + rotation : null,
    );
    notifyListeners();
  }

  /// 切换字体（并保存用户选择）
  void setFont(String fontFamily) async {
    _fontFamily = fontFamily;
    notifyListeners();
    
    // 保存用户选择
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_font', fontFamily);
    } catch (e) {
      debugPrint('保存字体设置失败: $e');
    }
  }

  /// 设置字号（并保存用户选择）
  void setFontSize(double size) async {
    _fontSize = size.clamp(12, 48);
    notifyListeners();
    
    // 保存用户选择
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('selected_font_size', _fontSize);
    } catch (e) {
      debugPrint('保存字号设置失败: $e');
    }
  }

  /// 切换编辑模式
  void toggleMode() {
    _isFreeMode = !_isFreeMode;
    notifyListeners();
  }

  /// 设置纸张尺寸
  void setPaperSize(Size size) {
    if (size.width == -1) {
      _isCustomSize = true;
      _paperSize = Size(_customWidth, _customHeight);
    } else {
      _isCustomSize = false;
      _paperSize = size;
      _customWidth = size.width;
      _customHeight = size.height;
    }
    notifyListeners();
  }

  /// 更新自定义宽度
  void updateCustomWidth(double width) {
    if (width <= 0) return;
    _customWidth = width;
    if (_isCustomSize) {
      _paperSize = Size(_customWidth, _customHeight);
    }
    notifyListeners();
  }

  /// 更新自定义高度
  void updateCustomHeight(double height) {
    if (height <= 0) return;
    _customHeight = height;
    if (_isCustomSize) {
      _paperSize = Size(_customWidth, _customHeight);
    }
    notifyListeners();
  }

  /// 设置贺卡类型（单页/对折）（并保存用户选择）
  void setFoldCard(bool isFold) async {
    _isFoldCard = isFold;
    notifyListeners();
    
    // 保存用户选择
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fold_card_mode', _isFoldCard);
    } catch (e) {
      debugPrint('保存对折贺卡模式设置失败: $e');
    }
  }

  /// 重置所有变换
  void resetTransforms() {
    _content = _content.copyWith(
      headerOffsetX: 0,
      headerOffsetY: 0,
      bodyOffsetX: 0,
      bodyOffsetY: 0,
      footerOffsetX: 0,
      footerOffsetY: 0,
      headerScale: 1.0,
      bodyScale: 1.0,
      footerScale: 1.0,
      headerRotation: 0,
      bodyRotation: 0,
      footerRotation: 0,
    );
    notifyListeners();
  }

  /// 清空内容
  void clear() {
    _content = CardContent();
    notifyListeners();
  }
}
