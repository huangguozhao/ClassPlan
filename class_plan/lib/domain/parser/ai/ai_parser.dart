import '../../../data/ai/ai_service.dart';
import '../../../domain/model/raw_schedule_data.dart';
import '../../../domain/model/structured_course.dart';
import '../schedule_parser.dart';

/// AI 解析器
/// 使用 AiService 的统一入口，支持多 Provider 自动降级
class AiParser implements ScheduleParser {
  AiParser();

  @override
  String get name => 'AI 解析';

  @override
  int get priority => 2; // 规则解析失败后再用 AI

  @override
  Future<List<StructuredCourse>> parse(RawScheduleData raw) async {
    final aiService = AiService();
    await aiService.initialize();

    if (!aiService.isCurrentProviderConfigured) {
      throw Exception('未配置 AI API Key，无法使用 AI 解析功能。请在设置中配置。');
    }

    return await aiService.parse(raw);
  }
}
