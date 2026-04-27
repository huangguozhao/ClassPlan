import 'package:get_it/get_it.dart';

import '../data/repository/course_repository.dart';
import '../data/repository/local_course_repository.dart';
import '../data/backup/backup_service.dart';

final getIt = GetIt.instance;

/// 初始化依赖注入容器
Future<void> setupDependencies() async {
  // Repository 层
  final repository = LocalCourseRepository();
  getIt.registerLazySingleton<CourseRepository>(() => repository);
  getIt.registerLazySingleton<LocalCourseRepository>(() => repository);

  // BackupService - 需要 Repository
  getIt.registerFactory<BackupService>(
    () => BackupService(getIt<LocalCourseRepository>()),
  );
}
