import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/card_content.dart';

/// DeepSeek AI 服务
/// 提供智能文本排版解析功能
class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/v1';
  static const String _apiKey = 'sk-4e0b4764e12f43fc902ad2d65b2bd45d';
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    },
  ));

  /// 系统提示词
  static const String _systemPrompt = '''
你是一个专业的贺卡排版助手。请分析用户输入的文本，提取三个部分：
1. "header": 称呼、抬头（通常在开头，如"亲爱的xxx"、"敬爱的xxx"）
2. "body": 正文内容（祝福语、主体内容）
3. "footer": 落款、日期（通常在结尾，如"爱你的xxx"、"你的xxx"、日期等）

规则：
- 如果没有明确的称呼，header 可以为空
- 如果没有明确的落款，footer 可以为空
- body 是必须的，不能为空
- 保留原文中的 Emoji 和特殊符号
- 保留原文的换行格式

只返回 JSON，不要有其他文字。格式：
{
  "header": "称呼内容",
  "body": "正文内容",
  "footer": "落款内容"
}
''';

  /// 使用 DeepSeek 解析文本
  static Future<CardContent> parseText(String text) async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.3,
          'max_tokens': 1000,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices']?[0]?['message']?['content'];
        
        if (content != null) {
          return _parseJsonResponse(content);
        }
      }
      
      // API 调用失败，降级到规则解析
      debugPrint('DeepSeek API 返回异常，使用规则解析');
      return CardContent.fromText(text);
      
    } on DioException catch (e) {
      debugPrint('DeepSeek API 请求失败: ${e.message}');
      // 网络错误，降级到规则解析
      return CardContent.fromText(text);
    } catch (e) {
      debugPrint('DeepSeek 解析异常: $e');
      return CardContent.fromText(text);
    }
  }

  /// 解析 JSON 响应
  static CardContent _parseJsonResponse(String content) {
    try {
      // 清理可能的 markdown 标记
      String jsonStr = content.trim();
      if (jsonStr.startsWith('```json')) {
        jsonStr = jsonStr.substring(7);
      }
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.substring(3);
      }
      if (jsonStr.endsWith('```')) {
        jsonStr = jsonStr.substring(0, jsonStr.length - 3);
      }
      jsonStr = jsonStr.trim();

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      return CardContent(
        header: (json['header'] as String?)?.trim() ?? '',
        body: (json['body'] as String?)?.trim() ?? '',
        footer: (json['footer'] as String?)?.trim() ?? '',
      );
    } catch (e) {
      debugPrint('JSON 解析失败: $e');
      debugPrint('原始内容: $content');
      // JSON 解析失败，降级到规则解析
      return CardContent.fromText(content);
    }
  }

  /// 检查 API 连接状态
  static Future<bool> checkConnection() async {
    try {
      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': 'deepseek-chat',
          'messages': [
            {'role': 'user', 'content': 'ping'},
          ],
          'max_tokens': 5,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
