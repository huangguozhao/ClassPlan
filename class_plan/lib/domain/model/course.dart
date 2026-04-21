/// 课程领域模型
/// 代表一节课（一次课程事件）

class Course {
  final String id;
  final String name;            // 课程名，如"高等数学"
  final String? teacher;        // 教师名
  final String? location;       // 上课地点，如"教学楼A301"
  final int dayOfWeek;          // 星期几 (1=周一, 7=周日)
  final int startPeriod;        // 第几节课开始 (1-based)
  final int endPeriod;          // 第几节课结束
  final int? weekStart;         // 起始周（如1）
  final int? weekEnd;           // 结束周（如16）
  final List<int>? weeks;       // 具体周次列表（如[1,3,5]表示单周），若为null表示每周年年都有
  final String? colorHex;        // 课程颜色（用于UI区分）
  /// AI 解析返回的额外原始数据，用于课程详情展示
  final Map<String, dynamic>? extraData;

  Course({
    required this.id,
    required this.name,
    this.teacher,
    this.location,
    required this.dayOfWeek,
    required this.startPeriod,
    required this.endPeriod,
    this.weekStart,
    this.weekEnd,
    this.weeks,
    this.colorHex,
    this.extraData,
  });

  /// 获取该课程在指定周是否上课
  bool isActiveInWeek(int week) {
    if (weeks != null) {
      return weeks!.contains(week);
    }
    if (weekStart != null && weekEnd != null) {
      return week >= weekStart! && week <= weekEnd!;
    }
    return true; // 没有周次限制，默认每周年都有
  }

  /// 获取该课程的时间描述，如 "1-2节"
  String get periodDescription => '$startPeriod-$endPeriod节';

  /// 获取该课程的时长（多少节课）
  int get duration => endPeriod - startPeriod + 1;

  Course copyWith({
    String? id,
    String? name,
    String? teacher,
    String? location,
    int? dayOfWeek,
    int? startPeriod,
    int? endPeriod,
    int? weekStart,
    int? weekEnd,
    List<int>? weeks,
    String? colorHex,
    Map<String, dynamic>? extraData,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startPeriod: startPeriod ?? this.startPeriod,
      endPeriod: endPeriod ?? this.endPeriod,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      weeks: weeks ?? this.weeks,
      colorHex: colorHex ?? this.colorHex,
      extraData: extraData ?? this.extraData,
    );
  }
}
