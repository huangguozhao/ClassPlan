import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/theme/theme_service.dart';
import '../../domain/model/app_theme.dart';
import '../../domain/model/theme_package.dart';
import '../../main.dart';

/// 主题市场页面（本地 + 云端）
class ThemeMarketScreen extends ConsumerStatefulWidget {
  const ThemeMarketScreen({super.key});

  @override
  ConsumerState<ThemeMarketScreen> createState() => _ThemeMarketScreenState();
}

class _ThemeMarketScreenState extends ConsumerState<ThemeMarketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<AppTheme> _localThemes = [];
  List<ThemePackage> _localPackages = [];
  List<CloudThemeInfo> _cloudThemes = [];
  List<DownloadedThemeConfig> _downloadedThemes = [];
  AppTheme? _currentTheme;
  ThemePackage? _currentPackage;
  bool _isLoading = true;
  String? _downloadingId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final service = ThemeService();
    await service.initialize();

    final localThemes = await service.getAllLocalThemes();
    final localPackages = await service.getAllThemePackages();
    final cloudThemes = await service.fetchCloudThemes();
    final downloadedThemes = await service.getDownloadedThemes();
    final currentTheme = await service.getCurrentTheme();
    final currentPackage = await service.getCurrentThemePackage();

    setState(() {
      _localThemes = localThemes;
      _localPackages = localPackages;
      _cloudThemes = cloudThemes;
      _downloadedThemes = downloadedThemes;
      _currentTheme = currentTheme;
      _currentPackage = currentPackage;
      _isLoading = false;
    });
  }

  Future<void> _selectTheme(AppTheme theme) async {
    final service = ThemeService();
    await service.setCurrentTheme(theme);
    // 清除主题包
    await service.setCurrentThemePackage(theme.toThemePackage());

    ref.read(appThemeProvider.notifier).state = theme;
    ref.read(themePackageProvider.notifier).state = null;

    setState(() => _currentTheme = theme);
    setState(() => _currentPackage = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换到"${theme.name}"主题'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _selectThemePackage(ThemePackage package) async {
    final service = ThemeService();
    await service.setCurrentThemePackage(package);

    ref.read(themePackageProvider.notifier).state = package;

    setState(() => _currentPackage = package);
    setState(() => _currentTheme = null);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已切换到"${package.name}"主题'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _downloadTheme(CloudThemeInfo cloudTheme) async {
    setState(() => _downloadingId = cloudTheme.id);

    try {
      final service = ThemeService();
      final downloaded = await service.downloadCloudTheme(cloudTheme.id);

      // 应用下载的主题
      await _selectTheme(downloaded.toAppTheme());

      // 刷新列表
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${cloudTheme.name}"下载并应用成功'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败：$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _downloadingId = null);
    }
  }

  Future<void> _deleteDownloadedTheme(String themeId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除主题'),
        content: const Text('确定要删除这个下载的主题吗？'),
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
      await service.deleteDownloadedTheme(themeId);
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('主题商店'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '本地主题'),
            Tab(text: '专业主题'),
            Tab(text: '云端主题'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLocalTab(),
                _buildProTab(),
                _buildCloudTab(),
              ],
            ),
    );
  }

  Widget _buildLocalTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 当前使用
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
            ? _buildEmptyState(
                icon: Icons.palette_outlined,
                message: '暂无自定义主题',
                hint: '点击上方"添加"创建自定义主题',
              )
            : _buildThemeGrid(
                _customThemes,
                showDelete: true,
              ),

        const SizedBox(height: 24),

        // 已下载的云端主题
        if (_downloadedThemes.isNotEmpty) ...[
          const Text(
            '已下载的云端主题',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ..._downloadedThemes.map((t) => _buildDownloadedThemeItem(t)),
        ],
      ],
    );
  }

  Widget _buildProTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 当前使用
        if (_currentPackage != null) ...[
          _buildCurrentPackageCard(_currentPackage!),
          const SizedBox(height: 24),
        ],

        // 预设专业主题
        const Text(
          '预设专业主题',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        const Text(
          '完整定制化主题包，支持颜色、字体、形状、间距等全部配置',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _buildPackageGrid(
          PresetThemes.packages,
          showDelete: false,
        ),

        const SizedBox(height: 24),

        // 自定义专业主题
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '自定义专业主题',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            TextButton.icon(
              onPressed: _addCustomThemePackage,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('添加'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _customPackages.isEmpty
            ? _buildEmptyState(
                icon: Icons.palette_outlined,
                message: '暂无自定义专业主题',
                hint: '点击上方"添加"创建专业主题',
              )
            : _buildPackageGrid(
                _customPackages,
                showDelete: true,
              ),
      ],
    );
  }

  Widget _buildCurrentPackageCard(ThemePackage package) {
    final lightScheme = package.colors.toColorScheme(Brightness.light);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            lightScheme.primary,
            lightScheme.primary.withAlpha(179),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            '当前使用',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                package.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '专业版',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPackageGrid(List<ThemePackage> packages, {required bool showDelete}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final package = packages[index];
        final isSelected = _currentPackage?.id == package.id;
        return _buildPackageCard(
          package: package,
          isSelected: isSelected,
          showDelete: showDelete && !PresetThemes.packages.any((p) => p.id == package.id),
          onTap: () => _selectThemePackage(package),
          onDelete: () => _deleteCustomPackage(package),
        );
      },
    );
  }

  Widget _buildPackageCard({
    required ThemePackage package,
    required bool isSelected,
    required bool showDelete,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final lightScheme = package.colors.toColorScheme(Brightness.light);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              lightScheme.primary,
              lightScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: lightScheme.primary.withAlpha(77),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    package.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    package.author,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    package.description ?? '',
                    style: const TextStyle(color: Colors.white60, fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showDelete)
              Positioned(
                top: 4,
                left: 4,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<ThemePackage> get _customPackages =>
      _localPackages.where((p) => !PresetThemes.packages.any((preset) => preset.id == p.id)).toList();

  Future<void> _addCustomThemePackage() async {
    final name = await _showNameDialog();
    if (name == null || name.isEmpty) return;

    final color = await _showColorPicker();
    if (color == null) return;

    final service = ThemeService();
    final newPackage = await service.addCustomThemePackage(name: name, seedColor: color);

    await _loadData();
    await _selectThemePackage(newPackage);
  }

  Future<void> _deleteCustomPackage(ThemePackage package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除主题'),
        content: Text('确定要删除"${package.name}"主题吗？'),
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
      await service.deleteCustomThemePackage(package.id);
      await _loadData();
    }
  }

  Widget _buildCloudTab() {
    if (_cloudThemes.isEmpty) {
      return _buildEmptyState(
        icon: Icons.cloud_off,
        message: '无法获取云端主题',
        hint: '请检查网络连接后重试',
        action: ElevatedButton(
          onPressed: _loadData,
          child: const Text('重试'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cloudThemes.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCloudHeader(),
              const SizedBox(height: 16),
            ],
          );
        }

        final cloudTheme = _cloudThemes[index - 1];
        return _buildCloudThemeItem(cloudTheme);
      },
    );
  }

  Widget _buildCloudHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '云端主题市场',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_cloudThemes.length} 个主题可选',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudThemeItem(CloudThemeInfo theme) {
    final isDownloading = _downloadingId == theme.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // 预览色块
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getCloudThemeColor(theme.id),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.palette, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // 主题信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        theme.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'v${theme.version}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '作者：${theme.author}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    theme.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 操作按钮
            if (isDownloading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              OutlinedButton(
                onPressed: () => _downloadTheme(theme),
                child: const Text('下载'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadedThemeItem(DownloadedThemeConfig theme) {
    final isSelected = _currentTheme?.id == 'cloud_${theme.id}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.seedColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        title: Text(theme.name),
        subtitle: Text('v${theme.version} · ${theme.author}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.green),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteDownloadedTheme(theme.id),
            ),
          ],
        ),
        onTap: () => _selectTheme(theme.toAppTheme()),
      ),
    );
  }

  Widget _buildCurrentThemeCard(AppTheme theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.seedColor,
            theme.seedColor.withAlpha(179),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white),
          const SizedBox(width: 8),
          const Text(
            '当前使用',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const Spacer(),
          Text(
            theme.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        return _buildThemeCard(
          theme: theme,
          isSelected: isSelected,
          showDelete: showDelete && theme.isCustom,
          onTap: () => _selectTheme(theme),
          onDelete: () => _deleteCustomTheme(theme),
        );
      },
    );
  }

  Widget _buildThemeCard({
    required AppTheme theme,
    required bool isSelected,
    required bool showDelete,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
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
                ),
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.black, width: 2)
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
                    ),
                  ),
                  if (isSelected)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: Icon(Icons.check_circle, color: Colors.white, size: 18),
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
                          child: const Icon(Icons.close, color: Colors.white, size: 12),
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String hint,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            action,
          ],
        ],
      ),
    );
  }

  List<AppTheme> get _customThemes => _localThemes.where((t) => t.isCustom).toList();

  Future<void> _addCustomTheme() async {
    final name = await _showNameDialog();
    if (name == null || name.isEmpty) return;

    final color = await _showColorPicker();
    if (color == null) return;

    final service = ThemeService();
    final newTheme = await service.addCustomTheme(name: name, seedColor: color);

    await _loadData();
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
      await _loadData();
    }
  }

  Color _getCloudThemeColor(String themeId) {
    switch (themeId) {
      case 'aurora':
        return const Color(0xFF00BCD4);
      case 'sunset':
        return const Color(0xFFFF7043);
      case 'forest':
        return const Color(0xFF4CAF50);
      case 'midnight':
        return const Color(0xFF3F51B5);
      default:
        return Colors.blue;
    }
  }
}

class _ColorPickerDialog extends StatefulWidget {
  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  static const List<Color> _presetColors = [
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF009688),
    Color(0xFF3F51B5),
    Color(0xFFFF4081),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFCDDC39),
    Color(0xFF00BCD4),
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
                  border: isSelected ? Border.all(color: Colors.black, width: 3) : null,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('确定'),
        ),
      ],
    );
  }
}