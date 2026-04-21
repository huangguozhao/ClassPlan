import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../di/app_module.dart';
import '../../domain/model/course.dart';
import '../../domain/model/semester.dart';
import '../../domain/model/week_schedule.dart';
import '../../data/repository/local_course_repository.dart';

class ManualEntryScreen extends ConsumerStatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  ConsumerState<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends ConsumerState<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _teacherController = TextEditingController();
  final _locationController = TextEditingController();

  int _selectedDay = 1;
  int _startPeriod = 1;
  int _endPeriod = 2;
  int? _weekStart;
  int? _weekEnd;
  bool _isSingleDoubleWeek = false; // 单双周模式
  List<int> _selectedWeeks = [];
  Color _selectedColor = Colors.blue;

  bool _isSaving = false;

  final _periods = List.generate(12, (i) => i + 1);

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加课程'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 课程名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '课程名称 *',
                hintText: '如：高等数学',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入课程名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 教师
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: '教师（可选）',
                hintText: '如：张三',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 上课地点
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '上课地点（可选）',
                hintText: '如：教学楼A301',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 星期选择
            const Text('上课星期 *', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('一')),
                ButtonSegment(value: 2, label: Text('二')),
                ButtonSegment(value: 3, label: Text('三')),
                ButtonSegment(value: 4, label: Text('四')),
                ButtonSegment(value: 5, label: Text('五')),
                ButtonSegment(value: 6, label: Text('六')),
                ButtonSegment(value: 7, label: Text('日')),
              ],
              selected: {_selectedDay},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedDay = set.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // 节次选择
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('开始节次 *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _startPeriod,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _periods.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('$p'),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _startPeriod = value!;
                            if (_endPeriod < _startPeriod) {
                              _endPeriod = _startPeriod;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('结束节次 *', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _endPeriod,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: _periods.map((p) => DropdownMenuItem(
                          value: p,
                          child: Text('$p'),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _endPeriod = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 周次设置
            const Text('上课周次', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('单双周模式'),
              subtitle: const Text('分别选择单周和双周的课程'),
              value: _isSingleDoubleWeek,
              onChanged: (value) {
                setState(() {
                  _isSingleDoubleWeek = value;
                  if (value) {
                    _selectedWeeks = [];
                  } else {
                    _weekStart = null;
                    _weekEnd = null;
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            if (_isSingleDoubleWeek) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('单周'),
                    selected: _selectedWeeks.contains(0),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedWeeks.add(0);
                        } else {
                          _selectedWeeks.remove(0);
                        }
                      });
                    },
                  ),
                  FilterChip(
                    label: const Text('双周'),
                    selected: _selectedWeeks.contains(1),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedWeeks.add(1);
                        } else {
                          _selectedWeeks.remove(1);
                        }
                      });
                    },
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('起始周', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          value: _weekStart,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('不限')),
                            ...List.generate(20, (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('第 ${i + 1} 周'),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _weekStart = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('结束周', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int?>(
                          value: _weekEnd,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('不限')),
                            ...List.generate(20, (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('第 ${i + 1} 周'),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _weekEnd = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // 颜色选择
            const Text('课程颜色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
                Colors.teal,
                Colors.pink,
                Colors.indigo,
                Colors.amber,
                Colors.red,
                Colors.cyan,
              ].map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            // 保存按钮
            FilledButton(
              onPressed: _isSaving ? null : _saveCourse,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('保存课程', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final repo = getIt<LocalCourseRepository>();
      final colorHex = '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

      // 处理单双周
      List<int>? weeks;
      if (_isSingleDoubleWeek && _selectedWeeks.isNotEmpty) {
        // 将0/1转换为实际周次
        weeks = [];
        for (int w = 1; w <= 20; w++) {
          if (_selectedWeeks.contains(w % 2)) {
            weeks.add(w);
          }
        }
      }

      final course = Course(
        id: _uuid.v4(),
        name: _nameController.text.trim(),
        teacher: _teacherController.text.trim().isEmpty ? null : _teacherController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        dayOfWeek: _selectedDay,
        startPeriod: _startPeriod,
        endPeriod: _endPeriod,
        weekStart: _weekStart,
        weekEnd: _weekEnd,
        weeks: weeks,
        colorHex: colorHex,
      );

      await repo.saveCourse(course);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${course.name} 已添加'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
