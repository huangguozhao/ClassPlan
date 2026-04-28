import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';
import '../repository/local_course_repository.dart';

/// 桌面小组件数据服务
/// 将当天课程数据写入 SharedPreferences，供 Android Widget 读取
class WidgetDataService {
  static const String _widgetDataKey = 'widget_schedule_data';
  static const String _widgetUpdateTimeKey = 'widget_last_update';

  final LocalCourseRepository _repository;

  WidgetDataService(this._repository);

  /// 更新小组件数据
  Future<void> updateWidgetData() async {
    final prefs = await SharedPreferences.getInstance();

    // 获取当前学期
    final semester = await _repository.getCurrentSemester();
    if (semester == null) {
      // 没有设置学期，清空小组件数据
      await prefs.remove(_widgetDataKey);
      await prefs.remove(_widgetUpdateTimeKey);
      return;
    }

    // 计算今天是第几周
    final now = DateTime.now();
    final weekNumber = semester.weekNumberOf(now);

    // 获取今天周几
    final dayOfWeek = now.weekday; // 1=周一, 7=周日

    // 获取当前学期的所有课程
    final allCourses = await _repository.getCoursesBySemester(semester.id);

    // 筛选今天的课程（按周次和星期过滤）
    final todayCourses = allCourses.where((course) {
      // 检查是否是今天
      if (course.dayOfWeek != dayOfWeek) return false;
      // 检查周次
      return course.isActiveInWeek(weekNumber);
    }).toList();

    // 按节次排序
    todayCourses.sort((a, b) => a.startPeriod.compareTo(b.startPeriod));

    // 构建 Widget 数据
    final dayNames = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final dateFormat = '${now.month}月${now.day}日';

    final widgetData = _WidgetData(
      dateLabel: '${dayNames[dayOfWeek - 1]} $dateFormat',
      weekLabel: '第${weekNumber}周',
      courses: todayCourses.map((c) => _WidgetCourse(
        name: c.name,
        location: c.location,
        startPeriod: c.startPeriod,
        endPeriod: c.endPeriod,
        teacher: c.teacher,
        colorHex: c.colorHex,
      )).toList(),
      updatedAt: now.toIso8601String(),
    );

    // 写入 SharedPreferences
    await prefs.setString(_widgetDataKey, jsonEncode(widgetData.toJson()));
    await prefs.setString(_widgetUpdateTimeKey, now.toIso8601String());
  }

  /// 清除小组件数据
  Future<void> clearWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_widgetDataKey);
    await prefs.remove(_widgetUpdateTimeKey);
  }
}

/// 小组件数据结构
class _WidgetData {
  final String dateLabel;
  final String weekLabel;
  final List<_WidgetCourse> courses;
  final String updatedAt;

  _WidgetData({
    required this.dateLabel,
    required this.weekLabel,
    required this.courses,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'dateLabel': dateLabel,
    'weekLabel': weekLabel,
    'courses': courses.map((c) => c.toJson()).toList(),
    'updatedAt': updatedAt,
  };
}

/// 小组件课程数据
class _WidgetCourse {
  final String name;
  final String? location;
  final int startPeriod;
  final int endPeriod;
  final String? teacher;
  final String? colorHex;

  _WidgetCourse({
    required this.name,
    this.location,
    required this.startPeriod,
    required this.endPeriod,
    this.teacher,
    this.colorHex,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'startPeriod': startPeriod,
    'endPeriod': endPeriod,
    'teacher': teacher,
    'colorHex': colorHex,
  };
}