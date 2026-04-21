import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/model/raw_schedule_data.dart';
import '../../../domain/model/structured_course.dart';
import '../ai_provider.dart';
import '../ai_prompts.dart';

/// KIMI AI Provider（Moonshot）
class KIMIProvider extends AiProvider {
  @override
  String get id => 'kimi';

  @override
  String get name => 'KIMI (Moonshot)';

  @override
  Future<List<StructuredCourse>> parse(RawScheduleData raw) async {
    throw UnimplementedError('请在设置中配置 KIMI API Key');
  }

  @override
  Future<String> callApi(String text, String apiKey) async {
    final body = jsonEncode({
      'model': 'moonshot-v1-8k',
      'messages': [
        {'role': 'system', 'content': scheduleParsingSystemPrompt},
        {'role': 'user', 'content': scheduleParsingUserPrompt + text},
      ],
      'max_tokens': 4096,
    });

    final response = await http.post(
      Uri.parse('https://api.moonshot.cn/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('KIMI API 错误：${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('KIMI 返回空结果');
    }
    final firstChoice = choices.first;
    if (firstChoice is! Map) throw Exception('KIMI 返回格式错误');
    final message = firstChoice['message'] as Map?;
    if (message == null) throw Exception('KIMI 返回格式错误');
    return (message['content'] as String?) ?? '[]';
  }
}
