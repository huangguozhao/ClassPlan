import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'di/app_module.dart';
import 'presentation/home_screen.dart';
import 'data/widget/widget_data_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();

  // 启动时更新小组件数据
  _updateWidgetData();

  runApp(const ProviderScope(child: ClassPlanApp()));
}

/// 更新小组件数据
Future<void> _updateWidgetData() async {
  final widgetService = getIt<WidgetDataService>();
  await widgetService.updateWidgetData();
}

class ClassPlanApp extends StatelessWidget {
  const ClassPlanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '课表',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
