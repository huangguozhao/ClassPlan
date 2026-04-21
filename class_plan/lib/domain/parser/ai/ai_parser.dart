import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../data/ai/ai_prompts.dart';
import '../../../domain/model/raw_schedule_data.dart';
import '../../../domain/model/structured_course.dart';
import '../schedule_parser.dart';

/// AI 解析器（Claude API）
/// 处理非标准格式的课表文本
class AiParser implements ScheduleParser {
  final String? apiKey;

  AiParser({this.apiKey});

  @override
  String get name => 'AI 解析';

  @override
  int get priority => 2; // 规则解析失败后再用 AI

  @override
  Future<List<StructuredCourse>> parse(RawScheduleData raw) async {
    if (apiKey == null || apiKey!.isEmpty) {
      throw Exception('未配置 AI API Key，无法使用 AI 解析功能');
    }

    final response = await _callClaude(raw.rawText);
    return _parseJsonResponse(response);
  }

  Future<String> _callClaude(String text) async {
    const model = 'claude-sonnet-4-20250514';

    final body = jsonEncode({
      'model': model,
      'max_tokens': 4096,
      'system': courseTableParsingPrompt,
      'messages': [
        {
          'role': 'user',
          'content': '请解析以下课表文本：\n\n$text',
        }
      ],
    });

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey!,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('AI 解析请求失败：${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>;
    final textContent = content.firstWhere(
      (c) => c['type'] == 'text',
      orElse: () => {'text': '[]'},
    );
    return textContent['text'] as String;
  }

  List<StructuredCourse> _parseJsonResponse(String jsonStr) {
    // 提取 JSON 数组（可能在 markdown 代码块中）
    var cleaned = jsonStr.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    final List<dynamic> jsonList = jsonDecode(cleaned);
    return jsonList.map((item) {
      final map = item as Map<String, dynamic>;
      return StructuredCourse(
        name: map['name'] as String? ?? '未知课程',
        teacher: map['teacher'] as String?,
        location: map['location'] as String?,
        dayOfWeek: map['dayOfWeek'] as int?,
        startPeriod: map['startPeriod'] as int?,
        endPeriod: map['endPeriod'] as int?,
        weekStart: map['weekStart'] as int?,
        weekEnd: map['weekEnd'] as int?,
        weeks: (map['weeks'] as List<dynamic>?)?.cast<int>(),
      );
    }).toList();
  }
}
