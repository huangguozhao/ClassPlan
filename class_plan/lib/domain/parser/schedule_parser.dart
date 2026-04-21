import '../model/raw_schedule_data.dart';
import '../model/structured_course.dart';

/// 课表解析器接口
/// 所有解析策略（规则解析/AI解析）都实现此接口
///
/// 新增解析方式只需：实现此接口 + 在 AppModule 注册

abstract class ScheduleParser {
  /// 解析器名称
  String get name;

  /// 解析优先级（数字越小优先级越高）
  int get priority;

  /// 解析原始数据为结构化课程列表
  /// 若返回空列表表示该解析器无法处理此数据
  Future<List<StructuredCourse>> parse(RawScheduleData raw);
}
