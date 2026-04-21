import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/model/raw_schedule_data.dart';
import '../../../domain/model/structured_course.dart';
import '../ai_provider.dart';
import '../ai_prompts.dart';

/// MiniMax AI Provider
class MiniMaxProvider extends AiProvider {
  @override
  String get id => 'minimax';

  @override
  String get name => 'MiniMax';

  @override
  Future<List<StructuredCourse>> parse(RawScheduleData raw) async {
    throw UnimplementedError('请在设置中配置 MiniMax API Key');
  }

  @override
  Future<String> callApi(String text, String apiKey) async {
    // MiniMax 使用不同的 API 格式
    final body = jsonEncode({
      'model': 'MiniMax-M2.7',
      'messages': [
        {'role': 'system', 'content': scheduleParsingSystemPrompt},
        {'role': 'user', 'content': scheduleParsingUserPrompt + text},
      ],
      'max_tokens': 4096,
    });

    final response = await http.post(
      Uri.parse('https://api.minimax.chat/v1/text/chatcompletion_v2'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('MiniMax API 错误：${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      // 调试：返回完整响应以便排查
      throw Exception('MiniMax 返回空结果，原始响应：${response.body}');
    }
    final firstChoice = choices.first;
    if (firstChoice is! Map) throw Exception('MiniMax 返回格式错误');
    final message = firstChoice['message'] as Map?;
    if (message == null) throw Exception('MiniMax 返回格式错误');
    return (message['content'] as String?) ?? '[]';
  }
}
