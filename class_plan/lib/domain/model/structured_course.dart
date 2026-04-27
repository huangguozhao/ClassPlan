import 'course.dart';

/// 结构化课程（解析后的中间格式）
/// 比 Course 更宽松，用于从不同解析器输出后统一转换为 Course

class StructuredCourse {
  final String name;
  final String? teacher;
  final String? location;
  final int? dayOfWeek;         // 1-7，若未知为null
  final int? startPeriod;       // 1-12，若未知为null
  final int? endPeriod;
  final int? weekStart;
  final int? weekEnd;
  final List<int>? weeks;
  final String? colorHex;
  /// AI 解析返回的额外原始数据，用于课程详情展示
  final Map<String, dynamic>? extraData;

  StructuredCourse({
    required this.name,
    this.teacher,
    this.location,
    this.dayOfWeek,
    this.startPeriod,
    this.endPeriod,
    this.weekStart,
    this.weekEnd,
    this.weeks,
    this.colorHex,
    this.extraData,
  });

  /// 转换为领域模型 Course
  Course toCourse(String id, String semesterId) {
    return Course(
      id: id,
      name: name,
      semesterId: semesterId,
      teacher: teacher,
      location: location,
      dayOfWeek: dayOfWeek ?? 1,
      startPeriod: startPeriod ?? 1,
      endPeriod: endPeriod ?? startPeriod ?? 1,
      weekStart: weekStart,
      weekEnd: weekEnd,
      weeks: weeks,
      colorHex: colorHex,
      extraData: extraData,
    );
  }
}
