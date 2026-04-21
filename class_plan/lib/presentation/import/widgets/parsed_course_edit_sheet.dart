import 'package:flutter/material.dart';

import '../../../domain/model/structured_course.dart';

/// 解析结果编辑底部表单
/// 用于用户在确认页面修正 AI 解析的课程信息
class ParsedCourseEditSheet extends StatefulWidget {
  final StructuredCourse original;
  final void Function(StructuredCourse edited) onSave;

  const ParsedCourseEditSheet({
    super.key,
    required this.original,
    required this.onSave,
  });

  @override
  State<ParsedCourseEditSheet> createState() => _ParsedCourseEditSheetState();
}

class _ParsedCourseEditSheetState extends State<ParsedCourseEditSheet> {
  late int _dayOfWeek;
  late int _startPeriod;
  late int _endPeriod;

  final _periods = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    _dayOfWeek = widget.original.dayOfWeek ?? 1;
    _startPeriod = widget.original.startPeriod ?? 1;
    _endPeriod = widget.original.endPeriod ?? _startPeriod;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '编辑课程',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.original.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (widget.original.teacher != null || widget.original.location != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [widget.original.teacher, widget.original.location]
                    .where((e) => e != null)
                    .join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
          const SizedBox(height: 24),

          // 星期选择
          const Text('上课星期', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
            selected: {_dayOfWeek},
            onSelectionChanged: (set) {
              setState(() => _dayOfWeek = set.first);
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

          // 保存按钮
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('保存'),
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final edited = StructuredCourse(
      name: widget.original.name,
      teacher: widget.original.teacher,
      location: widget.original.location,
      dayOfWeek: _dayOfWeek,
      startPeriod: _startPeriod,
      endPeriod: _endPeriod,
      weekStart: widget.original.weekStart,
      weekEnd: widget.original.weekEnd,
      weeks: widget.original.weeks,
      colorHex: widget.original.colorHex,
    );
    widget.onSave(edited);
    Navigator.pop(context);
  }
}