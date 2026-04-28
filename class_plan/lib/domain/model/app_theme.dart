import 'package:flutter/material.dart';

import 'theme_package.dart';

/// 主题配置数据模型
class AppTheme {
  final String id;
  final String name;
  final Color seedColor;
  final Brightness brightness;
  final bool isCustom;
  final DateTime createdAt;

  AppTheme({
    required this.id,
    required this.name,
    required this.seedColor,
    this.brightness = Brightness.light,
    this.isCustom = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'seedColor': seedColor.value,
    'brightness': brightness.index,
    'isCustom': isCustom,
    'createdAt': createdAt.toIso8601String(),
  };

  /// 从 JSON 创建
  factory AppTheme.fromJson(Map<String, dynamic> json) => AppTheme(
    id: json['id'] as String,
    name: json['name'] as String,
    seedColor: Color(json['seedColor'] as int),
    brightness: Brightness.values[json['brightness'] as int? ?? 0],
    isCustom: json['isCustom'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  /// 深拷贝
  AppTheme copyWith({
    String? id,
    String? name,
    Color? seedColor,
    Brightness? brightness,
    bool? isCustom,
  }) => AppTheme(
    id: id ?? this.id,
    name: name ?? this.name,
    seedColor: seedColor ?? this.seedColor,
    brightness: brightness ?? this.brightness,
    isCustom: isCustom ?? this.isCustom,
    createdAt: createdAt,
  );

  /// 转换为 ThemePackage（简单主题转专业版格式）
  ThemePackage toThemePackage() => ThemePackage(
    id: id,
    name: name,
    author: 'ClassPlan',
    version: '1.0.0',
    description: '简单主题',
    colors: ColorPackage(
      modes: {
        'light': ColorSchemeData(
          primary: seedColor.value,
          onPrimary: 0xFFFFFFFF,
          primaryContainer: seedColor.withAlpha(179).value,
          onPrimaryContainer: 0xFF001F3F,
          secondary: seedColor.value,
          onSecondary: 0xFF000000,
          secondaryContainer: seedColor.withAlpha(128).value,
          onSecondaryContainer: 0xFF002020,
          tertiary: seedColor.value,
          onTertiary: 0xFFFFFFFF,
          tertiaryContainer: seedColor.withAlpha(153).value,
          onTertiaryContainer: 0xFF310037,
          error: 0xFFB00020,
          onError: 0xFFFFFFFF,
          errorContainer: 0xFFFCD8DF,
          onErrorContainer: 0xFF410002,
          surface: 0xFFFFFFFF,
          onSurface: 0xFF1C1B1F,
          surfaceContainerHighest: 0xFFE7E0EC,
          onSurfaceVariant: 0xFF49454E,
          outline: 0xFF79747E,
          outlineVariant: 0xFFCAC4D0,
          shadow: 0xFF000000,
          scrim: 0xFF000000,
          inverseSurface: 0xFF313033,
          onInverseSurface: 0xFFF4EFF4,
          inversePrimary: seedColor.withAlpha(179).value,
          surfaceTintColor: seedColor.value,
        ),
        'dark': ColorSchemeData(
          primary: seedColor.withAlpha(179).value,
          onPrimary: 0xFF003258,
          primaryContainer: seedColor.value,
          onPrimaryContainer: 0xFFD1E4FF,
          secondary: seedColor.withAlpha(179).value,
          onSecondary: 0xFF00332F,
          secondaryContainer: seedColor.withAlpha(128).value,
          onSecondaryContainer: 0xFFA7F3EC,
          tertiary: seedColor.withAlpha(204).value,
          onTertiary: 0xFF3D0050,
          tertiaryContainer: seedColor.value,
          onTertiaryContainer: 0xFFFFD6F9,
          error: 0xFFFFB4AB,
          onError: 0xFF690005,
          errorContainer: 0xFF93000A,
          onErrorContainer: 0xFFFFDAD6,
          surface: 0xFF1C1B1F,
          onSurface: 0xFFE6E1E5,
          surfaceContainerHighest: 0xFF49454F,
          onSurfaceVariant: 0xFFCAC4D0,
          outline: 0xFF938F99,
          outlineVariant: 0xFF49454F,
          shadow: 0xFF000000,
          scrim: 0xFF000000,
          inverseSurface: 0xFFE6E1E5,
          onInverseSurface: 0xFF313033,
          inversePrimary: seedColor.value,
          surfaceTintColor: seedColor.withAlpha(179).value,
        ),
      },
    ),
  );
}

/// 预设主题列表
class PresetThemes {
  /// 预设简单主题
  static final List<AppTheme> presets = [
    // 经典蓝色
    AppTheme(
      id: 'blue',
      name: '海洋蓝',
      seedColor: const Color(0xFF2196F3),
    ),
    // 绿色
    AppTheme(
      id: 'green',
      name: '森林绿',
      seedColor: const Color(0xFF4CAF50),
    ),
    // 紫色
    AppTheme(
      id: 'purple',
      name: '薰衣草紫',
      seedColor: const Color(0xFF9C27B0),
    ),
    // 橙色
    AppTheme(
      id: 'orange',
      name: '活力橙',
      seedColor: const Color(0xFFFF9800),
    ),
    // 红色
    AppTheme(
      id: 'red',
      name: '珊瑚红',
      seedColor: const Color(0xFFE91E63),
    ),
    // 青色
    AppTheme(
      id: 'teal',
      name: '青碧色',
      seedColor: const Color(0xFF009688),
    ),
    // 深蓝色
    AppTheme(
      id: 'indigo',
      name: '靛蓝',
      seedColor: const Color(0xFF3F51B5),
    ),
    // 粉色
    AppTheme(
      id: 'pink',
      name: '樱花粉',
      seedColor: const Color(0xFFFF4081),
    ),
    // 棕色
    AppTheme(
      id: 'brown',
      name: '咖啡棕',
      seedColor: const Color(0xFF795548),
    ),
    // 深青色
    AppTheme(
      id: 'cyan',
      name: '碧青色',
      seedColor: const Color(0xFF00BCD4),
    ),
  ];

  /// 预设专业版主题包
  static final List<ThemePackage> packages = [
    // 经典蓝色专业版
    ThemePackage(
      id: 'pro_blue',
      name: '专业蓝',
      author: 'ClassPlan',
      version: '1.0.0',
      description: '经典的蓝色主题，专业简洁',
      colors: ColorPackage(
        modes: {
          'light': ColorSchemeData(
            primary: 0xFF2196F3,
            onPrimary: 0xFFFFFFFF,
            primaryContainer: 0xFFBBDEFB,
            onPrimaryContainer: 0xFF001F3F,
            secondary: 0xFF03DAC6,
            onSecondary: 0xFF000000,
            secondaryContainer: 0xFFB2DFDB,
            onSecondaryContainer: 0xFF002020,
            tertiary: 0xFF9C27B0,
            onTertiary: 0xFFFFFFFF,
            tertiaryContainer: 0xFFE1BEE7,
            onTertiaryContainer: 0xFF310037,
            error: 0xFFB00020,
            onError: 0xFFFFFFFF,
            errorContainer: 0xFFFCD8DF,
            onErrorContainer: 0xFF410002,
            surface: 0xFFFFFFFF,
            onSurface: 0xFF1C1B1F,
            surfaceContainerHighest: 0xFFE7E0EC,
            onSurfaceVariant: 0xFF49454E,
            outline: 0xFF79747E,
            outlineVariant: 0xFFCAC4D0,
            shadow: 0xFF000000,
            scrim: 0xFF000000,
            inverseSurface: 0xFF313033,
            onInverseSurface: 0xFFF4EFF4,
            inversePrimary: 0xFF9ECAFF,
            surfaceTintColor: 0xFF2196F3,
          ),
          'dark': ColorSchemeData(
            primary: 0xFF9ECAFF,
            onPrimary: 0xFF003258,
            primaryContainer: 0xFF00497D,
            onPrimaryContainer: 0xFFD1E4FF,
            secondary: 0xFF03DAC6,
            onSecondary: 0xFF000000,
            secondaryContainer: 0xFF005048,
            onSecondaryContainer: 0xFF70F5E6,
            tertiary: 0xFFE6B3E0,
            onTertiary: 0xFF3D0050,
            tertiaryContainer: 0xFF560066,
            onTertiaryContainer: 0xFFFFD6F9,
            error: 0xFFFFB4AB,
            onError: 0xFF690005,
            errorContainer: 0xFF93000A,
            onErrorContainer: 0xFFFFDAD6,
            surface: 0xFF1C1B1F,
            onSurface: 0xFFE6E1E5,
            surfaceContainerHighest: 0xFF49454F,
            onSurfaceVariant: 0xFFCAC4D0,
            outline: 0xFF938F99,
            outlineVariant: 0xFF49454F,
            shadow: 0xFF000000,
            scrim: 0xFF000000,
            inverseSurface: 0xFFE6E1E5,
            onInverseSurface: 0xFF313033,
            inversePrimary: 0xFF0061A4,
            surfaceTintColor: 0xFF9ECAFF,
          ),
        },
      ),
      shapes: ShapePackage.defaults(),
      spacing: SpacingPackage.defaults(),
      components: ComponentPackage.defaults(),
    ),
    // 极光专业版
    ThemePackage(
      id: 'pro_aurora',
      name: '极光',
      author: 'ClassPlan',
      version: '1.0.0',
      description: '蓝绿渐变如北极光',
      colors: ColorPackage(
        modes: {
          'light': ColorSchemeData(
            primary: 0xFF00BCD4,
            onPrimary: 0xFFFFFFFF,
            primaryContainer: 0xFFB2EBF5,
            onPrimaryContainer: 0xFF002022,
            secondary: 0xFF009688,
            onSecondary: 0xFFFFFFFF,
            secondaryContainer: 0xFFB2DFDB,
            onSecondaryContainer: 0xFF002020,
            tertiary: 0xFF00ACC1,
            onTertiary: 0xFFFFFFFF,
            tertiaryContainer: 0xFFB3E5FC,
            onTertiaryContainer: 0xFF001F28,
            error: 0xFFB00020,
            onError: 0xFFFFFFFF,
            errorContainer: 0xFFFCD8DF,
            onErrorContainer: 0xFF410002,
            surface: 0xFFFAFAFA,
            onSurface: 0xFF1C1B1F,
            surfaceContainerHighest: 0xFFE0F7FA,
            onSurfaceVariant: 0xFF49454E,
            outline: 0xFF79747E,
            outlineVariant: 0xFFB2EBF5,
            shadow: 0xFF000000,
            scrim: 0xFF000000,
            inverseSurface: 0xFF313033,
            onInverseSurface: 0xFFF4EFF4,
            inversePrimary: 0xFF4DD0E1,
            surfaceTintColor: 0xFF00BCD4,
          ),
          'dark': ColorSchemeData(
            primary: 0xFF4DD0E1,
            onPrimary: 0xFF003640,
            primaryContainer: 0xFF004D5C,
            onPrimaryContainer: 0xFFB2EBF5,
            secondary: 0xFF80CBC4,
            onSecondary: 0xFF00332F,
            secondaryContainer: 0xFF00504A,
            onSecondaryContainer: 0xFFA7F3EC,
            tertiary: 0xFF4DD0E1,
            onTertiary: 0xFF003640,
            tertiaryContainer: 0xFF004D5C,
            onTertiaryContainer: 0xFFB2EBF5,
            error: 0xFFFFB4AB,
            onError: 0xFF690005,
            errorContainer: 0xFF93000A,
            onErrorContainer: 0xFFFFDAD6,
            surface: 0xFF1C1B1F,
            onSurface: 0xFFE6E1E5,
            surfaceContainerHighest: 0xFF006874,
            onSurfaceVariant: 0xFFCAC4D0,
            outline: 0xFF938F99,
            outlineVariant: 0xFF004D5C,
            shadow: 0xFF000000,
            scrim: 0xFF000000,
            inverseSurface: 0xFFE6E1E5,
            onInverseSurface: 0xFF313033,
            inversePrimary: 0xFF00838F,
            surfaceTintColor: 0xFF4DD0E1,
          ),
        },
      ),
    ),
    // 日落专业版
    ThemePackage(
      id: 'pro_sunset',
      name: '日落',
      author: 'ClassPlan',
      version: '1.0.0',
      description: '温暖的橙红渐变，适合夜间',
      colors: ColorPackage(
        modes: {
          'light': ColorSchemeData(
            primary: 0xFFFF7043,
            onPrimary: 0xFFFFFFFF,
            primaryContainer: 0xFFFFCCBC,
            onPrimaryContainer: 0xFF3E0400,
            secondary: 0xFFFFAB91,
            onSecondary: 0xFF442B2D,
            secondaryContainer: 0xFFFFDAD6,
            onSecondaryContainer: 0xFF5C4133,
            tertiary: 0xFFFF5722,
            onTertiary: 0xFFFFFFFF,
            tertiaryContainer: 0xFFFFDBD0,
            onTertiaryContainer: 0xFF3A0B00,
            error: 0xFFB00020,
            onError: 0xFFFFFFFF,
            errorContainer: 0xFFFCD8DF,
            onErrorContainer: 0xFF410002,
            surface: 0xFFFFFBFF,
            onSurface: 0xFF2D2D2D,
            surfaceContainerHighest: 0xFFFFE0B2,
            onSurfaceVariant: 0xFF49454E,
            outline: 0xFF79747E,
            outlineVariant: 0xFFFFCCBC,
            shadow: 0xFF000000,
            scrim: 0xFF000000,
            inverseSurface: 0xFF313033,
            onInverseSurface: 0xFFF4EFF4,
            inversePrimary: 0xFFFFB4A1,
            surfaceTintColor: 0xFFFF7043,
          ),
          'dark': ColorSchemeData(
            primary: 0xFFFFAB91,
            onPrimary: 0xFF5C1900,
            primaryContainer: 0xFF7F2D00,
            onPrimaryContainer: 0xFFFFDBD0,
            secondary: 0xFFFFCCBC,
            onSecondary: 0xFF442B2D,
            secondaryContainer: 0xFF5C4133,
            onSecondaryContainer: 0xFFFFDAD6,
            tertiary: 0xFFFF8A65,
            onTertiary: 0xFF4E1400,
            tertiaryContainer: 0xFF6E1F00,
            onTertiaryContainer: 0xFFFFDBD0,
            error: 0xFFFFB4AB,
            onError: 0xFF690005,
            errorContainer: 0xFF93000A,
            onErrorContainer: 0xFFFFDAD6,
            surface: 0xFF1C1B1F,
            onSurface: 0xFFE6E1E5,
            surfaceContainerHighest: 0xFFBF360C,
            onSurfaceVariant: 0xFFCAC4D0,
            outline: 0xFF938F99,
            outlineVariant: 0xFF7F2D00,
            shadow: 0xFF000000,
            scrim: 0xFF000000,
            inverseSurface: 0xFFE6E1E5,
            onInverseSurface: 0xFF313033,
            inversePrimary: 0xFFBF360C,
            surfaceTintColor: 0xFFFFAB91,
          ),
        },
      ),
    ),
  ];
}