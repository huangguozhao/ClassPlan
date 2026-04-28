import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../domain/model/app_theme.dart';
import '../../domain/model/theme_package.dart';

const String _themeKey = 'app_theme_config';
const String _customThemesKey = 'custom_themes';
const String _downloadedThemesKey = 'downloaded_themes';
const String _themePackageKey = 'theme_package_config';
const String _customThemePackagesKey = 'custom_theme_packages';

/// 云端主题信息（从服务器获取）
class CloudThemeInfo {
  final String id;
  final String name;
  final String author;
  final String version;
  final String description;
  final String previewUrl;
  final String downloadUrl;
  final int sizeKB;
  final DateTime createdAt;
  final bool isDownloaded;
  final String? localVersion;

  CloudThemeInfo({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.description,
    required this.previewUrl,
    required this.downloadUrl,
    required this.sizeKB,
    required this.createdAt,
    this.isDownloaded = false,
    this.localVersion,
  });

  factory CloudThemeInfo.fromJson(Map<String, dynamic> json, {bool downloaded = false, String? localVer}) {
    return CloudThemeInfo(
      id: json['id'],
      name: json['name'],
      author: json['author'] ?? '未知',
      version: json['version'] ?? '1.0.0',
      description: json['description'] ?? '',
      previewUrl: json['previewUrl'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      sizeKB: json['sizeKB'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      isDownloaded: downloaded,
      localVersion: localVer,
    );

  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'author': author,
    'version': version,
    'description': description,
    'previewUrl': previewUrl,
    'downloadUrl': downloadUrl,
    'sizeKB': sizeKB,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// 下载的主题配置
class DownloadedThemeConfig {
  final String id;
  final String name;
  final String author;
  final String version;
  final Color seedColor;
  final Map<String, dynamic> config;
  final DateTime downloadedAt;

  DownloadedThemeConfig({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    required this.seedColor,
    required this.config,
    required this.downloadedAt,
  });

  factory DownloadedThemeConfig.fromJson(Map<String, dynamic> json) {
    return DownloadedThemeConfig(
      id: json['id'],
      name: json['name'],
      author: json['author'] ?? '未知',
      version: json['version'] ?? '1.0.0',
      seedColor: Color(json['seedColor'] as int),
      config: json['config'] ?? {},
      downloadedAt: DateTime.parse(json['downloadedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'author': author,
    'version': version,
    'seedColor': seedColor.value,
    'config': config,
    'downloadedAt': downloadedAt.toIso8601String(),
  };

  /// 转换为 AppTheme
  AppTheme toAppTheme() => AppTheme(
    id: 'cloud_$id',
    name: name,
    seedColor: seedColor,
    isCustom: false,
  );
}

/// 主题管理服务
class ThemeService {
  static final ThemeService _instance = ThemeService._();
  factory ThemeService() => _instance;
  ThemeService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  /// 云端主题市场地址（示例）
  // 可以替换成真实的服务地址
  static const String _manifestUrl = 'https://api.example.com/themes/manifest.json';

  /// 初始化
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ============ 本地主题管理 ============

  /// 获取当前主题
  Future<AppTheme> getCurrentTheme() async {
    await initialize();
    final jsonStr = _prefs.getString(_themeKey);
    if (jsonStr == null) {
      return PresetThemes.presets.first;
    }
    try {
      return AppTheme.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return PresetThemes.presets.first;
    }
  }

  /// 设置当前主题
  Future<void> setCurrentTheme(AppTheme theme) async {
    await initialize();
    await _prefs.setString(_themeKey, jsonEncode(theme.toJson()));
  }

  /// 获取所有自定义主题
  Future<List<AppTheme>> getCustomThemes() async {
    await initialize();
    final jsonStr = _prefs.getString(_customThemesKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => AppTheme.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 添加自定义主题
  Future<AppTheme> addCustomTheme({
    required String name,
    required Color seedColor,
    Brightness brightness = Brightness.light,
  }) async {
    await initialize();

    final uuid = const Uuid();
    final theme = AppTheme(
      id: uuid.v4(),
      name: name,
      seedColor: seedColor,
      brightness: brightness,
      isCustom: true,
    );

    final themes = await getCustomThemes();
    themes.add(theme);

    await _prefs.setString(_customThemesKey, jsonEncode(themes.map((t) => t.toJson()).toList()));

    return theme;
  }

  /// 删除自定义主题
  Future<void> deleteCustomTheme(String themeId) async {
    await initialize();

    final themes = await getCustomThemes();
    themes.removeWhere((t) => t.id == themeId);

    await _prefs.setString(_customThemesKey, jsonEncode(themes.map((t) => t.toJson()).toList()));

    final current = await getCurrentTheme();
    if (current.id == themeId && current.isCustom) {
      await _prefs.remove(_themeKey);
    }
  }

  /// 获取所有可用主题（预设 + 自定义）
  Future<List<AppTheme>> getAllLocalThemes() async {
    final customThemes = await getCustomThemes();
    return [...PresetThemes.presets, ...customThemes];
  }

  // ============ 专业版主题包管理 ============

  /// 获取当前主题包（可能是简单的 AppTheme 或完整的 ThemePackage）
  Future<ThemePackage?> getCurrentThemePackage() async {
    await initialize();
    final jsonStr = _prefs.getString(_themePackageKey);
    if (jsonStr == null) return null;
    try {
      return ThemePackage.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  /// 设置当前主题包
  Future<void> setCurrentThemePackage(ThemePackage package) async {
    await initialize();
    await _prefs.setString(_themePackageKey, jsonEncode(package.toJson()));
  }

  /// 获取所有自定义主题包
  Future<List<ThemePackage>> getCustomThemePackages() async {
    await initialize();
    final jsonStr = _prefs.getString(_customThemePackagesKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => ThemePackage.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 添加自定义主题包
  Future<ThemePackage> addCustomThemePackage({
    required String name,
    required Color seedColor,
    Brightness brightness = Brightness.light,
  }) async {
    await initialize();

    final uuid = const Uuid();
    final package = ThemePackage(
      id: uuid.v4(),
      name: name,
      author: '本地用户',
      version: '1.0.0',
      description: '自定义主题包',
      colors: ColorPackage.defaultLight(),
    );

    final packages = await getCustomThemePackages();
    packages.add(package);

    await _prefs.setString(
      _customThemePackagesKey,
      jsonEncode(packages.map((p) => p.toJson()).toList()),
    );

    return package;
  }

  /// 删除自定义主题包
  Future<void> deleteCustomThemePackage(String packageId) async {
    await initialize();

    final packages = await getCustomThemePackages();
    packages.removeWhere((p) => p.id == packageId);

    await _prefs.setString(
      _customThemePackagesKey,
      jsonEncode(packages.map((p) => p.toJson()).toList()),
    );

    final current = await getCurrentThemePackage();
    if (current?.id == packageId) {
      await _prefs.remove(_themePackageKey);
    }
  }

  /// 获取所有可用主题包（预设 + 自定义）
  Future<List<ThemePackage>> getAllThemePackages() async {
    final customPackages = await getCustomThemePackages();
    return [...PresetThemes.packages, ...customPackages];
  }

  // ============ 云端主题管理 ============

  /// 获取云端主题列表
  Future<List<CloudThemeInfo>> fetchCloudThemes() async {
    try {
      // 实际项目中这里会请求真实服务器
      // final response = await http.get(Uri.parse(_manifestUrl));
      // final json = jsonDecode(response.body);

      // 示例：返回模拟的云端主题
      return _getMockCloudThemes();
    } catch (e) {
      return [];
    }
  }

  /// 下载云端主题
  Future<DownloadedThemeConfig> downloadCloudTheme(String themeId) async {
    // 实际项目中：
    // 1. 获取主题下载 URL
    // 2. 下载主题配置 JSON
    // 3. 解析并保存到本地

    // 示例：模拟下载
    final mockTheme = _getMockCloudThemes().firstWhere(
      (t) => t.id == themeId,
      orElse: () => throw Exception('主题不存在'),
    );

    // 模拟下载延迟
    await Future.delayed(const Duration(seconds: 1));

    // 解析主题配置（实际从 downloadUrl 获取）
    final config = _parseMockThemeConfig(themeId);

    final downloaded = DownloadedThemeConfig(
      id: mockTheme.id,
      name: mockTheme.name,
      author: mockTheme.author,
      version: mockTheme.version,
      seedColor: _getThemeColor(themeId),
      config: config,
      downloadedAt: DateTime.now(),
    );

    // 保存到本地
    await _saveDownloadedTheme(downloaded);

    return downloaded;
  }

  /// 获取已下载的云端主题
  Future<List<DownloadedThemeConfig>> getDownloadedThemes() async {
    await initialize();
    final jsonStr = _prefs.getString(_downloadedThemesKey);
    if (jsonStr == null) return [];
    try {
      final list = jsonDecode(jsonStr) as List;
      return list.map((e) => DownloadedThemeConfig.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 检查主题是否已下载
  Future<bool> isThemeDownloaded(String themeId) async {
    final downloaded = await getDownloadedThemes();
    return downloaded.any((t) => t.id == themeId);
  }

  /// 删除下载的云端主题
  Future<void> deleteDownloadedTheme(String themeId) async {
    await initialize();

    final themes = await getDownloadedThemes();
    themes.removeWhere((t) => t.id == themeId);

    await _prefs.setString(
      _downloadedThemesKey,
      jsonEncode(themes.map((t) => t.toJson()).toList()),
    );

    // 如果当前使用这个主题，重置
    final current = await getCurrentTheme();
    if (current.id == 'cloud_$themeId') {
      await _prefs.remove(_themeKey);
    }
  }

  /// 将下载的主题应用到当前
  Future<void> applyDownloadedTheme(String themeId) async {
    final themes = await getDownloadedThemes();
    final theme = themes.firstWhere(
      (t) => t.id == themeId,
      orElse: () => throw Exception('主题未下载'),
    );

    final appTheme = theme.toAppTheme();
    await setCurrentTheme(appTheme);
  }

  Future<void> _saveDownloadedTheme(DownloadedThemeConfig theme) async {
    final themes = await getDownloadedThemes();
    themes.removeWhere((t) => t.id == theme.id); // 移除旧版本
    themes.add(theme);

    await _prefs.setString(
      _downloadedThemesKey,
      jsonEncode(themes.map((t) => t.toJson()).toList()),
    );
  }

  // ============ 模拟数据（实际项目中替换为真实 API） ============

  List<CloudThemeInfo> _getMockCloudThemes() {
    return [
      CloudThemeInfo(
        id: 'aurora',
        name: '极光',
        author: '设计师A',
        version: '1.0.0',
        description: '灵感来自北极光，蓝绿渐变风格',
        previewUrl: 'https://example.com/previews/aurora.png',
        downloadUrl: 'https://example.com/themes/aurora.json',
        sizeKB: 128,
        createdAt: DateTime(2025, 1, 15),
      ),
      CloudThemeInfo(
        id: 'sunset',
        name: '日落',
        author: '设计师B',
        version: '1.1.0',
        description: '温暖的橙红渐变，适合夜间使用',
        previewUrl: 'https://example.com/previews/sunset.png',
        downloadUrl: 'https://example.com/themes/sunset.json',
        sizeKB: 256,
        createdAt: DateTime(2025, 2, 20),
      ),
      CloudThemeInfo(
        id: 'forest',
        name: '森林',
        author: '设计师C',
        version: '1.0.0',
        description: '清新自然的绿色主题',
        previewUrl: 'https://example.com/previews/forest.png',
        downloadUrl: 'https://example.com/themes/forest.json',
        sizeKB: 180,
        createdAt: DateTime(2025, 3, 10),
      ),
      CloudThemeInfo(
        id: 'midnight',
        name: '午夜',
        author: '设计师D',
        version: '2.0.0',
        description: '深邃的深蓝色，适合专注学习',
        previewUrl: 'https://example.com/previews/midnight.png',
        downloadUrl: 'https://example.com/themes/midnight.json',
        sizeKB: 200,
        createdAt: DateTime(2025, 4, 1),
      ),
    ];
  }

  Map<String, dynamic> _parseMockThemeConfig(String themeId) {
    switch (themeId) {
      case 'aurora':
        return {
          'seedColor': 0xFF00BCD4,
          'gradientColors': [0xFF00BCD4, 0xFF009688],
        };
      case 'sunset':
        return {
          'seedColor': 0xFFFF7043,
          'gradientColors': [0xFFFF7043, 0xFFFFAB91],
        };
      case 'forest':
        return {
          'seedColor': 0xFF4CAF50,
          'gradientColors': [0xFF4CAF50, 0xFF81C784],
        };
      case 'midnight':
        return {
          'seedColor': 0xFF3F51B5,
          'gradientColors': [0xFF3F51B5, 0xFF5C6BC0],
        };
      default:
        return {'seedColor': 0xFF2196F3};
    }
  }

  Color _getThemeColor(String themeId) {
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