import 'package:get_it/get_it.dart';

import '../data/repository/course_repository.dart';
import '../data/repository/local_course_repository.dart';

final getIt = GetIt.instance;

/// 初始化依赖注入容器
Future<void> setupDependencies() async {
  // 统一使用同一个 LocalCourseRepository 实例
  final repository = LocalCourseRepository();
  getIt.registerLazySingleton<CourseRepository>(() => repository);
  getIt.registerLazySingleton<LocalCourseRepository>(() => repository);
}
