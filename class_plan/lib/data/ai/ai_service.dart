import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/model/raw_schedule_data.dart';
import '../../domain/model/structured_course.dart';
import 'ai_provider.dart';
import 'providers/claude_provider.dart';
import 'providers/kimi_provider.dart';
import 'providers/minimax_provider.dart';
import 'providers/deepseek_provider.dart';
import 'providers/chatgpt_provider.dart';

/// AI 服务
/// 统一管理所有 AI Provider 和用户配置
class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// 所有注册的 Provider
  final Map<String, AiProvider> _providers = {
    'claude': ClaudeProvider(),
    'kimi': KIMIProvider(),
    'minimax': MiniMaxProvider(),
    'deepseek': DeepSeekProvider(),
    'chatgpt': ChatGPTProvider(),
  };

  /// 可用的 Provider 列表（供 UI 显示）
  List<AiProviderInfo> get availableProviders => [
    AiProviderInfo(
      id: 'claude',
      name: 'Claude',
      description: 'Anthropic 开发的 AI助手',
      requiresApiKey: true,
    ),
    AiProviderInfo(
      id: 'kimi',
      name: 'KIMI (Moonshot)',
      description: '月之暗面开发的 AI助手',
      requiresApiKey: true,
    ),
    AiProviderInfo(
      id: 'minimax',
      name: 'MiniMax',
      description: 'MiniMax 开发的 AI助手',
      requiresApiKey: true,
    ),
    AiProviderInfo(
      id: 'deepseek',
      name: 'DeepSeek',
      description: '深度求索开发的 AI助手',
      requiresApiKey: true,
    ),
    AiProviderInfo(
      id: 'chatgpt',
      name: 'ChatGPT (OpenAI)',
      description: 'OpenAI 开发的 AI助手',
      requiresApiKey: true,
    ),
  ];

  /// 当前选择的 Provider ID
  String get selectedProviderId => _prefs.getString('ai_selected_provider') ?? 'claude';

  /// 获取当前 Provider
  AiProvider get selectedProvider {
    final id = selectedProviderId;
    return _providers[id] ?? _providers['claude']!;
  }

  /// 获取某个 Provider 的 API Key
  String? getApiKey(String providerId) {
    return _prefs.getString('ai_key_$providerId');
  }

  /// 检查某个 Provider 是否已配置
  bool isProviderConfigured(String providerId) {
    final key = getApiKey(providerId);
    return key != null && key.isNotEmpty;
  }

  /// 检查当前选择的 Provider 是否已配置
  bool get isCurrentProviderConfigured {
    return isProviderConfigured(selectedProviderId);
  }

  /// 初始化
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// 设置 API Key
  Future<void> setApiKey(String providerId, String apiKey) async {
    await _prefs.setString('ai_key_$providerId', apiKey);
  }

  /// 删除 API Key
  Future<void> removeApiKey(String providerId) async {
    await _prefs.remove('ai_key_$providerId');
  }

  /// 选择 Provider
  Future<void> selectProvider(String providerId) async {
    await _prefs.setString('ai_selected_provider', providerId);
  }

  /// 使用当前选择的 Provider 解析课表
  Future<List<StructuredCourse>> parse(RawScheduleData raw) async {
    final provider = selectedProvider;
    final apiKey = getApiKey(selectedProviderId);

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('未配置 ${provider.name} 的 API Key，请在设置中配置');
    }

    try {
      final response = await provider.callApi(raw.rawText, apiKey);
      return provider.parseJsonResponse(response);
    } catch (e) {
      // 重新抛出，保留原始堆栈
      rethrow;
    }
  }
}

/// Provider 信息（供 UI 显示）
class AiProviderInfo {
  final String id;
  final String name;
  final String description;
  final bool requiresApiKey;

  AiProviderInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.requiresApiKey,
  });
}
