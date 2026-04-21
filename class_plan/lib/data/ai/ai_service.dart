import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/model/raw_schedule_data.dart';
import '../../domain/model/structured_course.dart';
import 'ai_provider.dart';
import 'providers/claude_provider.dart';
import 'providers/kimi_provider.dart';
import 'providers/minimax_provider.dart';
import 'providers/deepseek_provider.dart';
import 'providers/chatgpt_provider.dart';

/// AI service
/// Manages all AI providers and user configuration
class AiService {
  static final AiService _instance = AiService._();
  factory AiService() => _instance;
  AiService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// All registered providers
  final Map<String, AiProvider> _providers = {
    'claude': ClaudeProvider(),
    'kimi': KIMIProvider(),
    'minimax': MiniMaxProvider(),
    'deepseek': DeepSeekProvider(),
    'chatgpt': ChatGPTProvider(),
  };

  /// Available provider list (for UI display)
  List<AiProviderInfo> get availableProviders => [
    AiProviderInfo(
      id: 'claude',
      name: 'Claude',
      description: 'Anthropic AI assistant',
      requiresApiKey: true,
    ),
    AiProviderInfo(
      id: 'kimi',
      name: 'KIMI (Moonshot)',
      description: 'Moonshot AI assistant',
      requiresApiKey: true,
    ),
    AiProviderInfo(
      id: 'minimax',
      name: 'MiniMax',
      description: 'MiniMax AI assistant',
      requiresApiKey: true,
    ),
    AiProviderInfo(
      id: 'deepseek',
      name: 'DeepSeek',
      description: 'DeepSeek AI assistant',
      requiresApiKey: true,
    ),
    AiProviderInfo(
      id: 'chatgpt',
      name: 'ChatGPT (OpenAI)',
      description: 'OpenAI ChatGPT',
      requiresApiKey: true,
    ),
  ];

  /// Current selected provider ID
  String get selectedProviderId => _prefs.getString('ai_selected_provider') ?? 'claude';

  /// Get current provider
  AiProvider get selectedProvider {
    final id = selectedProviderId;
    return _providers[id] ?? _providers['claude']!;
  }

  /// Get API key for a provider
  String? getApiKey(String providerId) {
    return _prefs.getString('ai_key_$providerId');
  }

  /// Check if a provider is configured
  bool isProviderConfigured(String providerId) {
    final key = getApiKey(providerId);
    return key != null && key.isNotEmpty;
  }

  /// Check if current provider is configured
  bool get isCurrentProviderConfigured {
    return isProviderConfigured(selectedProviderId);
  }

  /// Initialize
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// Set API key
  Future<void> setApiKey(String providerId, String apiKey) async {
    await _prefs.setString('ai_key_$providerId', apiKey);
  }

  /// Remove API key
  Future<void> removeApiKey(String providerId) async {
    await _prefs.remove('ai_key_$providerId');
  }

  /// Select provider
  Future<void> selectProvider(String providerId) async {
    await _prefs.setString('ai_selected_provider', providerId);
  }

  /// Parse schedule using current provider, fallback to other configured providers on failure
  Future<List<StructuredCourse>> parse(RawScheduleData raw) async {
    // Get all configured providers in priority order
    final providers = _getConfiguredProvidersInOrder();

    if (providers.isEmpty) {
      throw Exception('No AI provider configured');
    }

    Exception? lastError;
    final triedProviders = <String>[];

    for (final config in providers) {
      triedProviders.add(config.provider.name);

      try {
        final response = await config.provider.callApi(raw.rawText, config.apiKey);
        final result = config.provider.parseJsonResponse(response);
        if (result.isNotEmpty) {
          // Success
          return result;
        }
        // Empty result, try next provider
        lastError = Exception('${config.provider.name} returned empty result');
      } catch (e) {
        lastError = Exception('${config.provider.name} failed: $e');
        // Continue to next provider
      }
    }

    // All providers failed
    final triedNames = triedProviders.join(', ');
    throw Exception('All AI providers failed. Tried: $triedNames. Last error: $lastError');
  }

  /// Get configured providers in priority order
  List<_ProviderConfig> _getConfiguredProvidersInOrder() {
    final result = <_ProviderConfig>[];

    // Add current selected provider first
    final currentId = selectedProviderId;
    if (isProviderConfigured(currentId)) {
      result.add(_ProviderConfig(currentId, selectedProvider, getApiKey(currentId)!));
    }

    // Add other configured providers
    for (final id in _providers.keys) {
      if (id != currentId && isProviderConfigured(id)) {
        result.add(_ProviderConfig(id, _providers[id]!, getApiKey(id)!));
      }
    }

    return result;
  }
}

/// Provider configuration
class _ProviderConfig {
  final String id;
  final AiProvider provider;
  final String apiKey;

  _ProviderConfig(this.id, this.provider, this.apiKey);
}

/// Provider info (for UI display)
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
