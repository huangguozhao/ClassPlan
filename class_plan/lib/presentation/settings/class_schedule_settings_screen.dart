import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/model/class_schedule.dart';

/// 课程时间表设置页面
/// 允许用户配置每节课的开始时间和时长
class ClassScheduleSettingsScreen extends StatefulWidget {
  const ClassScheduleSettingsScreen({super.key});

  @override
  State<ClassScheduleSettingsScreen> createState() => _ClassScheduleSettingsScreenState();
}

class _ClassScheduleSettingsScreenState extends State<ClassScheduleSettingsScreen> {
  late ClassSchedule _schedule;
  bool _isLoading = true;

  static const _prefKey = 'class_schedule_config';

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_prefKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _schedule = ClassSchedule.fromJson(json);
      } catch (_) {
        _schedule = ClassSchedule.defaultSchedule();
      }
    } else {
      _schedule = ClassSchedule.defaultSchedule();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(_schedule.toJson());
    await prefs.setString(_prefKey, jsonStr);
  }

  Future<void> _selectTime(int periodIndex) async {
    final period = _schedule.periods[periodIndex];
    final time = await showTimePicker(
      context: context,
      initialTime: period.startTime,
    );

    if (time != null) {
      setState(() {
        _schedule = ClassSchedule(
          periods: List.from(_schedule.periods),
          breakDurationMinutes: _schedule.breakDurationMinutes,
        );
        _schedule.periods[periodIndex] = PeriodTime(
          startTime: time,
          durationMinutes: period.durationMinutes,
        );
      });
    }
  }

  Future<void> _setDuration(int periodIndex, int duration) async {
    setState(() {
      _schedule = ClassSchedule(
        periods: List.from(_schedule.periods),
        breakDurationMinutes: _schedule.breakDurationMinutes,
      );
      _schedule.periods[periodIndex] = PeriodTime(
        startTime: _schedule.periods[periodIndex].startTime,
        durationMinutes: duration,
      );
    });
  }

  void _resetToDefault() {
    setState(() {
      _schedule = ClassSchedule.defaultSchedule();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程时间表设置'),
        actions: [
          TextButton(
            onPressed: _resetToDefault,
            child: const Text('重置'),
          ),
          TextButton(
            onPressed: () async {
              await _saveSchedule();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('时间表已保存')),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '设置每节课的开始时间和时长，用于计算准确的提醒时间',
                          style: TextStyle(color: Colors.blue.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '节次时间表',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...List.generate(_schedule.periods.length, (index) {
                  final period = _schedule.periods[index];
                  return _PeriodCard(
                    periodNumber: index + 1,
                    period: period,
                    onTimeTap: () => _selectTime(index),
                    onDurationChanged: (d) => _setDuration(index, d),
                  );
                }),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text(
                      '课间休息时长',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    DropdownButton<int>(
                      value: _schedule.breakDurationMinutes,
                      items: [5, 10, 15, 20, 30].map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text('$d 分钟'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _schedule = ClassSchedule(
                              periods: _schedule.periods,
                              breakDurationMinutes: v,
                            );
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  final int periodNumber;
  final PeriodTime period;
  final VoidCallback onTimeTap;
  final ValueChanged<int> onDurationChanged;

  const _PeriodCard({
    required this.periodNumber,
    required this.period,
    required this.onTimeTap,
    required this.onDurationChanged,
  });

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final startMinutes = period.startTime.hour * 60 + period.startTime.minute;
    final endMinutes = startMinutes + period.durationMinutes;
    final endTime = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$periodNumber',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onTimeTap,
                    child: Row(
                      children: [
                        Text(
                          '${_formatTime(period.startTime)} - ${_formatTime(endTime)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.edit, size: 16, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '课程时长: ${period.durationMinutes} 分钟',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            DropdownButton<int>(
              value: period.durationMinutes,
              items: [30, 35, 40, 45, 50, 55, 60].map((d) {
                return DropdownMenuItem(
                  value: d,
                  child: Text('$d 分钟'),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) onDurationChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
