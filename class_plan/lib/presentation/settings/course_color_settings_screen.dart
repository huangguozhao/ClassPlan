import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/app_module.dart';
import '../../data/repository/local_course_repository.dart';
import '../../data/repository/course_change_notifier.dart';
import '../../domain/model/course.dart';

/// 课程颜色设置页面
class CourseColorSettingsScreen extends ConsumerStatefulWidget {
  const CourseColorSettingsScreen({super.key});

  @override
  ConsumerState<CourseColorSettingsScreen> createState() => _CourseColorSettingsScreenState();
}

class _CourseColorSettingsScreenState extends ConsumerState<CourseColorSettingsScreen> {
  List<Course> _courses = [];
  bool _isLoading = true;

  /// 预设颜色列表
  static const List<Color> _presetColors = [
    Color(0xFF5C6BC0), // Indigo
    Color(0xFF42A5F5), // Blue
    Color(0xFF26C6DA), // Cyan
    Color(0xFF66BB6A), // Green
    Color(0xFFFFCA28), // Amber
    Color(0xFFFF7043), // Deep Orange
    Color(0xFFEF5350), // Red
    Color(0xFFAB47BC), // Purple
    Color(0xFF8D6E63), // Brown
    Color(0xFF78909C), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  void _loadCourses() async {
    setState(() => _isLoading = true);
    final repo = getIt<LocalCourseRepository>();
    final courses = await repo.getAllCourses();
    // 按课程名排序
    courses.sort((a, b) => a.name.compareTo(b.name));
    setState(() {
      _courses = courses;
      _isLoading = false;
    });
  }

  Color _getCourseColor(Course course) {
    if (course.colorHex == null) {
      return _presetColors[course.name.hashCode % _presetColors.length];
    }
    try {
      return Color(int.parse(course.colorHex!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return _presetColors[course.name.hashCode % _presetColors.length];
    }
  }

  void _showColorPicker(Course course) async {
    final selectedColor = await showDialog<Color>(
      context: context,
      builder: (context) => _ColorPickerDialog(
        currentColor: _getCourseColor(course),
        presetColors: _presetColors,
      ),
    );

    if (selectedColor != null) {
      final colorHex = '#${selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
      final updatedCourse = course.copyWith(colorHex: colorHex);

      final repo = getIt<LocalCourseRepository>();
      await repo.saveCourse(updatedCourse);
      CourseChangeNotifier().notify();

      _loadCourses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程颜色'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(
                  child: Text('暂无课程，请先导入课程'),
                )
              : ListView.builder(
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    final color = _getCourseColor(course);
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      title: Text(course.name),
                      subtitle: Text(
                        '${course.teacher ?? '未设置教师'} · ${course.location ?? '未设置地点'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showColorPicker(course),
                      ),
                      onTap: () => _showColorPicker(course),
                    );
                  },
                ),
    );
  }
}

/// 颜色选择对话框
class _ColorPickerDialog extends StatefulWidget {
  final Color currentColor;
  final List<Color> presetColors;

  const _ColorPickerDialog({
    required this.currentColor,
    required this.presetColors,
  });

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('选择颜色'),
      content: SizedBox(
        width: 280,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: widget.presetColors.map((color) {
            final isSelected = _selectedColor.value == color.value;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = color;
                });
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: Colors.black, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _selectedColor),
          child: const Text('确定'),
        ),
      ],
    );
  }
}