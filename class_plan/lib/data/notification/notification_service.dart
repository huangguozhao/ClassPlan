import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';
import '../../domain/model/class_schedule.dart';

/// 课程提醒通知服务
class ReminderService {
  static final ReminderService _instance = ReminderService._();
  factory ReminderService() => _instance;
  ReminderService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  ClassSchedule _classSchedule = ClassSchedule.defaultSchedule();

  /// 记录每个课程的通知 ID（用于精确取消）
  final _courseNotificationIds = <String, List<int>>{};

  static const _schedulePrefKey = 'class_schedule_config';

  /// 初始化通知服务
  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _loadClassSchedule();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    _initialized = true;
  }

  /// 加载课程时间表配置
  Future<void> _loadClassSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_schedulePrefKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _classSchedule = ClassSchedule.fromJson(json);
      } catch (_) {
        _classSchedule = ClassSchedule.defaultSchedule();
      }
    } else {
      _classSchedule = ClassSchedule.defaultSchedule();
    }
  }

  /// 请求通知权限（Android 13+）
  Future<bool> requestPermission() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// 为一门课程设置提醒
  Future<void> scheduleCourseReminder({
    required Course course,
    required Semester semester,
    required int minutesBefore, // 上课前多少分钟提醒
  }) async {
    await initialize();

    // 先取消该课程的旧提醒
    await cancelCourseReminders(course.id);

    // 获取课程开始时间
    final periodTime = _classSchedule.getPeriodStartTime(course.startPeriod);
    if (periodTime == null) return;

    // 计算下一次上课时间
    final now = DateTime.now();
    final currentWeek = semester.currentWeek() ?? 1;
    final ids = <int>[];

    for (int week = currentWeek; week <= semester.totalWeeks; week++) {
      if (!course.isActiveInWeek(week)) continue;

      final weekDate = semester.dateOfWeek(week);
      // dayOfWeek: 1=周一, 7=周日
      final courseDate = weekDate.add(Duration(days: course.dayOfWeek - 1));

      // 使用配置的上课时间
      final courseDateTime = DateTime(
        courseDate.year,
        courseDate.month,
        courseDate.day,
        periodTime.hour,
        periodTime.minute,
      );

      // 提醒时间
      final reminderTime = courseDateTime.subtract(Duration(minutes: minutesBefore));

      if (reminderTime.isBefore(now)) continue;

      final notificationId = '${course.id}_$week'.hashCode.abs();
      ids.add(notificationId);

      await _notifications.zonedSchedule(
        notificationId,
        '课前提醒',
        '${course.name} 将于 $minutesBefore 分钟后开始${course.location != null ? '（${course.location}）' : ''}',
        tz.TZDateTime.from(reminderTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'course_reminders',
            '课程提醒',
            channelDescription: '上课前提醒',
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(
              '${course.name}\n'
              '${course.location ?? '未知地点'}\n'
              '${course.teacher != null ? '教师：${course.teacher}' : ''}',
            ),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: null,
      );
    }

    _courseNotificationIds[course.id] = ids;
  }

  /// 取消一门课程的所有提醒（只取消该课程的，不影响其他）
  Future<void> cancelCourseReminders(String courseId) async {
    final ids = _courseNotificationIds[courseId];
    if (ids != null) {
      for (final id in ids) {
        await _notifications.cancel(id);
      }
      _courseNotificationIds.remove(courseId);
    }
  }

  /// 取消所有提醒
  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
    _courseNotificationIds.clear();
  }

  /// 重新加载课程时间表（供外部调用）
  Future<void> reloadClassSchedule() async {
    await _loadClassSchedule();
  }
}
