import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/model/raw_schedule_data.dart';
import '../../../domain/model/structured_course.dart';
import '../ai_provider.dart';
import '../ai_prompts.dart';

/// Claude AI Provider (Anthropic)
class ClaudeProvider extends AiProvider {
  @override
  String get id => 'claude';

  @override
  String get name => 'Claude (Anthropic)';

  @override
  Future<List<StructuredCourse>> parse(RawScheduleData raw) async {
    throw UnimplementedError('请在设置中配置 Claude API Key');
  }

  @override
  Future<String> callApi(String text, String apiKey) async {
    const model = 'claude-sonnet-4-20250514';

    final body = jsonEncode({
      'model': model,
      'max_tokens': 4096,
      'system': scheduleParsingSystemPrompt,
      'messages': [
        {
          'role': 'user',
          'content': scheduleParsingUserPrompt + text,
        }
      ],
    });

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Claude API 错误：${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as List<dynamic>?;
    if (content == null || content.isEmpty) {
      throw Exception('Claude 返回空内容');
    }
    final textContent = content.firstWhere(
      (c) => c is Map && c['type'] == 'text',
      orElse: () => null,
    );
    if (textContent == null) {
      throw Exception('Claude 返回格式错误：${data['content']}');
    }
    return textContent['text'] as String? ?? '[]';
  }
}
