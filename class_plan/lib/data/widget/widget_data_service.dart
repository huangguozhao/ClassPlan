import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';
import '../../domain/model/class_schedule.dart';
import '../repository/local_course_repository.dart';

/// 桌面小组件数据服务
/// 将当天课程数据写入 SharedPreferences，供 Android Widget 读取
class WidgetDataService {
  static const String _widgetDataKey = 'flutter.widget_schedule_data';
  static const String _widgetUpdateTimeKey = 'flutter.widget_last_update';

  final LocalCourseRepository _repository;

  WidgetDataService(this._repository);

  /// 更新小组件数据
  Future<void> updateWidgetData() async {
    final prefs = await SharedPreferences.getInstance();

    // 获取当前学期
    final semester = await _repository.getCurrentSemester();
    if (semester == null) {
      await prefs.remove(_widgetDataKey);
      await prefs.remove(_widgetUpdateTimeKey);
      return;
    }

    // 计算今天是第几周
    final now = DateTime.now();
    final weekNumber = semester.weekNumberOf(now);
    final dayOfWeek = now.weekday;

    // 获取当前学期的所有课程
    final allCourses = await _repository.getCoursesBySemester(semester.id);

    // 筛选今天的课程
    final todayCourses = allCourses.where((course) {
      if (course.dayOfWeek != dayOfWeek) return false;
      return course.isActiveInWeek(weekNumber);
    }).toList();

    // 按节次排序
    todayCourses.sort((a, b) => a.startPeriod.compareTo(b.startPeriod));

    // 获取课程作息时间
    final classSchedule = await _getClassSchedule();

    // 计算下一节课信息
    final nextCourseInfo = _calculateNextCourse(todayCourses, now, classSchedule);

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
      nextCourse: nextCourseInfo,
      updatedAt: now.toIso8601String(),
    );

    await prefs.setString(_widgetDataKey, jsonEncode(widgetData.toJson()));
    await prefs.setString(_widgetUpdateTimeKey, now.toIso8601String());
  }

  /// 获取课程作息时间
  Future<ClassSchedule> _getClassSchedule() async {
    // 尝试从 SharedPreferences 加载自定义作息时间
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('class_schedule_config');
    if (json != null) {
      try {
        return ClassSchedule.fromJson(jsonDecode(json));
      } catch (_) {}
    }
    return ClassSchedule.defaultSchedule();
  }

  /// 计算下一节课信息
  _NextCourseInfo? _calculateNextCourse(
    List<Course> todayCourses,
    DateTime now,
    ClassSchedule classSchedule,
  ) {
    if (todayCourses.isEmpty) return null;

    // 找到当前时间之后的第一节课
    Course? nextCourse;
    int? minutesUntilStart;

    for (final course in todayCourses) {
      // 计算这门课的开始时间
      final periodTime = classSchedule.getPeriodStartTime(course.startPeriod);
      if (periodTime == null) continue;

      // 计算今天这节课的实际开始时间
      final courseStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        periodTime.hour,
        periodTime.minute,
      );

      // 如果课程还没开始
      if (courseStartTime.isAfter(now)) {
        nextCourse = course;
        minutesUntilStart = courseStartTime.difference(now).inMinutes;
        break;
      }
    }

    if (nextCourse == null) {
      // 今天所有课程都已结束
      return _NextCourseInfo(
        name: nextCourse?.name ?? '今日课程已结束',
        location: nextCourse?.location,
        startPeriod: nextCourse?.startPeriod ?? 0,
        endPeriod: nextCourse?.endPeriod ?? 0,
        minutesUntilStart: -1, // -1 表示今天没有下一节课了
        status: '今日课程已结束',
      );
    }

    // 确定状态文案
    String status;
    if (minutesUntilStart! <= 5) {
      status = '即将开始';
    } else if (minutesUntilStart <= 30) {
      status = '${minutesUntilStart}分钟后';
    } else {
      status = '${minutesUntilStart}分钟后';
    }

    return _NextCourseInfo(
      name: nextCourse.name,
      location: nextCourse.location,
      startPeriod: nextCourse.startPeriod,
      endPeriod: nextCourse.endPeriod,
      minutesUntilStart: minutesUntilStart,
      status: status,
    );
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
  final _NextCourseInfo? nextCourse;
  final String updatedAt;

  _WidgetData({
    required this.dateLabel,
    required this.weekLabel,
    required this.courses,
    this.nextCourse,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'dateLabel': dateLabel,
    'weekLabel': weekLabel,
    'courses': courses.map((c) => c.toJson()).toList(),
    'nextCourse': nextCourse?.toJson(),
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

/// 下一节课信息
class _NextCourseInfo {
  final String name;
  final String? location;
  final int startPeriod;
  final int endPeriod;
  final int minutesUntilStart;
  final String status;

  _NextCourseInfo({
    required this.name,
    this.location,
    required this.startPeriod,
    required this.endPeriod,
    required this.minutesUntilStart,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'location': location,
    'startPeriod': startPeriod,
    'endPeriod': endPeriod,
    'minutesUntilStart': minutesUntilStart,
    'status': status,
  };
}