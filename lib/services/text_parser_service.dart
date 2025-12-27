import '../models/card_content.dart';

/// 文本解析服务
/// MVP 版本使用规则解析，后续可接入 DeepSeek API
class TextParserService {
  /// 解析文本为 CardContent
  /// 规则版：第一行为 header，最后一行为 footer，中间为 body
  static CardContent parse(String text) {
    return CardContent.fromText(text);
  }

  /// 智能检测文本是否像卡片文案
  /// 用于剪贴板检测时的初筛
  static bool looksLikeCardText(String text) {
    if (text.isEmpty) return false;

    final trimmed = text.trim();

    // 字符数大于 4
    if (trimmed.length <= 4) return false;

    // 检查是否包含常见的卡片关键词
    final keywords = [
      '亲爱的', '敬爱的', '尊敬的',
      '生日快乐', '新年快乐', '节日快乐',
      '祝你', '祝您', '愿你', '愿您',
      '爱你的', '想你的', '你的',
      '此致', '敬礼',
    ];

    for (final keyword in keywords) {
      if (trimmed.contains(keyword)) return true;
    }

    // 检查是否有多行（可能是格式化的卡片内容）
    final lines = trimmed.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.length >= 2 && lines.length <= 10) {
      return true;
    }

    return false;
  }

  /// 预处理文本（清理多余空白等）
  static String preprocess(String text) {
    // 移除多余的空行
    final lines = text.split('\n');
    final cleanedLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        cleanedLines.add(trimmed);
      }
    }

    return cleanedLines.join('\n');
  }
}
