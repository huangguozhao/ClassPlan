import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/app_module.dart';
import '../../data/repository/local_course_repository.dart';
import '../../data/conflict/conflict_detection_service.dart';

/// 课程冲突检测页面
class ConflictDetectionScreen extends ConsumerStatefulWidget {
  const ConflictDetectionScreen({super.key});

  @override
  ConsumerState<ConflictDetectionScreen> createState() => _ConflictDetectionScreenState();
}

class _ConflictDetectionScreenState extends ConsumerState<ConflictDetectionScreen> {
  List<CourseConflict> _timeConflicts = [];
  List<CourseConflict> _locationConflicts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _detectConflicts();
  }

  Future<void> _detectConflicts() async {
    setState(() => _isLoading = true);

    final repo = getIt<LocalCourseRepository>();
    final service = ConflictDetectionService(repo);
    final conflicts = await service.detectAllConflicts();

    setState(() {
      _timeConflicts = conflicts.where((c) => c.type == ConflictType.time).toList();
      _locationConflicts = conflicts.where((c) => c.type == ConflictType.location).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程冲突检测'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _detectConflicts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _timeConflicts.isEmpty && _locationConflicts.isEmpty
              ? _buildNoConflicts()
              : _buildConflictList(),
    );
  }

  Widget _buildNoConflicts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
          const SizedBox(height: 16),
          const Text(
            '未发现课程冲突',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '您的课表安排合理，没有时间或地点冲突',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictList() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_timeConflicts.isNotEmpty) ...[
          _buildSectionHeader('时间冲突', Icons.schedule, Colors.orange),
          const SizedBox(height: 8),
          ..._timeConflicts.map((c) => _buildConflictCard(c)),
          const SizedBox(height: 24),
        ],
        if (_locationConflicts.isNotEmpty) ...[
          _buildSectionHeader('地点冲突', Icons.location_on, Colors.red),
          const SizedBox(height: 8),
          ..._locationConflicts.map((c) => _buildConflictCard(c)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${_timeConflicts.length + _locationConflicts.length}',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildConflictCard(CourseConflict conflict) {
    final color = conflict.type == ConflictType.time ? Colors.orange : Colors.red;
    final isToday1 = _isToday(conflict.course1);
    final isToday2 = _isToday(conflict.course2);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conflict.course1.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isToday1)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '今天',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${conflict.course1.startPeriod}-${conflict.course1.endPeriod}节'
                        '${conflict.course1.location != null ? " · ${conflict.course1.location}" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.compare_arrows, size: 16, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '与以下课程冲突：',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withAlpha(179),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conflict.course2.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isToday2)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '今天',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${conflict.course2.startPeriod}-${conflict.course2.endPeriod}节'
                        '${conflict.course2.location != null ? " · ${conflict.course2.location}" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(Course course) {
    return course.dayOfWeek == DateTime.now().weekday;
  }
}