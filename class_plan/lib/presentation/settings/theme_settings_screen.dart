import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/app_module.dart';
import '../../data/theme/theme_service.dart';
import '../../domain/model/app_theme.dart';
import '../../main.dart';

/// 主题选择页面
class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  ConsumerState<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  AppTheme? _currentTheme;
  List<AppTheme> _allThemes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThemes();
  }

  Future<void> _loadThemes() async {
    final service = ThemeService();
    await service.initialize();

    final current = await service.getCurrentTheme();
    final all = await service.getAllThemes();

    setState(() {
      _currentTheme = current;
      _allThemes = all;
      _isLoading = false;
    });
  }

  Future<void> _selectTheme(AppTheme theme) async {
    final service = ThemeService();
    await service.setCurrentTheme(theme);

    // 通知应用主题 Provider
    ref.read(appThemeProvider.notifier).state = theme;

    setState(() => _currentTheme = theme);

    // 通知应用重新构建
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换到"${theme.name}"主题'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addCustomTheme() async {
    final name = await _showNameDialog();
    if (name == null || name.isEmpty) return;

    final color = await _showColorPicker();
    if (color == null) return;

    final service = ThemeService();
    final newTheme = await service.addCustomTheme(name: name, seedColor: color);

    await _loadThemes();
    await _selectTheme(newTheme);
  }

  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('主题名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入主题名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  Future<Color?> _showColorPicker() async {
    return showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(),
    );
  }

  Future<void> _deleteCustomTheme(AppTheme theme) async {
    if (!theme.isCustom) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除主题'),
        content: Text('确定要删除"${theme.name}"主题吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final service = ThemeService();
      await service.deleteCustomTheme(theme.id);
      await _loadThemes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题设置'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 当前主题预览
                if (_currentTheme != null) ...[
                  _buildCurrentThemeCard(_currentTheme!),
                  const SizedBox(height: 24),
                ],

                // 预设主题
                const Text(
                  '预设主题',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildThemeGrid(
                  PresetThemes.presets,
                  showDelete: false,
                ),

                const SizedBox(height: 24),

                // 自定义主题
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '自定义主题',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      onPressed: _addCustomTheme,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('添加'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _customThemes.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.palette_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              '暂无自定义主题',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '点击上方"添加"创建自定义主题',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : _buildThemeGrid(
                        _customThemes,
                        showDelete: true,
                      ),
              ],
            ),
    );
  }

  List<AppTheme> get _customThemes =>
      _allThemes.where((t) => t.isCustom).toList();

  Widget _buildCurrentThemeCard(AppTheme theme) {
    final lightColor = Color(0xFFFFFFFF);
    final darkColor = Color(0xFF1C1C1E);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.seedColor,
            theme.seedColor.withAlpha(179),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                '当前使用',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            theme.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildColorChip(lightColor),
              const SizedBox(width: 8),
              _buildColorChip(theme.seedColor),
              const SizedBox(width: 8),
              _buildColorChip(darkColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorChip(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white30),
      ),
    );
  }

  Widget _buildThemeGrid(List<AppTheme> themes, {required bool showDelete}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = theme.id == _currentTheme?.id;
        return _ThemeCard(
          theme: theme,
          isSelected: isSelected,
          showDelete: showDelete && theme.isCustom,
          onTap: () => _selectTheme(theme),
          onDelete: () => _deleteCustomTheme(theme),
        );
      },
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.showDelete,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.seedColor,
                    theme.seedColor.withAlpha(179),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.black, width: 2)
                    : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.seedColor.withAlpha(102),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: theme.seedColor == Colors.white
                          ? const SizedBox()
                          : Container(
                              decoration: BoxDecoration(
                                color: theme.seedColor.withAlpha(128),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  if (showDelete)
                    Positioned(
                      top: 2,
                      left: 2,
                      child: GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            theme.name,
            style: const TextStyle(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  static const List<Color> _presetColors = [
    Color(0xFF2196F3), // 蓝
    Color(0xFF4CAF50), // 绿
    Color(0xFF9C27B0), // 紫
    Color(0xFFFF9800), // 橙
    Color(0xFFE91E63), // 红
    Color(0xFF009688), // 青
    Color(0xFF3F51B5), // 靛
    Color(0xFFFF4081), // 粉
    Color(0xFF795548), // 棕
    Color(0xFF607D8B), // 灰蓝
    Color(0xFFCDDC39), // 黄绿
    Color(0xFF00BCD4), // 碧
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = _presetColors.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 280,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _presetColors.map((color) {
            final isSelected = _selectedColor.value == color.value;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('确定'),
        ),
      ],
    );
  }
}