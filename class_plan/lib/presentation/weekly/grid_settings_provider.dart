import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/model/grid_settings.dart';

const _gridSettingsPrefKey = 'grid_settings_config';

class GridSettingsNotifier extends StateNotifier<GridSettings> {
  GridSettingsNotifier() : super(GridSettings.defaultSettings) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_gridSettingsPrefKey);
    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        state = GridSettings.fromJson(json);
      } catch (_) {
        state = GridSettings.defaultSettings;
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(state.toJson());
    await prefs.setString(_gridSettingsPrefKey, jsonStr);
  }

  void updateCourseCellHeight(double value) {
    state = state.copyWith(
      courseCellHeight: value.clamp(
        GridSettings.minCellHeight,
        GridSettings.maxCellHeight,
      ),
    );
    _saveSettings();
  }

  void updateEmptyCellHeight(double value) {
    state = state.copyWith(
      emptyCellHeight: value.clamp(
        GridSettings.minCellHeight,
        GridSettings.maxCellHeight,
      ),
    );
    _saveSettings();
  }

  void updateCellSpacing(double value) {
    state = state.copyWith(
      cellSpacing: value.clamp(
        GridSettings.minSpacing,
        GridSettings.maxSpacing,
      ),
    );
    _saveSettings();
  }

  void updatePeriodColumnWidth(double value) {
    state = state.copyWith(
      periodColumnWidth: value.clamp(
        GridSettings.minColumnWidth,
        GridSettings.maxColumnWidth,
      ),
    );
    _saveSettings();
  }

  void updateDayColumnWidth(double value) {
    state = state.copyWith(
      dayColumnWidth: value.clamp(
        GridSettings.minColumnWidth,
        GridSettings.maxColumnWidth,
      ),
    );
    _saveSettings();
  }

  void resetToDefaults() {
    state = GridSettings.defaultSettings;
    _saveSettings();
  }
}

final gridSettingsProvider =
    StateNotifierProvider<GridSettingsNotifier, GridSettings>((ref) {
  return GridSettingsNotifier();
});