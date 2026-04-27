import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/model/grid_settings.dart';
import 'grid_settings_provider.dart';

class GridSettingsBottomSheet extends ConsumerStatefulWidget {
  const GridSettingsBottomSheet({super.key});

  @override
  ConsumerState<GridSettingsBottomSheet> createState() =>
      _GridSettingsBottomSheetState();
}

class _GridSettingsBottomSheetState
    extends ConsumerState<GridSettingsBottomSheet> {
  late TextEditingController _courseHeightController;
  late TextEditingController _emptyHeightController;
  late TextEditingController _spacingController;
  late TextEditingController _periodWidthController;
  late TextEditingController _dayWidthController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(gridSettingsProvider);
    _courseHeightController =
        TextEditingController(text: settings.courseCellHeight.toInt().toString());
    _emptyHeightController =
        TextEditingController(text: settings.emptyCellHeight.toInt().toString());
    _spacingController =
        TextEditingController(text: settings.cellSpacing.toString());
    _periodWidthController =
        TextEditingController(text: settings.periodColumnWidth.toInt().toString());
    _dayWidthController =
        TextEditingController(text: settings.dayColumnWidth.toInt().toString());
  }

  @override
  void dispose() {
    _courseHeightController.dispose();
    _emptyHeightController.dispose();
    _spacingController.dispose();
    _periodWidthController.dispose();
    _dayWidthController.dispose();
    super.dispose();
  }

  void _updateControllers(GridSettings settings) {
    _courseHeightController.text = settings.courseCellHeight.toInt().toString();
    _emptyHeightController.text = settings.emptyCellHeight.toInt().toString();
    _spacingController.text = settings.cellSpacing.toString();
    _periodWidthController.text = settings.periodColumnWidth.toInt().toString();
    _dayWidthController.text = settings.dayColumnWidth.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(gridSettingsProvider);
    final notifier = ref.read(gridSettingsProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            '课表布局调整',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Mini preview
          _buildPreview(settings),
          const SizedBox(height: 16),

          // Settings sliders
          _buildSliderRow(
            label: '课程格高度',
            value: settings.courseCellHeight,
            min: GridSettings.minCellHeight,
            max: GridSettings.maxCellHeight,
            controller: _courseHeightController,
            onChanged: (value) {
              notifier.updateCourseCellHeight(value);
              _courseHeightController.text = value.toInt().toString();
            },
            onSubmitted: (text) {
              final value = double.tryParse(text);
              if (value != null) {
                notifier.updateCourseCellHeight(value);
              } else {
                _updateControllers(ref.read(gridSettingsProvider));
              }
            },
          ),
          const SizedBox(height: 12),

          _buildSliderRow(
            label: '空白格高度',
            value: settings.emptyCellHeight,
            min: GridSettings.minCellHeight,
            max: GridSettings.maxCellHeight,
            controller: _emptyHeightController,
            onChanged: (value) {
              notifier.updateEmptyCellHeight(value);
              _emptyHeightController.text = value.toInt().toString();
            },
            onSubmitted: (text) {
              final value = double.tryParse(text);
              if (value != null) {
                notifier.updateEmptyCellHeight(value);
              } else {
                _updateControllers(ref.read(gridSettingsProvider));
              }
            },
          ),
          const SizedBox(height: 12),

          _buildSliderRow(
            label: '格间距',
            value: settings.cellSpacing,
            min: GridSettings.minSpacing,
            max: GridSettings.maxSpacing,
            controller: _spacingController,
            onChanged: (value) {
              notifier.updateCellSpacing(value);
              _spacingController.text = value.toString();
            },
            onSubmitted: (text) {
              final value = double.tryParse(text);
              if (value != null) {
                notifier.updateCellSpacing(value);
              } else {
                _updateControllers(ref.read(gridSettingsProvider));
              }
            },
          ),
          const SizedBox(height: 12),

          _buildSliderRow(
            label: '节次列宽度',
            value: settings.periodColumnWidth,
            min: GridSettings.minColumnWidth,
            max: GridSettings.maxColumnWidth,
            controller: _periodWidthController,
            onChanged: (value) {
              notifier.updatePeriodColumnWidth(value);
              _periodWidthController.text = value.toInt().toString();
            },
            onSubmitted: (text) {
              final value = double.tryParse(text);
              if (value != null) {
                notifier.updatePeriodColumnWidth(value);
              } else {
                _updateControllers(ref.read(gridSettingsProvider));
              }
            },
          ),
          const SizedBox(height: 12),

          _buildSliderRow(
            label: '天数列宽度',
            value: settings.dayColumnWidth,
            min: GridSettings.minColumnWidth,
            max: GridSettings.maxColumnWidth,
            controller: _dayWidthController,
            onChanged: (value) {
              notifier.updateDayColumnWidth(value);
              _dayWidthController.text = value.toInt().toString();
            },
            onSubmitted: (text) {
              final value = double.tryParse(text);
              if (value != null) {
                notifier.updateDayColumnWidth(value);
              } else {
                _updateControllers(ref.read(gridSettingsProvider));
              }
            },
          ),
          const SizedBox(height: 16),

          // Reset button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                notifier.resetToDefaults();
                _updateControllers(GridSettings.defaultSettings);
              },
              child: const Text('重置为默认'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildPreview(GridSettings settings) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Period column
          Column(
            children: [
              _buildPreviewCell('', width: settings.periodColumnWidth, height: 20),
              ...List.generate(3, (i) => Padding(
                    padding: EdgeInsets.only(top: settings.cellSpacing),
                    child: _buildPreviewCell(
                      '${i + 1}',
                      width: settings.periodColumnWidth,
                      height: settings.emptyCellHeight * 0.5,
                    ),
                  )),
            ],
          ),
          // Day columns
          ...List.generate(3, (day) => Padding(
                padding: EdgeInsets.only(left: settings.cellSpacing),
                child: Column(
                  children: [
                    _buildPreviewCell(
                      ['一', '二', '三'][day],
                      width: settings.dayColumnWidth,
                      height: 20,
                    ),
                    ...List.generate(3, (i) => Padding(
                          padding: EdgeInsets.only(top: settings.cellSpacing),
                          child: _buildPreviewCell(
                            i == 1 ? '课程' : '',
                            width: settings.dayColumnWidth,
                            height: i == 1
                                ? settings.courseCellHeight * 0.5
                                : settings.emptyCellHeight * 0.5,
                            isCourse: i == 1,
                          ),
                        )),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPreviewCell(
    String text, {
    required double width,
    required double height,
    bool isCourse = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isCourse ? Colors.blue.shade300 : Colors.white,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: 8, color: isCourse ? Colors.white : Colors.black54),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required TextEditingController controller,
    required ValueChanged<double> onChanged,
    required ValueChanged<String> onSubmitted,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 60,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 12),
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(width: 4),
        const Text('px', style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

void showGridSettingsBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const GridSettingsBottomSheet(),
  );
}