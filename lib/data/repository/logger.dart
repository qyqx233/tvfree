import 'dart:async';

import 'package:logger/logger.dart';

// 全局日志实例
class LogManager {
  final List<String> _logs = [];
  final StreamController<List<String>> _logStreamController =
      StreamController<List<String>>.broadcast();

  Stream<List<String>> get logStream => _logStreamController.stream;

  void addLog(String message) {
    _logs.add(message);
    _logStreamController.add(_logs);
  }

  void clearLogs() {
    _logs.clear();
    _logStreamController.add(_logs);
  }
}

final LogManager logManager = LogManager();

class CustomLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      // ignore: avoid_print
      print(line); // 输出到控制台
      logManager.addLog(line); // 添加到 LogManager
    }
  }
}

final Logger logger = Logger(
  printer: PrettyPrinter(),
  output: CustomLogOutput(),
);
