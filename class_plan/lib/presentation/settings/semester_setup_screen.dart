import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../di/app_module.dart';
import '../../domain/model/semester.dart';
import '../../data/repository/local_course_repository.dart';

class SemesterSetupScreen extends ConsumerStatefulWidget {
  const SemesterSetupScreen({super.key});

  @override
  ConsumerState<SemesterSetupScreen> createState() => _SemesterSetupScreenState();
}

class _SemesterSetupScreenState extends ConsumerState<SemesterSetupScreen> {
  final _uuid = const Uuid();

  final _nameController = TextEditingController(text: '2025-2026学年第一学期');
  DateTime _startDate = DateTime.now();
  int _totalWeeks = 20;
  String? _currentSemesterId; // 用于保存原有学期ID

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSemester();
  }

  void _loadCurrentSemester() async {
    final repo = getIt<LocalCourseRepository>();
    final semester = await repo.getCurrentSemester();
    if (semester != null && mounted) {
      setState(() {
        _nameController.text = semester.name;
        _startDate = semester.startDate;
        _totalWeeks = semester.totalWeeks;
        _currentSemesterId = semester.id;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学期设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 学期名称
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '学期名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // 开学日期
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('开学日期', style: TextStyle(fontSize: 14)),
            subtitle: Text(
              DateFormat('yyyy年MM月dd日 (EEEE)').format(_startDate),
              style: const TextStyle(fontSize: 16),
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
          ),
          const Divider(),
          const SizedBox(height: 16),

          // 学期周数
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('学期周数', style: TextStyle(fontSize: 14)),
                  Text('$_totalWeeks 周', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Slider(
                value: _totalWeeks.toDouble(),
                min: 10,
                max: 25,
                divisions: 15,
                label: '$_totalWeeks 周',
                onChanged: (value) {
                  setState(() {
                    _totalWeeks = value.round();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 预览
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('学期预览', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('开学日期：${DateFormat('yyyy/MM/dd').format(_startDate)}'),
                Text('结束日期：${DateFormat('yyyy/MM/dd').format(_endDate)}'),
                Text('共 $_totalWeeks 周'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 保存按钮
          FilledButton(
            onPressed: _isSaving ? null : _saveSemester,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存学期设置', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  DateTime get _endDate {
    return _startDate.add(Duration(days: _totalWeeks * 7 - 1));
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      // 调整到周一
      final monday = picked.subtract(Duration(days: picked.weekday - 1));
      setState(() {
        _startDate = monday;
      });
    }
  }

  Future<void> _saveSemester() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final repo = getIt<LocalCourseRepository>();
      final semesterId = _currentSemesterId ?? _uuid.v4();
      final semester = Semester(
        id: semesterId,
        name: _nameController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        totalWeeks: _totalWeeks,
      );

      await repo.saveSemester(semester);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('学期设置已保存'),
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
