import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/app_module.dart';
import '../../data/repository/local_course_repository.dart';
import '../../data/repository/course_change_notifier.dart';
import '../../domain/model/course.dart';
import '../import/course_edit_screen.dart';

/// 课程管理页面：查看和删除已录入的课程
class CourseManagementScreen extends ConsumerStatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  ConsumerState<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends ConsumerState<CourseManagementScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() async {
    setState(() => _isLoading = true);
    final repo = getIt<LocalCourseRepository>();
    final courses = await repo.getAllCourses();
    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('暂无课程', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text('请在"导入课程"中添加', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return _CourseCard(
                      course: course,
                      onDelete: () => _deleteCourse(course),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CourseEditScreen(course: course),
                          ),
                        ).then((_) => _loadCourses());
                      },
                    );
                  },
                ),
    );
  }

  void _deleteCourse(Course course) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定删除 "${course.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = getIt<LocalCourseRepository>();
      await repo.deleteCourse(course.id);
      CourseChangeNotifier().notify();
      _loadCourses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${course.name} 已删除')),
        );
      }
    }
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: _courseColor(course),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        dayNames[course.dayOfWeek - 1],
                        '${course.startPeriod}-${course.endPeriod}节',
                        if (course.location != null) course.location!,
                        if (course.teacher != null) course.teacher!,
                      ].join(' · '),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    if (course.weekStart != null || course.weeks != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _weekDescription(course),
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekDescription(Course course) {
    if (course.weeks != null && course.weeks!.isNotEmpty) {
      if (course.weeks!.every((w) => w % 2 == 1)) return '单周';
      if (course.weeks!.every((w) => w % 2 == 0)) return '双周';
      return '第${course.weeks!.join(',')}周';
    }
    if (course.weekStart != null && course.weekEnd != null) {
      return '第${course.weekStart}-${course.weekEnd}周';
    }
    return '每周年年都有';
  }

  Color _courseColor(Course course) {
    if (course.colorHex != null) {
      try {
        return Color(int.parse(course.colorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple,
                    Colors.teal, Colors.pink, Colors.indigo, Colors.amber];
    return colors[course.name.hashCode % colors.length];
  }
}
