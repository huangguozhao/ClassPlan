import 'package:flutter/material.dart';

/// 课程时间表配置
/// 用于配置每节课的开始时间和时长
class ClassSchedule {
  final List<PeriodTime> periods;
  final int breakDurationMinutes; // 课间休息时长（分钟）

  ClassSchedule({
    required this.periods,
    this.breakDurationMinutes = 10,
  });

  /// 获取指定节次的上课时间
  TimeOfDay? getPeriodStartTime(int period) {
    if (period < 1 || period > periods.length) return null;
    return periods[period - 1].startTime;
  }

  /// 获取指定节次的下课时间
  TimeOfDay? getPeriodEndTime(int period) {
    if (period < 1 || period > periods.length) return null;
    final p = periods[period - 1];
    final startMinutes = p.startTime.hour * 60 + p.startTime.minute;
    final endMinutes = startMinutes + p.durationMinutes;
    return TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
  }

  /// 估算指定节次的大致开始小时（用于提醒计算）
  int getPeriodStartHour(int period) {
    final time = getPeriodStartTime(period);
    return time?.hour ?? (8 + (period - 1));
  }

  Map<String, dynamic> toJson() {
    return {
      'periods': periods.map((p) => p.toJson()).toList(),
      'breakDurationMinutes': breakDurationMinutes,
    };
  }

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      periods: (json['periods'] as List<dynamic>)
          .map((p) => PeriodTime.fromJson(p as Map<String, dynamic>))
          .toList(),
      breakDurationMinutes: json['breakDurationMinutes'] as int? ?? 10,
    );
  }

  /// 默认课程表（高校常见作息）
  factory ClassSchedule.defaultSchedule() {
    return ClassSchedule(
      breakDurationMinutes: 10,
      periods: [
        PeriodTime(startTime: const TimeOfDay(hour: 8, minute: 0), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 8, minute: 55), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 9, minute: 50), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 10, minute: 45), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 11, minute: 40), durationMinutes: 45),
        // 午休
        PeriodTime(startTime: const TimeOfDay(hour: 14, minute: 0), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 14, minute: 55), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 15, minute: 50), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 16, minute: 45), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 17, minute: 40), durationMinutes: 45),
        // 晚上
        PeriodTime(startTime: const TimeOfDay(hour: 19, minute: 0), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 19, minute: 55), durationMinutes: 45),
        PeriodTime(startTime: const TimeOfDay(hour: 20, minute: 50), durationMinutes: 45),
      ],
    );
  }
}

/// 单节课的时间信息
class PeriodTime {
  final TimeOfDay startTime;
  final int durationMinutes;

  PeriodTime({
    required this.startTime,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'hour': startTime.hour,
      'minute': startTime.minute,
      'durationMinutes': durationMinutes,
    };
  }

  factory PeriodTime.fromJson(Map<String, dynamic> json) {
    return PeriodTime(
      startTime: TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      ),
      durationMinutes: json['durationMinutes'] as int,
    );
  }
}
