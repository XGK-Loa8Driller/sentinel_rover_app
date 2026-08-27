import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../services/mission_log_service.dart';
import '../services/system_status_service.dart';

class MissionLogScreen extends StatefulWidget {
  const MissionLogScreen({super.key});

  @override
  State<MissionLogScreen> createState() => _MissionLogScreenState();
}

class _MissionLogScreenState extends State<MissionLogScreen> {
  final MissionLogService _logService = Get.find<MissionLogService>();
  LogLevel? _filterLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B2B),
        title: Text(
          'MISSION LOG',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportLogs),
        ],
      ),
      body: Column(
        children: [
          _buildStatsBar(),
          _buildFilterChips(),
          Expanded(child: _buildLogList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _logService.clearLogs();
          final status = Get.find<SystemStatusService>();
          status.show('🗑 Mission log has been reset', StatusType.success);
        },
        backgroundColor: const Color(0xFFFF3366),
        child: const Icon(Icons.delete_sweep),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF151B2B),
          border: Border(
            bottom: BorderSide(
              color: const Color(0xFF00F5FF).withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'TOTAL',
              _logService.logs.length.toString(),
              const Color(0xFF00F5FF),
            ),
            _buildStatItem(
              'CRITICAL',
              _logService.criticalCount.toString(),
              const Color(0xFFFF3366),
            ),
            _buildStatItem(
              'WARNING',
              _logService.warningCount.toString(),
              const Color(0xFFFF9500),
            ),
            _buildStatItem(
              'INFO',
              _logService.infoCount.toString(),
              const Color(0xFF00FF88),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white60,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('ALL', null),
            const SizedBox(width: 8),
            _buildFilterChip('CRITICAL', LogLevel.critical),
            const SizedBox(width: 8),
            _buildFilterChip('WARNING', LogLevel.warning),
            const SizedBox(width: 8),
            _buildFilterChip('INFO', LogLevel.info),
            const SizedBox(width: 8),
            _buildFilterChip('SUCCESS', LogLevel.success),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, LogLevel? level) {
    final isSelected = _filterLevel == level;

    return FilterChip(
      label: Text(
        label,
        style: GoogleFonts.orbitron(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : Colors.white70,
          letterSpacing: 1,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterLevel = selected ? level : null;
        });
      },
      backgroundColor: const Color(0xFF151B2B),
      selectedColor: const Color(0xFF00F5FF),
      checkmarkColor: Colors.black,
      side: BorderSide(
        color: const Color(0xFF00F5FF).withOpacity(0.3),
        width: 1,
      ),
    );
  }

  Widget _buildLogList() {
    return Obx(() {
      var filteredLogs = _filterLevel == null
          ? _logService.logs
          : _logService.logs.where((log) => log.level == _filterLevel).toList();

      if (filteredLogs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description_outlined,
                  size: 80, color: Colors.white30),
              const SizedBox(height: 16),
              Text(
                'NO LOG ENTRIES',
                style: GoogleFonts.orbitron(
                  fontSize: 16,
                  color: Colors.white30,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredLogs.length,
        itemBuilder: (context, index) {
          final log = filteredLogs[index];
          return _buildLogEntry(log);
        },
      );
    });
  }

  Widget _buildLogEntry(LogEntry log) {
    Color levelColor;
    IconData levelIcon;

    switch (log.level) {
      case LogLevel.critical:
        levelColor = const Color(0xFFFF3366);
        levelIcon = Icons.error;
        break;
      case LogLevel.warning:
        levelColor = const Color(0xFFFF9500);
        levelIcon = Icons.warning_amber;
        break;
      case LogLevel.success:
        levelColor = const Color(0xFF00FF88);
        levelIcon = Icons.check_circle;
        break;
      default:
        levelColor = const Color(0xFF00F5FF);
        levelIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: levelColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(levelIcon, color: levelColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.timeString,
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: levelColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: levelColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.level.name.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  log.message,
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                ),
                if (log.data != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Data: ${log.data}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterMenu() {
    // Show filter options
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF151B2B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FILTER OPTIONS',
              style: GoogleFonts.orbitron(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            // Filter options here
          ],
        ),
      ),
    );
  }

  void _exportLogs() {
    final logsText = _logService.exportLogsAsText();
    Clipboard.setData(ClipboardData(text: logsText));

    final status = Get.find<SystemStatusService>();
    status.show('📋 Mission log copied to clipboard', StatusType.success);
  }
}
