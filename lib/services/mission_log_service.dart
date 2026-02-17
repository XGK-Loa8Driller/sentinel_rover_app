import 'package:get/get.dart';

enum LogLevel { info, warning, critical, success }

class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? data;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.message,
    this.data,
  });

  String get timeString {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}:'
           '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

class MissionLogService extends GetxController {
  var logs = <LogEntry>[].obs;
  var maxLogs = 500.obs; // Keep last 500 entries
  var sessionStartTime = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    log('Mission log system initialized', LogLevel.info);
    log('Sentinel Rover Defense System online', LogLevel.success);
  }

  void log(String message, LogLevel level, [Map<String, dynamic>? data]) {
    final entry = LogEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: level,
      message: message,
      data: data,
    );

    logs.insert(0, entry); // Add to beginning

    // Maintain max log size
    if (logs.length > maxLogs.value) {
      logs.removeLast();
    }

    // Print to console in debug mode
    print('[${entry.timeString}] [${level.name.toUpperCase()}] $message');
  }

  void logDroneDetection(double confidence, double distance, String severity) {
    log(
      'Drone detected (${(confidence * 100).toStringAsFixed(0)}%) at ${distance.toStringAsFixed(0)}m',
      severity == 'critical' ? LogLevel.critical : LogLevel.warning,
      {
        'type': 'drone_detection',
        'confidence': confidence,
        'distance': distance,
        'severity': severity,
      },
    );
  }

  void logLaserFire(String targetId) {
    log(
      'Laser engaged - Target: $targetId',
      LogLevel.critical,
      {'type': 'laser_fire', 'target_id': targetId},
    );
  }

  void logThreatNeutralized(String targetId) {
    log(
      'Threat neutralized - Target: $targetId',
      LogLevel.success,
      {'type': 'neutralized', 'target_id': targetId},
    );
  }

  void logConnectionChange(String from, String to) {
    log(
      'Connection switched: $from → $to',
      LogLevel.info,
      {'type': 'connection_change', 'from': from, 'to': to},
    );
  }

  void logSystemWarning(String message) {
    log(message, LogLevel.warning, {'type': 'system_warning'});
  }

  void logEmergencyAlert(String message) {
    log(message, LogLevel.critical, {'type': 'emergency'});
  }

  List<LogEntry> getLogsByLevel(LogLevel level) {
    return logs.where((entry) => entry.level == level).toList();
  }

  List<LogEntry> getLogsInTimeRange(DateTime start, DateTime end) {
    return logs.where((entry) => 
      entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end)
    ).toList();
  }

  void clearLogs() {
    logs.clear();
    log('Mission logs cleared', LogLevel.info);
  }

  String exportLogsAsText() {
    final buffer = StringBuffer();
    buffer.writeln('SENTINEL ROVER MISSION LOG');
    buffer.writeln('Session Start: ${sessionStartTime.value}');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Total Entries: ${logs.length}');
    buffer.writeln('${'=' * 60}');
    
    for (var entry in logs.reversed) {
      buffer.writeln('[${entry.timeString}] [${entry.level.name.toUpperCase()}] ${entry.message}');
    }
    
    return buffer.toString();
  }

  int get criticalCount => logs.where((e) => e.level == LogLevel.critical).length;
  int get warningCount => logs.where((e) => e.level == LogLevel.warning).length;
  int get infoCount => logs.where((e) => e.level == LogLevel.info).length;
}
