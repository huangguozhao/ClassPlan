import 'course.dart';

/// 一周的课表
/// 按星期几分组的课程列表

class WeekSchedule {
  final int weekNumber;
  final DateTime weekStartDate;
  final Map<int, List<Course>> coursesByDay; // key=星期几(1-7)

  WeekSchedule({
    required this.weekNumber,
    required this.weekStartDate,
    required this.coursesByDay,
  });

  /// 获取某天的课程列表
  List<Course> coursesOnDay(int dayOfWeek) {
    return coursesByDay[dayOfWeek] ?? [];
  }

  /// 获取某天某节次的课程
  Course? courseAt(int dayOfWeek, int period) {
    final dayCourses = coursesOnDay(dayOfWeek);
    for (final course in dayCourses) {
      if (period >= course.startPeriod && period <= course.endPeriod) {
        return course;
      }
    }
    return null;
  }
}
