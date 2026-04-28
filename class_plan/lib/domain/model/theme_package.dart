import 'package:flutter/material.dart';

/// 完整主题包配置
/// 支持定制颜色、字体、形状、间距、所有组件样式
class ThemePackage {
  final String id;
  final String name;
  final String author;
  final String version;
  final String? description;
  final ColorPackage colors;
  final TypographyPackage? typography;
  final ShapePackage? shapes;
  final SpacingPackage? spacing;
  final ComponentPackage? components;
  final DateTime createdAt;

  ThemePackage({
    required this.id,
    required this.name,
    required this.author,
    required this.version,
    this.description,
    required this.colors,
    this.typography,
    this.shapes,
    this.spacing,
    this.components,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 从 JSON 创建
  factory ThemePackage.fromJson(Map<String, dynamic> json) => ThemePackage(
    id: json['id'],
    name: json['name'],
    author: json['author'] ?? '未知',
    version: json['version'] ?? '1.0.0',
    description: json['description'],
    colors: ColorPackage.fromJson(json['colors']),
    typography: json['typography'] != null
        ? TypographyPackage.fromJson(json['typography'])
        : null,
    shapes: json['shapes'] != null
        ? ShapePackage.fromJson(json['shapes'])
        : null,
    spacing: json['spacing'] != null
        ? SpacingPackage.fromJson(json['spacing'])
        : null,
    components: json['components'] != null
        ? ComponentPackage.fromJson(json['components'])
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.now(),
  );

  /// 转为 JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'author': author,
    'version': version,
    'description': description,
    'colors': colors.toJson(),
    'typography': typography?.toJson(),
    'shapes': shapes?.toJson(),
    'spacing': spacing?.toJson(),
    'components': components?.toJson(),
    'createdAt': createdAt.toIso8601String(),
  };

  /// 生成 Flutter ThemeData
  ThemeData toThemeData({Brightness brightness = Brightness.light}) {
    final colorScheme = colors.toColorScheme(brightness);
    final shapePkg = shapes ?? ShapePackage.defaults();
    final spacingPkg = spacing ?? SpacingPackage.defaults();
    final componentPkg = components ?? ComponentPackage.defaults();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,

      // Typography
      fontFamily: typography?.fontFamily,
      textTheme: typography?.toTextTheme(brightness),

      // Colors
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainerLow,

      // Shapes
      shapeRadius: shapePkg.mediumComponentRadius,
      cardTheme: CardTheme(
        elevation: componentPkg.card.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapePkg.mediumComponentRadius),
        ),
        margin: EdgeInsets.all(spacingPkg.sm),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        elevation: componentPkg.appBar.elevation,
        centerTitle: componentPkg.appBar.centerTitle,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: componentPkg.bottomNav.elevation,
        showSelectedLabels: componentPkg.bottomNav.showLabels,
        showUnselectedLabels: componentPkg.bottomNav.showLabels,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        elevation: componentPkg.navigationBar?.elevation ?? 0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            );
          }
          return TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: componentPkg.fab.elevation,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapePkg.largeComponentRadius),
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: componentPkg.button.elevation,
          padding: EdgeInsets.symmetric(
            horizontal: componentPkg.button.paddingHorizontal,
            vertical: componentPkg.button.paddingVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: componentPkg.button.paddingHorizontal,
            vertical: componentPkg.button.paddingVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
          ),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: componentPkg.button.paddingHorizontal,
            vertical: componentPkg.button.paddingVertical,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withAlpha(128),
        contentPadding: EdgeInsets.symmetric(
          horizontal: spacingPkg.md,
          vertical: spacingPkg.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
          borderSide: BorderSide(color: colorScheme.outline.withAlpha(77)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: TextStyle(fontSize: 14, color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
        ),
      ),

      // Dialog
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: componentPkg.dialog.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapePkg.largeComponentRadius),
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: componentPkg.bottomSheet.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(shapePkg.extraLargeRadius),
          ),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: spacingPkg.md,
      ),

      // List Tile
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: spacingPkg.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shapePkg.smallComponentRadius),
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // Checkbox
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Radio
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.surfaceContainerHighest,
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withAlpha(30),
      ),

      // Progress Indicators
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        circularTrackColor: colorScheme.surfaceContainerHighest,
        linearTrackColor: colorScheme.surfaceContainerHighest,
      ),

      // Tab Bar
      tabBarTheme: TabBarTheme(
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        dividerColor: Colors.transparent,
      ),

    );
  }

  /// 克隆
  ThemePackage copyWith({
    String? id,
    String? name,
    String? author,
    String? version,
    String? description,
    ColorPackage? colors,
    TypographyPackage? typography,
    ShapePackage? shapes,
    SpacingPackage? spacing,
    ComponentPackage? components,
  }) => ThemePackage(
    id: id ?? this.id,
    name: name ?? this.name,
    author: author ?? this.author,
    version: version ?? this.version,
    description: description ?? this.description,
    colors: colors ?? this.colors,
    typography: typography ?? this.typography,
    shapes: shapes ?? this.shapes,
    spacing: spacing ?? this.spacing,
    components: components ?? this.components,
    createdAt: createdAt,
  );
}

/// 颜色包
class ColorPackage {
  final Map<String, ColorSchemeData> modes;

  ColorPackage({required this.modes});

  factory ColorPackage.fromJson(Map<String, dynamic> json) {
    final modes = <String, ColorSchemeData>{};
    json.forEach((key, value) {
      if (value is Map) {
        modes[key] = ColorSchemeData.fromJson(value);
      }
    });
    return ColorPackage(modes: modes);
  }

  Map<String, dynamic> toJson() => modes.map((k, v) => MapEntry(k, v.toJson()));

  factory ColorPackage.light(Map<String, dynamic> lightColors) =>
      ColorPackage(modes: {'light': ColorSchemeData.fromJson(lightColors)});

  factory ColorPackage.defaultLight() => ColorPackage(modes: {
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
  });

  ColorScheme toColorScheme(Brightness brightness) {
    final mode = brightness == Brightness.light ? 'light' : 'dark';
    return modes[mode]?.toColorScheme() ?? ColorScheme.fromSeed(seedColor: Colors.blue);
  }
}

/// 单个颜色模式的配置
class ColorSchemeData {
  final int primary;
  final int onPrimary;
  final int primaryContainer;
  final int onPrimaryContainer;
  final int secondary;
  final int onSecondary;
  final int secondaryContainer;
  final int onSecondaryContainer;
  final int tertiary;
  final int onTertiary;
  final int tertiaryContainer;
  final int onTertiaryContainer;
  final int error;
  final int onError;
  final int errorContainer;
  final int onErrorContainer;
  final int surface;
  final int onSurface;
  final int surfaceContainerHighest;
  final int onSurfaceVariant;
  final int outline;
  final int outlineVariant;
  final int shadow;
  final int scrim;
  final int inverseSurface;
  final int onInverseSurface;
  final int inversePrimary;
  final int surfaceTintColor;

  ColorSchemeData({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.surface,
    required this.onSurface,
    required this.surfaceContainerHighest,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.onInverseSurface,
    required this.inversePrimary,
    required this.surfaceTintColor,
  });

  factory ColorSchemeData.fromJson(Map<String, dynamic> json) => ColorSchemeData(
    primary: json['primary'] ?? 0xFF2196F3,
    onPrimary: json['onPrimary'] ?? 0xFFFFFFFF,
    primaryContainer: json['primaryContainer'] ?? 0xFFBBDEFB,
    onPrimaryContainer: json['onPrimaryContainer'] ?? 0xFF001F3F,
    secondary: json['secondary'] ?? 0xFF03DAC6,
    onSecondary: json['onSecondary'] ?? 0xFF000000,
    secondaryContainer: json['secondaryContainer'] ?? 0xFFB2DFDB,
    onSecondaryContainer: json['onSecondaryContainer'] ?? 0xFF002020,
    tertiary: json['tertiary'] ?? 0xFF9C27B0,
    onTertiary: json['onTertiary'] ?? 0xFFFFFFFF,
    tertiaryContainer: json['tertiaryContainer'] ?? 0xFFE1BEE7,
    onTertiaryContainer: json['onTertiaryContainer'] ?? 0xFF310037,
    error: json['error'] ?? 0xFFB00020,
    onError: json['onError'] ?? 0xFFFFFFFF,
    errorContainer: json['errorContainer'] ?? 0xFFFCD8DF,
    onErrorContainer: json['onErrorContainer'] ?? 0xFF410002,
    surface: json['surface'] ?? 0xFFFFFFFF,
    onSurface: json['onSurface'] ?? 0xFF1C1B1F,
    surfaceContainerHighest: json['surfaceContainerHighest'] ?? 0xFFE7E0EC,
    onSurfaceVariant: json['onSurfaceVariant'] ?? 0xFF49454E,
    outline: json['outline'] ?? 0xFF79747E,
    outlineVariant: json['outlineVariant'] ?? 0xFFCAC4D0,
    shadow: json['shadow'] ?? 0xFF000000,
    scrim: json['scrim'] ?? 0xFF000000,
    inverseSurface: json['inverseSurface'] ?? 0xFF313033,
    onInverseSurface: json['onInverseSurface'] ?? 0xFFF4EFF4,
    inversePrimary: json['inversePrimary'] ?? 0xFF9ECAFF,
    surfaceTintColor: json['surfaceTintColor'] ?? 0xFF2196F3,
  );

  Map<String, dynamic> toJson() => {
    'primary': primary,
    'onPrimary': onPrimary,
    'primaryContainer': primaryContainer,
    'onPrimaryContainer': onPrimaryContainer,
    'secondary': secondary,
    'onSecondary': onSecondary,
    'secondaryContainer': secondaryContainer,
    'onSecondaryContainer': onSecondaryContainer,
    'tertiary': tertiary,
    'onTertiary': onTertiary,
    'tertiaryContainer': tertiaryContainer,
    'onTertiaryContainer': onTertiaryContainer,
    'error': error,
    'onError': onError,
    'errorContainer': errorContainer,
    'onErrorContainer': onErrorContainer,
    'surface': surface,
    'onSurface': onSurface,
    'surfaceContainerHighest': surfaceContainerHighest,
    'onSurfaceVariant': onSurfaceVariant,
    'outline': outline,
    'outlineVariant': outlineVariant,
    'shadow': shadow,
    'scrim': scrim,
    'inverseSurface': inverseSurface,
    'onInverseSurface': onInverseSurface,
    'inversePrimary': inversePrimary,
    'surfaceTintColor': surfaceTintColor,
  };

  ColorScheme toColorScheme() => ColorScheme(
    primary: Color(primary),
    onPrimary: Color(onPrimary),
    primaryContainer: Color(primaryContainer),
    onPrimaryContainer: Color(onPrimaryContainer),
    secondary: Color(secondary),
    onSecondary: Color(onSecondary),
    secondaryContainer: Color(secondaryContainer),
    onSecondaryContainer: Color(onSecondaryContainer),
    tertiary: Color(tertiary),
    onTertiary: Color(onTertiary),
    tertiaryContainer: Color(tertiaryContainer),
    onTertiaryContainer: Color(onTertiaryContainer),
    error: Color(error),
    onError: Color(onError),
    errorContainer: Color(errorContainer),
    onErrorContainer: Color(onErrorContainer),
    surface: Color(surface),
    onSurface: Color(onSurface),
    surfaceContainerHighest: Color(surfaceContainerHighest),
    onSurfaceVariant: Color(onSurfaceVariant),
    outline: Color(outline),
    outlineVariant: Color(outlineVariant),
    shadow: Color(shadow),
    scrim: Color(scrim),
    inverseSurface: Color(inverseSurface),
    onInverseSurface: Color(onInverseSurface),
    inversePrimary: Color(inversePrimary),
    surfaceTintColor: Color(surfaceTintColor),
  );
}

/// 字体排版包
class TypographyPackage {
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final Map<String, TextStyleData>? textStyles;

  TypographyPackage({this.fontFamily, this.fontFamilyFallback, this.textStyles});

  factory TypographyPackage.fromJson(Map<String, dynamic> json) {
    final textStyles = <String, TextStyleData>{};
    if (json['textStyles'] != null) {
      (json['textStyles'] as Map).forEach((key, value) {
        textStyles[key] = TextStyleData.fromJson(value);
      });
    }
    return TypographyPackage(
      fontFamily: json['fontFamily'],
      fontFamilyFallback: json['fontFamilyFallback'] != null
          ? List<String>.from(json['fontFamilyFallback'])
          : null,
      textStyles: textStyles.isNotEmpty ? textStyles : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'fontFamily': fontFamily,
    'fontFamilyFallback': fontFamilyFallback,
    'textStyles': textStyles?.map((k, v) => MapEntry(k, v.toJson())),
  };

  TextTheme toTextTheme(Brightness brightness) {
    final baseTheme = Typography.materialType(brightness);
    final family = fontFamily;
    final styles = textStyles ?? {};

    return TextTheme(
      displayLarge: _applyStyle(baseTheme.displayLarge, styles['displayLarge'], family),
      displayMedium: _applyStyle(baseTheme.displayMedium, styles['displayMedium'], family),
      displaySmall: _applyStyle(baseTheme.displaySmall, styles['displaySmall'], family),
      headlineLarge: _applyStyle(baseTheme.headlineLarge, styles['headlineLarge'], family),
      headlineMedium: _applyStyle(baseTheme.headlineMedium, styles['headlineMedium'], family),
      headlineSmall: _applyStyle(baseTheme.headlineSmall, styles['headlineSmall'], family),
      titleLarge: _applyStyle(baseTheme.titleLarge, styles['titleLarge'], family),
      titleMedium: _applyStyle(baseTheme.titleMedium, styles['titleMedium'], family),
      titleSmall: _applyStyle(baseTheme.titleSmall, styles['titleSmall'], family),
      bodyLarge: _applyStyle(baseTheme.bodyLarge, styles['bodyLarge'], family),
      bodyMedium: _applyStyle(baseTheme.bodyMedium, styles['bodyMedium'], family),
      bodySmall: _applyStyle(baseTheme.bodySmall, styles['bodySmall'], family),
      labelLarge: _applyStyle(baseTheme.labelLarge, styles['labelLarge'], family),
      labelMedium: _applyStyle(baseTheme.labelMedium, styles['labelMedium'], family),
      labelSmall: _applyStyle(baseTheme.labelSmall, styles['labelSmall'], family),
    );
  }

  TextStyle _applyStyle(TextStyle base, TextStyleData? style, String? family) {
    if (style == null) {
      return family != null ? base.copyWith(fontFamily: family) : base;
    }
    return base.copyWith(
      fontFamily: family,
      fontSize: style.size ?? base.fontSize,
      fontWeight: style.weight != null ? FontWeight.values[style.weight!] : base.fontWeight,
      letterSpacing: style.letterSpacing,
      height: style.height,
    );
  }
}

/// 文本样式配置
class TextStyleData {
  final double? size;
  final int? weight;
  final double? letterSpacing;
  final double? height;

  TextStyleData({this.size, this.weight, this.letterSpacing, this.height});

  factory TextStyleData.fromJson(Map<String, dynamic> json) => TextStyleData(
    size: (json['size'] as num?)?.toDouble(),
    weight: json['weight'] as int?,
    letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
    height: (json['height'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'size': size,
    'weight': weight,
    'letterSpacing': letterSpacing,
    'height': height,
  };
}

/// 形状系统包
class ShapePackage {
  final double smallComponentRadius;
  final double mediumComponentRadius;
  final double largeComponentRadius;
  final double extraLargeRadius;

  ShapePackage({
    required this.smallComponentRadius,
    required this.mediumComponentRadius,
    required this.largeComponentRadius,
    required this.extraLargeRadius,
  });

  factory ShapePackage.fromJson(Map<String, dynamic> json) => ShapePackage(
    smallComponentRadius: (json['smallComponentRadius'] as num?)?.toDouble() ?? 8.0,
    mediumComponentRadius: (json['mediumComponentRadius'] as num?)?.toDouble() ?? 12.0,
    largeComponentRadius: (json['largeComponentRadius'] as num?)?.toDouble() ?? 16.0,
    extraLargeRadius: (json['extraLargeRadius'] as num?)?.toDouble() ?? 24.0,
  );

  Map<String, dynamic> toJson() => {
    'smallComponentRadius': smallComponentRadius,
    'mediumComponentRadius': mediumComponentRadius,
    'largeComponentRadius': largeComponentRadius,
    'extraLargeRadius': extraLargeRadius,
  };

  factory ShapePackage.defaults() => ShapePackage(
    smallComponentRadius: 8.0,
    mediumComponentRadius: 12.0,
    largeComponentRadius: 16.0,
    extraLargeRadius: 24.0,
  );
}

/// 间距系统包
class SpacingPackage {
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double xxl;

  SpacingPackage({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.xxl,
  });

  factory SpacingPackage.fromJson(Map<String, dynamic> json) => SpacingPackage(
    xs: (json['xs'] as num?)?.toDouble() ?? 4.0,
    sm: (json['sm'] as num?)?.toDouble() ?? 8.0,
    md: (json['md'] as num?)?.toDouble() ?? 16.0,
    lg: (json['lg'] as num?)?.toDouble() ?? 24.0,
    xl: (json['xl'] as num?)?.toDouble() ?? 32.0,
    xxl: (json['xxl'] as num?)?.toDouble() ?? 48.0,
  );

  Map<String, dynamic> toJson() => {
    'xs': xs,
    'sm': sm,
    'md': md,
    'lg': lg,
    'xl': xl,
    'xxl': xxl,
  };

  factory SpacingPackage.defaults() => SpacingPackage(
    xs: 4.0,
    sm: 8.0,
    md: 16.0,
    lg: 24.0,
    xl: 32.0,
    xxl: 48.0,
  );
}

/// 组件样式包
class ComponentPackage {
  final AppBarComponentStyle appBar;
  final CardComponentStyle card;
  final ButtonComponentStyle button;
  final FabComponentStyle fab;
  final BottomNavComponentStyle bottomNav;
  final NavigationBarComponentStyle? navigationBar;
  final DialogComponentStyle dialog;
  final BottomSheetComponentStyle bottomSheet;

  ComponentPackage({
    required this.appBar,
    required this.card,
    required this.button,
    required this.fab,
    required this.bottomNav,
    this.navigationBar,
    required this.dialog,
    required this.bottomSheet,
  });

  factory ComponentPackage.fromJson(Map<String, dynamic> json) => ComponentPackage(
    appBar: json['appBar'] != null
        ? AppBarComponentStyle.fromJson(json['appBar'])
        : AppBarComponentStyle.defaults(),
    card: json['card'] != null
        ? CardComponentStyle.fromJson(json['card'])
        : CardComponentStyle.defaults(),
    button: json['button'] != null
        ? ButtonComponentStyle.fromJson(json['button'])
        : ButtonComponentStyle.defaults(),
    fab: json['fab'] != null
        ? FabComponentStyle.fromJson(json['fab'])
        : FabComponentStyle.defaults(),
    bottomNav: json['bottomNav'] != null
        ? BottomNavComponentStyle.fromJson(json['bottomNav'])
        : BottomNavComponentStyle.defaults(),
    navigationBar: json['navigationBar'] != null
        ? NavigationBarComponentStyle.fromJson(json['navigationBar'])
        : null,
    dialog: json['dialog'] != null
        ? DialogComponentStyle.fromJson(json['dialog'])
        : DialogComponentStyle.defaults(),
    bottomSheet: json['bottomSheet'] != null
        ? BottomSheetComponentStyle.fromJson(json['bottomSheet'])
        : BottomSheetComponentStyle.defaults(),
  );

  Map<String, dynamic> toJson() => {
    'appBar': appBar.toJson(),
    'card': card.toJson(),
    'button': button.toJson(),
    'fab': fab.toJson(),
    'bottomNav': bottomNav.toJson(),
    'navigationBar': navigationBar?.toJson(),
    'dialog': dialog.toJson(),
    'bottomSheet': bottomSheet.toJson(),
  };

  factory ComponentPackage.defaults() => ComponentPackage(
    appBar: AppBarComponentStyle.defaults(),
    card: CardComponentStyle.defaults(),
    button: ButtonComponentStyle.defaults(),
    fab: FabComponentStyle.defaults(),
    bottomNav: BottomNavComponentStyle.defaults(),
    navigationBar: NavigationBarComponentStyle.defaults(),
    dialog: DialogComponentStyle.defaults(),
    bottomSheet: BottomSheetComponentStyle.defaults(),
  );
}

class AppBarComponentStyle {
  final double elevation;
  final bool centerTitle;

  AppBarComponentStyle({required this.elevation, required this.centerTitle});

  factory AppBarComponentStyle.fromJson(Map<String, dynamic> json) =>
      AppBarComponentStyle(
        elevation: (json['elevation'] as num?)?.toDouble() ?? 0.0,
        centerTitle: json['centerTitle'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {'elevation': elevation, 'centerTitle': centerTitle};

  factory AppBarComponentStyle.defaults() =>
      AppBarComponentStyle(elevation: 0.0, centerTitle: true);
}

class CardComponentStyle {
  final double elevation;
  final double padding;

  CardComponentStyle({required this.elevation, required this.padding});

  factory CardComponentStyle.fromJson(Map<String, dynamic> json) =>
      CardComponentStyle(
        elevation: (json['elevation'] as num?)?.toDouble() ?? 1.0,
        padding: (json['padding'] as num?)?.toDouble() ?? 16.0,
      );

  Map<String, dynamic> toJson() => {'elevation': elevation, 'padding': padding};

  factory CardComponentStyle.defaults() => CardComponentStyle(elevation: 1.0, padding: 16.0);
}

class ButtonComponentStyle {
  final double elevation;
  final double paddingHorizontal;
  final double paddingVertical;

  ButtonComponentStyle({
    required this.elevation,
    required this.paddingHorizontal,
    required this.paddingVertical,
  });

  factory ButtonComponentStyle.fromJson(Map<String, dynamic> json) =>
      ButtonComponentStyle(
        elevation: (json['elevation'] as num?)?.toDouble() ?? 2.0,
        paddingHorizontal: (json['paddingHorizontal'] as num?)?.toDouble() ?? 24.0,
        paddingVertical: (json['paddingVertical'] as num?)?.toDouble() ?? 12.0,
      );

  Map<String, dynamic> toJson() => {
    'elevation': elevation,
    'paddingHorizontal': paddingHorizontal,
    'paddingVertical': paddingVertical,
  };

  factory ButtonComponentStyle.defaults() => ButtonComponentStyle(
    elevation: 2.0,
    paddingHorizontal: 24.0,
    paddingVertical: 12.0,
  );
}

class FabComponentStyle {
  final double elevation;

  FabComponentStyle({required this.elevation});

  factory FabComponentStyle.fromJson(Map<String, dynamic> json) =>
      FabComponentStyle(elevation: (json['elevation'] as num?)?.toDouble() ?? 6.0);

  Map<String, dynamic> toJson() => {'elevation': elevation};

  factory FabComponentStyle.defaults() => FabComponentStyle(elevation: 6.0);
}

class BottomNavComponentStyle {
  final double elevation;
  final bool showLabels;

  BottomNavComponentStyle({required this.elevation, required this.showLabels});

  factory BottomNavComponentStyle.fromJson(Map<String, dynamic> json) =>
      BottomNavComponentStyle(
        elevation: (json['elevation'] as num?)?.toDouble() ?? 8.0,
        showLabels: json['showLabels'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {'elevation': elevation, 'showLabels': showLabels};

  factory BottomNavComponentStyle.defaults() =>
      BottomNavComponentStyle(elevation: 8.0, showLabels: true);
}

class NavigationBarComponentStyle {
  final double elevation;

  NavigationBarComponentStyle({required this.elevation});

  factory NavigationBarComponentStyle.fromJson(Map<String, dynamic> json) =>
      NavigationBarComponentStyle(
        elevation: (json['elevation'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toJson() => {'elevation': elevation};

  factory NavigationBarComponentStyle.defaults() =>
      NavigationBarComponentStyle(elevation: 0.0);
}

class DialogComponentStyle {
  final double elevation;

  DialogComponentStyle({required this.elevation});

  factory DialogComponentStyle.fromJson(Map<String, dynamic> json) =>
      DialogComponentStyle(elevation: (json['elevation'] as num?)?.toDouble() ?? 3.0);

  Map<String, dynamic> toJson() => {'elevation': elevation};

  factory DialogComponentStyle.defaults() => DialogComponentStyle(elevation: 3.0);
}

class BottomSheetComponentStyle {
  final double elevation;

  BottomSheetComponentStyle({required this.elevation});

  factory BottomSheetComponentStyle.fromJson(Map<String, dynamic> json) =>
      BottomSheetComponentStyle(
        elevation: (json['elevation'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toJson() => {'elevation': elevation};

  factory BottomSheetComponentStyle.defaults() =>
      BottomSheetComponentStyle(elevation: 1.0);
}