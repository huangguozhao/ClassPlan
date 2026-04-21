import '../../domain/model/raw_schedule_data.dart';

/// 课表导入器接口
/// 所有导入方式（PDF/图片/手动）都实现此接口
///
/// 新增导入方式只需：实现此接口 + 在 AppModule 注册

abstract class CourseImporter {
  /// 导入器名称（如"PDF文件"、"图片OCR"）
  String get name;

  /// 从源文件/数据导入原始课表
  Future<RawScheduleData> import(String sourcePath);
}
