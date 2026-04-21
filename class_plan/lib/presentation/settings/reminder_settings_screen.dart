import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/notification/notification_service.dart';

/// 提醒设置页面
class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends ConsumerState<ReminderSettingsScreen> {
  bool _remindersEnabled = false;
  int _minutesBefore = 10;
  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final service = ReminderService();
    await service.initialize();

    setState(() {
      _remindersEnabled = prefs.getBool('reminders_enabled') ?? false;
      _minutesBefore = prefs.getInt('reminder_minutes_before') ?? 10;
    });
  }

  void _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', _remindersEnabled);
    await prefs.setInt('reminder_minutes_before', _minutesBefore);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课程提醒'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('开启上课提醒'),
            subtitle: const Text('在课程开始前发送通知'),
            value: _remindersEnabled,
            onChanged: (value) async {
              if (value && !_permissionGranted) {
                final granted = await ReminderService().requestPermission();
                if (!granted) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请在系统设置中开启通知权限')),
                    );
                  }
                  return;
                }
                _permissionGranted = true;
              }
              setState(() {
                _remindersEnabled = value;
              });
              _saveSettings();
            },
          ),
          const Divider(),
          if (_remindersEnabled) ...[
            ListTile(
              title: const Text('提前提醒时间'),
              subtitle: Text('课程开始前 $_minutesBefore 分钟'),
              trailing: DropdownButton<int>(
                value: _minutesBefore,
                items: [5, 10, 15, 20, 30, 60]
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('$m 分钟'),
                          ))
                      .toList(),
                onChanged: (v) {
                  setState(() => _minutesBefore = v!);
                  _saveSettings();
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '提醒会在每次打开应用时自动根据当前周次安排更新。'
                          '如果课程时间有调整，重新打开应用即可更新提醒。',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
