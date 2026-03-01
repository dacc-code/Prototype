import 'package:flutter/foundation.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;

  LogService._internal();

  final ValueNotifier<List<String>> logs = ValueNotifier<List<String>>([]);

  void addLog(String message) {
    debugPrint(message); // Still print to real console
    final timestamp =
        DateTime.now().toIso8601String().split('T')[1].substring(0, 8);
    final logMessage = '[$timestamp] $message';

    // Add to top of the list and keep only last 50 logs
    final currentLogs = List<String>.from(logs.value);
    currentLogs.insert(0, logMessage);
    if (currentLogs.length > 50) {
      currentLogs.removeLast();
    }

    logs.value = currentLogs;
  }

  void clear() {
    logs.value = [];
  }
}

// Global helper for easy logging
final logger = LogService();
