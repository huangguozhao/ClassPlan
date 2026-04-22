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
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  String _sortBy = 'day'; // 'day', 'name', 'time'
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCourses() async {
    setState(() => _isLoading = true);
    final repo = getIt<LocalCourseRepository>();
    final courses = await repo.getAllCourses();
    setState(() {
      _courses = courses;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    var result = List<Course>.from(_courses);

    // 搜索过滤
    if (_searchQuery.isNotEmpty) {
      result = result.where((c) {
        return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (c.teacher?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (c.location?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // 排序
    switch (_sortBy) {
      case 'name':
        result.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'day':
        result.sort((a, b) {
          final dayCompare = a.dayOfWeek.compareTo(b.dayOfWeek);
          if (dayCompare != 0) return dayCompare;
          return a.startPeriod.compareTo(b.startPeriod);
        });
        break;
      case 'time':
        result.sort((a, b) {
          final timeCompare = a.startPeriod.compareTo(b.startPeriod);
          if (timeCompare != 0) return timeCompare;
          return a.dayOfWeek.compareTo(b.dayOfWeek);
        });
        break;
    }

    _filteredCourses = result;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String courseId) {
    setState(() {
      if (_selectedIds.contains(courseId)) {
        _selectedIds.remove(courseId);
      } else {
        _selectedIds.add(courseId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (_selectedIds.length == _filteredCourses.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_filteredCourses.map((c) => c.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('批量删除'),
        content: Text('确定删除选中的 ${_selectedIds.length} 门课程吗？此操作不可撤销。'),
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
      for (final id in _selectedIds) {
        await repo.deleteCourse(id);
      }
      CourseChangeNotifier().notify();
      _selectedIds.clear();
      _loadCourses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已删除 ${_selectedIds.length} 门课程')),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('已选择 ${_selectedIds.length} 门课程')
            : const Text('课程管理'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: Icon(_selectedIds.length == _filteredCourses.length
                  ? Icons.deselect
                  : Icons.select_all),
              onPressed: _selectAll,
              tooltip: '全选',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
              tooltip: '删除选中',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: '选择模式',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              tooltip: '排序方式',
              onSelected: (value) {
                setState(() {
                  _sortBy = value;
                  _applyFilters();
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'day',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: _sortBy == 'day' ? Colors.blue : null),
                      const SizedBox(width: 8),
                      const Text('按星期排序'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha, size: 18, color: _sortBy == 'name' ? Colors.blue : null),
                      const SizedBox(width: 8),
                      const Text('按名称排序'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'time',
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: _sortBy == 'time' ? Colors.blue : null),
                      const SizedBox(width: 8),
                      const Text('按节次排序'),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadCourses,
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索课程名称、教师、地点...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          // 课程列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCourses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.book_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty ? '没有找到匹配的课程' : '暂无课程',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty ? '试试其他关键词' : '请在"导入课程"中添加',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _filteredCourses.length,
                        itemBuilder: (context, index) {
                          final course = _filteredCourses[index];
                          final isSelected = _selectedIds.contains(course.id);

                          if (_isSelectionMode) {
                            return _buildSelectableCourseCard(course, isSelected);
                          }
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
          ),
        ],
      ),
      // 底部操作栏（选择模式下）
      bottomNavigationBar: _isSelectionMode && _selectedIds.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '已选择 ${_selectedIds.length} 门课程',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    FilledButton.icon(
                      onPressed: _deleteSelected,
                      icon: const Icon(Icons.delete),
                      label: const Text('删除'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSelectableCourseCard(Course course, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? Colors.blue.shade50 : null,
      child: InkWell(
        onTap: () => _toggleSelection(course.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(course.id),
              ),
              Container(
                width: 4,
                height: 50,
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getCourseSubtitle(course),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCourseSubtitle(Course course) {
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return [
      dayNames[course.dayOfWeek - 1],
      '${course.startPeriod}-${course.endPeriod}节',
      if (course.location != null) course.location!,
    ].join(' · ');
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 50,
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
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
