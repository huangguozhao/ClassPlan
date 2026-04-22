import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/model/course.dart';
import '../../data/repository/local_course_repository.dart';
import '../../data/repository/course_change_notifier.dart';
import '../../di/app_module.dart';

/// 课程编辑/详情页面
class CourseEditScreen extends ConsumerStatefulWidget {
  final Course course;

  const CourseEditScreen({super.key, required this.course});

  @override
  ConsumerState<CourseEditScreen> createState() => _CourseEditScreenState();
}

class _CourseEditScreenState extends ConsumerState<CourseEditScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _teacherController;
  late final TextEditingController _locationController;
  late final TextEditingController _noteController;

  late int _selectedDay;
  late int _startPeriod;
  late int _endPeriod;
  int? _weekStart;
  int? _weekEnd;
  String _weekType = 'all'; // 'all', 'odd', 'even'
  Color _selectedColor = Colors.blue;
  bool _isSaving = false;

  final _periods = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    final c = widget.course;
    _nameController = TextEditingController(text: c.name);
    _teacherController = TextEditingController(text: c.teacher ?? '');
    _locationController = TextEditingController(text: c.location ?? '');
    _noteController = TextEditingController(text: '');
    _selectedDay = c.dayOfWeek;
    _startPeriod = c.startPeriod;
    _endPeriod = c.endPeriod;
    _weekStart = c.weekStart;
    _weekEnd = c.weekEnd;
    if (c.colorHex != null) {
      try {
        _selectedColor = Color(int.parse(c.colorHex!.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    // 根据 weeks 判断单双周类型
    if (c.weeks != null && c.weeks!.isNotEmpty) {
      if (c.weeks!.every((w) => w % 2 == 1)) {
        _weekType = 'odd';
      } else if (c.weeks!.every((w) => w % 2 == 0)) {
        _weekType = 'even';
      } else {
        _weekType = 'all';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _teacherController.dispose();
    _locationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑课程'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '课程名称 *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? '请输入课程名称' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teacherController,
              decoration: const InputDecoration(
                labelText: '教师',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '上课地点',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            const Text('上课星期 *', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(7, (index) {
                final day = index + 1;
                final isSelected = _selectedDay == day;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ['一', '二', '三', '四', '五', '六', '日'][index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('开始节次', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _startPeriod,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _periods.map((p) => DropdownMenuItem(value: p, child: Text('$p'))).toList(),
                        onChanged: (v) => setState(() {
                          _startPeriod = v!;
                          if (_endPeriod < _startPeriod) _endPeriod = _startPeriod;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('结束节次', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _endPeriod,
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: _periods.map((p) => DropdownMenuItem(value: p, child: Text('$p'))).toList(),
                        onChanged: (v) => setState(() => _endPeriod = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('不限')),
                          ...List.generate(20, (i) => DropdownMenuItem(value: i + 1, child: Text('第 ${i + 1} 周'))),
                        ],
                        onChanged: (v) => setState(() => _weekStart = v),
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
                        decoration: const InputDecoration(border: OutlineInputBorder()),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('不限')),
                          ...List.generate(20, (i) => DropdownMenuItem(value: i + 1, child: Text('第 ${i + 1} 周'))),
                        ],
                        onChanged: (v) => setState(() => _weekEnd = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text('单双周', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: [
                _WeekTypeChip(
                  label: '全部周',
                  isSelected: _weekType == 'all',
                  onTap: () => setState(() => _weekType = 'all'),
                ),
                const SizedBox(width: 8),
                _WeekTypeChip(
                  label: '单周',
                  isSelected: _weekType == 'odd',
                  onTap: () => setState(() => _weekType = 'odd'),
                ),
                const SizedBox(width: 8),
                _WeekTypeChip(
                  label: '双周',
                  isSelected: _weekType == 'even',
                  onTap: () => setState(() => _weekType = 'even'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // AI 解析的原始数据
            if (widget.course.extraData != null && widget.course.extraData!.isNotEmpty) ...[
              const Text('AI 解析信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.course.extraData!.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                          ),
                          Expanded(
                            child: Text(
                              entry.value.toString(),
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade900),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            const Text('课程颜色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                Colors.blue, Colors.green, Colors.orange, Colors.purple,
                Colors.teal, Colors.pink, Colors.indigo, Colors.amber,
                Colors.red, Colors.cyan,
              ].map((color) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.black, width: 3) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _isSaving ? null : _saveCourse,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('保存修改', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final repo = getIt<LocalCourseRepository>();
      final colorHex = '#${_selectedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

      // 根据单双周类型计算 weeks 列表
      List<int>? weeks;
      if (_weekType != 'all' && _weekStart != null && _weekEnd != null) {
        final start = _weekStart!;
        final end = _weekEnd!;
        if (_weekType == 'odd') {
          weeks = List.generate(((end - start) ~/ 2) + 1, (i) => start + i * 2);
        } else if (_weekType == 'even') {
          weeks = List.generate(((end - start) ~/ 2) + 1, (i) => start + 1 + i * 2);
        }
      }

      final updated = widget.course.copyWith(
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

      await repo.saveCourse(updated);
      CourseChangeNotifier().notify();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('课程已更新'), behavior: SnackBarBehavior.floating),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定删除 "${widget.course.name}" 吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = getIt<LocalCourseRepository>();
      await repo.deleteCourse(widget.course.id);
      CourseChangeNotifier().notify();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.course.name} 已删除')),
        );
      }
    }
  }
}

class _WeekTypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WeekTypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
