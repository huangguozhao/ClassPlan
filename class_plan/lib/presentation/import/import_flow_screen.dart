import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../data/repository/local_course_repository.dart';
import '../../data/repository/course_change_notifier.dart';
import '../../data/importer/pdf/pdf_importer.dart';
import '../../data/importer/image/image_importer.dart';
import '../../data/ai/ai_service.dart';
import '../../domain/model/course.dart';
import '../../domain/model/structured_course.dart';
import '../../domain/parser/rule/rule_based_parser.dart';
import '../../di/app_module.dart';
import 'ai_settings_screen.dart';
import 'widgets/parsed_course_edit_sheet.dart';
import 'widgets/draggable_course_card.dart';
import 'widgets/timetable_grid_editor.dart';

/// 导入流程屏幕
/// 支持 PDF 和图片 OCR 的完整导入流程
class ImportFlowScreen extends ConsumerStatefulWidget {
  final String sourceType; // 'pdf' 或 'image'

  const ImportFlowScreen({super.key, required this.sourceType});

  @override
  ConsumerState<ImportFlowScreen> createState() => _ImportFlowScreenState();
}

class _ImportFlowScreenState extends ConsumerState<ImportFlowScreen> {
  int _step = 0; // 0=选择文件, 1=解析中, 2=确认课程
  String? _selectedFilePath;
  String? _rawText;
  List<StructuredCourse> _parsedCourses = [];
  String? _error;
  bool _useRuleParser = false; // 默认使用 AI 解析
  String? _selectedAiProviderId;
  bool _aiServiceInitialized = false;

  // 追踪用户编辑过的课程
  final Map<int, StructuredCourse> _editedCourses = {};

  // 拖拽放置的课程：courseIndex -> (dayOfWeek, startPeriod)
  final Map<int, Map<String, int>> _placedCourses = {};

  final _ruleParser = RuleBasedParser();
  AiService? _aiService;

  /// 获取有效课程（编辑后或原版）
  StructuredCourse _getEffectiveCourse(int index) {
    return _editedCourses[index] ?? _parsedCourses[index];
  }

  @override
  void initState() {
    super.initState();
    _initAiService();
  }

  Future<void> _initAiService() async {
    final service = AiService();
    await service.initialize();
    setState(() {
      _aiService = service;
      _aiServiceInitialized = true;
      _selectedAiProviderId = service.selectedProviderId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sourceType == 'pdf' ? 'PDF 导入' : '图片 OCR 导入'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case 0:
        return _buildFileSelection();
      case 1:
        return _buildParsing();
      case 2:
        return _buildConfirmation();
      default:
        return const Center(child: Text('未知步骤'));
    }
  }

  Widget _buildFileSelection() {
    if (!_aiServiceInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final providers = _aiService!.availableProviders;
    final selectedProvider = _selectedAiProviderId ?? 'claude';
    final isConfigured = _aiService!.isProviderConfigured(selectedProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '选择文件',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.sourceType == 'pdf'
                        ? '请选择学校课表 PDF 文件'
                        : '请选择课表图片（支持 JPG、PNG）',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  // 文件选择卡片
                  Card(
                    child: InkWell(
                      onTap: _pickFile,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              widget.sourceType == 'pdf'
                                  ? Icons.picture_as_pdf
                                  : Icons.image,
                              size: 64,
                              color: widget.sourceType == 'pdf'
                                  ? Colors.red
                                  : Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '点击选择文件',
                              style: TextStyle(fontSize: 16),
                            ),
                            if (_selectedFilePath != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _selectedFilePath!.split('/').last.split('\\').last,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 错误提示
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: Colors.red.shade700),
                            onPressed: () => setState(() => _error = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 解析方式选择
                  const Text(
                    '解析方式',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // 规则解析选项
                  RadioListTile<bool>(
                    title: const Text('规则解析（本地）'),
                    subtitle: const Text('无需网络，适合标准格式课表'),
                    value: true,
                    groupValue: _useRuleParser,
                    onChanged: (v) => setState(() => _useRuleParser = v!),
                  ),

                  // AI 解析选项
                  RadioListTile<bool>(
                    title: Row(
                      children: [
                        Text(
                          'AI 解析',
                          style: TextStyle(
                            fontWeight: _useRuleParser == false ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '推荐',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                          ),
                        ),
                        if (!isConfigured) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '未配置',
                              style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      isConfigured
                          ? '使用 ${_aiService!.selectedProvider.name} 解析，适合复杂格式课表'
                          : '需要先在设置中配置 AI API Key',
                      style: TextStyle(
                        fontSize: 12,
                        color: isConfigured ? Colors.grey.shade600 : Colors.orange.shade700,
                      ),
                    ),
                    value: false,
                    groupValue: _useRuleParser,
                    onChanged: (v) => setState(() => _useRuleParser = v!),
                  ),

                  // AI Provider 选择
                  if (!_useRuleParser) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('选择 AI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: providers.map((p) {
                              final configured = _aiService!.isProviderConfigured(p.id);
                              final selected = _selectedAiProviderId == p.id;
                              return ChoiceChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(p.name),
                                    if (configured) ...[
                                      const SizedBox(width: 4),
                                      Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                                    ],
                                  ],
                                ),
                                selected: selected,
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _selectedAiProviderId = p.id);
                                    _aiService!.selectProvider(p.id);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          if (!isConfigured)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AiSettingsScreen(),
                                  ),
                                ).then((_) {
                                  // 返回时刷新配置状态
                                  setState(() {});
                                });
                              },
                              icon: const Icon(Icons.settings, size: 16),
                              label: const Text('去设置 API Key'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: _selectedFilePath == null ? null : _startParsing,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('开始解析', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsing() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            widget.sourceType == 'pdf' ? '正在解析 PDF...' : '正在识别图片文字...',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilePath?.split('/').last.split('\\').last ?? '',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    // 获取未放置的课程（不在 _placedCourses 中的课程）
    final unplacedIndices = List.generate(_parsedCourses.length, (i) => i)
        .where((i) => !_placedCourses.containsKey(i))
        .toList();

    // AI 返回空结果时显示提示
    if (_parsedCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              '未能识别到课程',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '可能是 AI 解析失败或课表格式无法识别。\n可以尝试切换到规则解析方式。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _useRuleParser = true; // 切换到规则解析
                  _step = 0;
                });
              },
              icon: const Icon(Icons.rule),
              label: const Text('尝试规则解析'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _retryParsing,
              child: const Text('重新解析'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 顶部提示栏
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '解析完成 ${_parsedCourses.length} 门课程，已放置 ${_placedCourses.length} 门',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: _retryParsing,
                child: const Text('重新解析'),
              ),
            ],
          ),
        ),
        // 未放置的课程（可拖拽）
        if (unplacedIndices.isNotEmpty)
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '拖拽课程到下方时间表',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: unplacedIndices.length,
                    itemBuilder: (context, idx) {
                      final courseIndex = unplacedIndices[idx];
                      if (courseIndex < 0 || courseIndex >= _parsedCourses.length) {
                        return const SizedBox.shrink();
                      }
                      final course = _parsedCourses[courseIndex];
                      if (course == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: 150,
                          child: DraggableCourseCard(
                            course: course,
                            courseIndex: courseIndex,
                            isPlaced: false,
                            onTap: () => _openEditSheet(courseIndex, course),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        // 时间表网格编辑器
        Expanded(
          child: TimetableGridEditor(
            courses: _parsedCourses,
            placedCourses: _placedCourses,
            onCourseDropped: _onCourseDropped,
            onCourseRemoved: _onCourseRemoved,
          ),
        ),
        // 底部保存按钮
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _parsedCourses.isEmpty ? null : _saveCourses,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '保存 ${_parsedCourses.length} 门课程',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _onCourseDropped(int courseIndex, int dayOfWeek, int startPeriod, int endPeriod) {
    setState(() {
      _placedCourses[courseIndex] = {
        'dayOfWeek': dayOfWeek,
        'startPeriod': startPeriod,
        'endPeriod': endPeriod,
      };
      // 清除编辑记录（拖拽优先）
      _editedCourses.remove(courseIndex);
    });
  }

  void _onCourseRemoved(int courseIndex) {
    setState(() {
      _placedCourses.remove(courseIndex);
    });
  }

  Future<void> _pickFile() async {
    try {
      final FileType type;
      final List<String>? extensions;

      if (widget.sourceType == 'pdf') {
        type = FileType.custom;
        extensions = ['pdf'];
      } else {
        type = FileType.custom;
        extensions = ['jpg', 'jpeg', 'png'];
      }

      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: extensions,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = '选择文件失败：$e';
      });
    }
  }

  Future<void> _startParsing() async {
    if (_selectedFilePath == null) return;

    setState(() {
      _step = 1;
      _error = null;
    });

    try {
      final importer = widget.sourceType == 'pdf'
          ? PdfImporter()
          : ImageImporter();
      final rawData = await importer.import(_selectedFilePath!);
      _rawText = rawData.rawText;

      List<StructuredCourse> courses;

      if (_useRuleParser) {
        // 规则解析
        courses = await _ruleParser.parse(rawData);
      } else {
        // AI 解析
        if (_selectedAiProviderId != null) {
          await _aiService!.selectProvider(_selectedAiProviderId!);
        }
        courses = await _aiService!.parse(rawData);
      }

      setState(() {
        _parsedCourses = courses;
        _step = 2;
      });
    } catch (e) {
      setState(() {
        _error = '解析失败：$e';
        _step = 0;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解析失败：$e')),
        );
      }
    }
  }

  void _retryParsing() {
    setState(() {
      _step = 0;
      _placedCourses.clear();
      _editedCourses.clear();
    });
  }

  Future<void> _saveCourses() async {
    if (_parsedCourses.isEmpty) return;

    try {
      final repo = getIt<LocalCourseRepository>();
      final uuid = const Uuid();
      // 使用有效课程（编辑后或原版）+ 拖拽放置的位置
      final courses = List.generate(_parsedCourses.length, (i) {
        final sc = _getEffectiveCourse(i);
        final placed = _placedCourses[i];

        return Course(
          id: uuid.v4(),
          name: sc.name,
          teacher: sc.teacher,
          location: sc.location,
          dayOfWeek: placed?['dayOfWeek'] ?? sc.dayOfWeek ?? 1,
          startPeriod: placed?['startPeriod'] ?? sc.startPeriod ?? 1,
          endPeriod: placed?['endPeriod'] ?? sc.endPeriod ?? sc.startPeriod ?? 1,
          weekStart: sc.weekStart,
          weekEnd: sc.weekEnd,
          weeks: sc.weeks,
        );
      });

      await repo.saveCourses(courses);
      CourseChangeNotifier().notify();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已保存 ${courses.length} 门课程'),
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
    }
  }

  void _openEditSheet(int index, StructuredCourse course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ParsedCourseEditSheet(
        original: course,
        onSave: (edited) {
          setState(() {
            _editedCourses[index] = edited;
          });
        },
      ),
    );
  }
}

/// 解析出的课程卡片
class _ParsedCourseCard extends StatelessWidget {
  final StructuredCourse course;
  final bool isEdited;
  final VoidCallback? onTap;

  const _ParsedCourseCard({
    required this.course,
    this.isEdited = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (isEdited)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '已修改',
                        style: TextStyle(fontSize: 10, color: Colors.blue.shade800),
                      ),
                    ),
                  if (onTap != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (course.dayOfWeek != null)
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: dayNames[course.dayOfWeek! - 1],
                    ),
                  if (course.startPeriod != null)
                    _InfoChip(
                      icon: Icons.access_time,
                      label: course.endPeriod != null
                          ? '${course.startPeriod}-${course.endPeriod}节'
                          : '${course.startPeriod}节',
                    ),
                  if (course.location != null)
                    _InfoChip(icon: Icons.location_on, label: course.location!),
                  if (course.teacher != null)
                    _InfoChip(icon: Icons.person, label: course.teacher!),
                  if (course.weekStart != null && course.weekEnd != null)
                    _InfoChip(
                      icon: Icons.date_range,
                      label: '第${course.weekStart}-${course.weekEnd}周',
                    ),
                ],
              ),
              if (course.dayOfWeek == null ||
                  course.startPeriod == null ||
                  course.weekStart == null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber, size: 14, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        '部分信息缺失，建议手动补充',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
      ],
    );
  }
}
