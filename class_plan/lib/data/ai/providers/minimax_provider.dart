import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../domain/model/raw_schedule_data.dart';
import '../../../domain/model/structured_course.dart';
import '../ai_provider.dart';
import '../ai_prompts.dart';
import '../../../presentation/debug/debug_log_screen.dart';

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
    DebugLogService().debug('MiniMax.callApi 开始调用，文本长度: ${text.length}', tag: 'MiniMax');
    // MiniMax 使用不同的 API 格式
    final body = jsonEncode({
      'model': 'MiniMax-M2.7',
      'messages': [
        {'role': 'system', 'content': scheduleParsingSystemPrompt},
        {'role': 'user', 'content': scheduleParsingUserPrompt + text},
      ],
      'max_tokens': 4096,
    });

    DebugLogService().debug('发送请求到 https://api.minimax.chat/v1/text/chatcompletion_v2', tag: 'MiniMax');
    final response = await http.post(
      Uri.parse('https://api.minimax.chat/v1/text/chatcompletion_v2'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );
    DebugLogService().debug('MiniMax 响应状态码: ${response.statusCode}', tag: 'MiniMax');

    if (response.statusCode != 200) {
      DebugLogService().error('MiniMax API 错误：${response.statusCode} ${response.body}', tag: 'MiniMax');
      throw Exception('MiniMax API 错误：${response.statusCode} ${response.body}');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      DebugLogService().error('MiniMax JSON 解析失败：$e，原始响应：${response.body}', tag: 'MiniMax');
      throw Exception('MiniMax JSON 解析失败：$e，原始响应：${response.body}');
    }

    // 检查是否有 API 错误
    if (data.containsKey('error')) {
      DebugLogService().error('MiniMax API 返回错误：${data['error']}', tag: 'MiniMax');
      throw Exception('MiniMax API 返回错误：${data['error']}');
    }

    final choices = data['choices'];
    if (choices == null) {
      DebugLogService().error('MiniMax 返回空 choices，原始响应：${response.body}', tag: 'MiniMax');
      throw Exception('MiniMax 返回空 choices，原始响应：${response.body}');
    }
    if (choices is! List) {
      DebugLogService().error('MiniMax choices 类型错误：${choices.runtimeType}，原始响应：${response.body}', tag: 'MiniMax');
      throw Exception('MiniMax choices 类型错误：${choices.runtimeType}，原始响应：${response.body}');
    }
    if (choices.isEmpty) {
      DebugLogService().error('MiniMax 返回空结果，原始响应：${response.body}', tag: 'MiniMax');
      throw Exception('MiniMax 返回空结果，原始响应：${response.body}');
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map) throw Exception('MiniMax 返回格式错误');
    final message = firstChoice['message'] as Map?;
    if (message == null) throw Exception('MiniMax message 为空');
    final content = message['content'];
    if (content == null) return '[]';
    return content.toString();
  }
}
