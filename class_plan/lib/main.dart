import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'di/app_module.dart';
import 'presentation/home_screen.dart';
import 'data/widget/widget_data_service.dart';
import 'data/theme/theme_service.dart';
import 'domain/model/app_theme.dart';
import 'domain/model/theme_package.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();

  // 初始化主题服务
  final themeService = ThemeService();
  await themeService.initialize();

  // 启动时更新小组件数据
  _updateWidgetData();

  runApp(ProviderScope(
    child: ClassPlanApp(themeService: themeService),
  ));
}

/// 更新小组件数据
Future<void> _updateWidgetData() async {
  final widgetService = getIt<WidgetDataService>();
  await widgetService.updateWidgetData();
}

/// 当前主题包 Provider（支持专业版主题包）
final themePackageProvider = StateNotifierProvider<ThemePackageNotifier, ThemePackage?>((ref) {
  return ThemePackageNotifier();
});

class ThemePackageNotifier extends StateNotifier<ThemePackage?> {
  ThemePackageNotifier() : super(null) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final service = ThemeService();
    final package = await service.getCurrentThemePackage();
    state = package;
  }

  Future<void> setThemePackage(ThemePackage package) async {
    final service = ThemeService();
    await service.setCurrentThemePackage(package);
    state = package;
  }

  Future<void> refresh() async {
    await _loadTheme();
  }
}

class ClassPlanApp extends ConsumerStatefulWidget {
  final ThemeService themeService;

  const ClassPlanApp({super.key, required this.themeService});

  @override
  ConsumerState<ClassPlanApp> createState() => _ClassPlanAppState();
}

class _ClassPlanAppState extends ConsumerState<ClassPlanApp> {
  @override
  void initState() {
    super.initState();
    // 初始化主题
    _initTheme();
  }

  Future<void> _initTheme() async {
    final package = await widget.themeService.getCurrentThemePackage();
    if (package != null) {
      ref.read(themePackageProvider.notifier).state = package;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themePackage = ref.watch(themePackageProvider);

    // 如果有专业版主题包，使用它生成完整主题
    // 否则使用默认的蓝色主题
    final lightTheme = themePackage?.toThemeData(brightness: Brightness.light) ??
        ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          brightness: Brightness.light,
        );

    final darkTheme = themePackage?.toThemeData(brightness: Brightness.dark) ??
        ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
          useMaterial3: true,
          brightness: Brightness.dark,
        );

    return MaterialApp(
      title: '课表',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}