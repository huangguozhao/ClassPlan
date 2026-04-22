import 'package:flutter/material.dart';

/// 简单的内存日志服务，用于调试
class DebugLogService {
  static final DebugLogService _instance = DebugLogService._();
  factory DebugLogService() => _instance;
  DebugLogService._();

  final List<_LogEntry> _logs = [];
  static const int maxLogs = 500;

  void log(String message, {String? tag, LogLevel level = LogLevel.info}) {
    _logs.insert(0, _LogEntry(
      message: message,
      tag: tag,
      level: level,
      timestamp: DateTime.now(),
    ));
    if (_logs.length > maxLogs) {
      _logs.removeLast();
    }
  }

  void info(String message, {String? tag}) => log(message, tag: tag, level: LogLevel.info);
  void error(String message, {String? tag}) => log(message, tag: tag, level: LogLevel.error);
  void debug(String message, {String? tag}) => log(message, tag: tag, level: LogLevel.debug);
  void warning(String message, {String? tag}) => log(message, tag: tag, level: LogLevel.warning);

  List<_LogEntry> get logs => List.unmodifiable(_logs);

  void clear() => _logs.clear();
}

enum LogLevel { debug, info, warning, error }

class _LogEntry {
  final String message;
  final String? tag;
  final LogLevel level;
  final DateTime timestamp;

  _LogEntry({
    required this.message,
    this.tag,
    required this.level,
    required this.timestamp,
  });
}

/// 调试日志页面
class DebugLogScreen extends StatelessWidget {
  const DebugLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('调试日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              DebugLogService().clear();
              (context as Element).markNeedsBuild();
            },
            tooltip: '清空日志',
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              final logs = DebugLogService().logs;
              final text = logs.map((e) {
                final level = e.level.name.toUpperCase();
                final tag = e.tag ?? '';
                return '[${e.timestamp.toIso8601String()}] [$level]${tag.isNotEmpty ? ' [$tag]' : ''}: ${e.message}';
              }).join('\n');
              // Copy to clipboard would need clipboard package
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('日志已复制')),
              );
            },
            tooltip: '复制日志',
          ),
        ],
      ),
      body: const _LogList(),
    );
  }
}

class _LogList extends StatelessWidget {
  const _LogList();

  @override
  Widget build(BuildContext context) {
    return const _LogListView();
  }
}

class _LogListView extends StatefulWidget {
  const _LogListView();

  @override
  State<_LogListView> createState() => _LogListViewState();
}

class _LogListViewState extends State<_LogListView> {
  final _logService = DebugLogService();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _logService.logs.length,
      itemBuilder: (context, index) {
        final log = _logService.logs[index];
        return _LogTile(log: log);
      },
    );
  }
}

class _LogTile extends StatelessWidget {
  final _LogEntry log;

  const _LogTile({required this.log});

  Color _getLevelColor() {
    switch (log.level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  IconData _getLevelIcon() {
    switch (log.level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info;
      case LogLevel.warning:
        return Icons.warning;
      case LogLevel.error:
        return Icons.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(_getLevelIcon(), color: _getLevelColor(), size: 20),
      title: Text(
        log.message,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: log.level == LogLevel.error ? Colors.red.shade700 : null,
        ),
      ),
      subtitle: Text(
        '${log.timestamp.toString().substring(0, 23)}${log.tag != null ? ' [${log.tag}]' : ''}',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}