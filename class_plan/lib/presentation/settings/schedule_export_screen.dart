import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../di/app_module.dart';
import '../../data/repository/local_course_repository.dart';
import '../../data/export/schedule_export_service.dart';
import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';

/// 课表导出页面
class ScheduleExportScreen extends ConsumerStatefulWidget {
  const ScheduleExportScreen({super.key});

  @override
  ConsumerState<ScheduleExportScreen> createState() => _ScheduleExportScreenState();
}

class _ScheduleExportScreenState extends ConsumerState<ScheduleExportScreen> {
  final GlobalKey _repaintKey = GlobalKey();
  bool _isExporting = false;

  Semester? _semester;
  Map<int, List<Course>> _coursesByDay = {};
  int _currentWeek = 1;
  int _totalWeeks = 20;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = getIt<LocalCourseRepository>();
    final semester = await repo.getCurrentSemester();
    if (semester != null) {
      final week = semester.currentWeek() ?? 1;
      final schedule = await repo.getWeekSchedule(week, semester);
      setState(() {
        _semester = semester;
        _coursesByDay = schedule.coursesByDay;
        _currentWeek = week;
        _totalWeeks = semester.totalWeeks;
      });
    }
  }

  Future<void> _exportAndShare() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final service = ScheduleExportService();
      final fileName = '课表_${_semester?.name ?? 'default'}_第${_currentWeek}周';
      final filePath = await service.exportToImage(
        repaintKey: _repaintKey,
        fileName: fileName,
      );

      if (filePath != null && mounted) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: '我的课表 - ${_semester?.name ?? ''} 第${_currentWeek}周',
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败，请重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导出课表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isExporting ? null : _exportAndShare,
          ),
        ],
      ),
      body: _semester == null
          ? const Center(child: Text('请先设置学期并导入课程'))
          : Column(
              children: [
                // 预览区
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: RepaintBoundary(
                      key: _repaintKey,
                      child: ScheduleExportService.buildScheduleWidget(
                        coursesByDay: _coursesByDay,
                        totalWeeks: _totalWeeks,
                        semesterName: '${_semester!.name} 第$_currentWeek周',
                      ),
                    ),
                  ),
                ),
                // 底部操作栏
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // 周次选择
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showWeekPicker(),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text('第 $_currentWeek 周'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 分享按钮
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _isExporting ? null : _exportAndShare,
                            icon: _isExporting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.share, size: 18),
                            label: Text(_isExporting ? '导出中...' : '分享图片'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showWeekPicker() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择周次', style: TextStyle(fontSize: 18)),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _totalWeeks,
                itemBuilder: (context, index) {
                  final week = index + 1;
                  return ListTile(
                    title: Text('第 $week 周'),
                    trailing: week == _currentWeek
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => Navigator.pop(context, week),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selected != null && selected != _currentWeek) {
      final repo = getIt<LocalCourseRepository>();
      final schedule = await repo.getWeekSchedule(selected, _semester!);
      setState(() {
        _currentWeek = selected;
        _coursesByDay = schedule.coursesByDay;
      });
    }
  }
}