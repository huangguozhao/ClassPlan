import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai/ai_service.dart';

/// AI 设置页面
/// 配置各 AI Provider 的 API Key
class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  final Map<String, TextEditingController> _controllers = {};
  AiService? _aiService;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final service = AiService();
    await service.initialize();

    // 初始化所有 provider 的 controller
    for (final p in service.availableProviders) {
      final existingKey = service.getApiKey(p.id) ?? '';
      _controllers[p.id] = TextEditingController(text: existingKey);
    }

    setState(() {
      _aiService = service;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 设置'),
      ),
      body: _initialized && _aiService != null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '配置多个 AI 的 API Key 后，在导入课程时可以自由选择使用哪个 AI 进行解析。',
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 当前选中的 Provider
                Text(
                  '当前选择：${_aiService!.selectedProvider.name}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // 各 Provider 配置
                ..._aiService!.availableProviders.map((provider) {
                  return _ProviderConfigCard(
                    provider: provider,
                    controller: _controllers[provider.id]!,
                    isSelected: _aiService!.selectedProviderId == provider.id,
                    isConfigured: _aiService!.isProviderConfigured(provider.id),
                    onSelect: () async {
                      await _aiService!.selectProvider(provider.id);
                      setState(() {});
                    },
                    onSave: () async {
                      final key = _controllers[provider.id]!.text.trim();
                      if (key.isNotEmpty) {
                        await _aiService!.setApiKey(provider.id, key);
                      } else {
                        await _aiService!.removeApiKey(provider.id);
                      }
                      setState(() {});
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${provider.name} ${key.isNotEmpty ? "已保存" : "已清除"}'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  );
                }),

                const SizedBox(height: 24),

                // API Key 获取说明
                ExpansionTile(
                  title: const Text('如何获取 API Key？'),
                  children: [
                    _ApiKeyHelpItem(
                      name: 'Claude (Anthropic)',
                      url: 'anthropic.com',
                      hint: '访问 claude.ai 或 anthropic.com 申请',
                    ),
                    _ApiKeyHelpItem(
                      name: 'KIMI (Moonshot)',
                      url: 'console.moonshot.cn',
                      hint: '访问 Moonshot 控制台申请',
                    ),
                    _ApiKeyHelpItem(
                      name: 'DeepSeek',
                      url: 'platform.deepseek.com',
                      hint: '访问 DeepSeek 开放平台申请',
                    ),
                    _ApiKeyHelpItem(
                      name: 'MiniMax',
                      url: 'www.minimax.io',
                      hint: '访问 MiniMax 开放平台申请',
                    ),
                    _ApiKeyHelpItem(
                      name: 'ChatGPT (OpenAI)',
                      url: 'platform.openai.com',
                      hint: '访问 OpenAI API 平台申请',
                    ),
                  ],
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProviderConfigCard extends StatelessWidget {
  final AiProviderInfo provider;
  final TextEditingController controller;
  final bool isSelected;
  final bool isConfigured;
  final VoidCallback onSelect;
  final VoidCallback onSave;

  const _ProviderConfigCard({
    required this.provider,
    required this.controller,
    required this.isSelected,
    required this.isConfigured,
    required this.onSelect,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            provider.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (isConfigured) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 12,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '已配置',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.description,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: provider.id,
                  groupValue: isSelected ? provider.id : null,
                  onChanged: (_) => onSelect(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: _getHintText(provider.id),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: onSave,
                  child: const Text('保存'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getHintText(String id) {
    switch (id) {
      case 'claude':
        return 'sk-ant-...';
      case 'kimi':
        return 'sk-...';
      case 'deepseek':
        return 'sk-...';
      case 'minimax':
        return '输入 API Key';
      case 'chatgpt':
        return 'sk-...';
      default:
        return '输入 API Key';
    }
  }
}

class _ApiKeyHelpItem extends StatelessWidget {
  final String name;
  final String url;
  final String hint;

  const _ApiKeyHelpItem({
    required this.name,
    required this.url,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.link, size: 20),
      title: Text(name, style: const TextStyle(fontSize: 14)),
      subtitle: Text(hint, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: () {
        // 可以在这里打开 URL
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请访问 $url 获取 API Key')),
        );
      },
    );
  }
}
