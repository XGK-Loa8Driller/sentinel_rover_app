import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/mission_log_service.dart';
import '../services/system_status_service.dart';

class SystemModeSelector extends StatelessWidget {
  const SystemModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Get.find<AuthService>();
    final MissionLogService logService = Get.find<MissionLogService>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00F5FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SYSTEM MODE',
                style: GoogleFonts.orbitron(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const Icon(
                Icons.settings_input_composite,
                color: Color(0xFF00F5FF),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildModeChip(
                SystemMode.surveillance,
                '🔍 SURVEILLANCE',
                'Monitor and track',
                const Color(0xFF00F5FF),
                authService,
                logService,
              ),
              _buildModeChip(
                SystemMode.defense,
                '⚔️ DEFENSE',
                'Active protection',
                const Color(0xFFFF3366),
                authService,
                logService,
              ),
              _buildModeChip(
                SystemMode.manual,
                '🎮 MANUAL',
                'Direct control',
                const Color(0xFFFF9500),
                authService,
                logService,
              ),
              _buildModeChip(
                SystemMode.patrol,
                '🚁 PATROL',
                'Autonomous sweep',
                const Color(0xFF00FF88),
                authService,
                logService,
              ),
              _buildModeChip(
                SystemMode.standby,
                '⏸️ STANDBY',
                'System idle',
                Colors.white60,
                authService,
                logService,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Mode description
          Obx(
            () => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getModeColor(
                  authService.systemMode.value,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getModeColor(
                    authService.systemMode.value,
                  ).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getModeDescription(authService.systemMode.value),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: _getModeColor(authService.systemMode.value),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getModeFeatures(authService.systemMode.value),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(
    SystemMode mode,
    String label,
    String subtitle,
    Color color,
    AuthService authService,
    MissionLogService logService,
  ) {
    return Obx(() {
      final isSelected = authService.systemMode.value == mode;

      return InkWell(
        onTap: () {
          if (authService.hasPermission('change_mode')) {
            authService.changeSystemMode(mode);
          } else {
            final status = Get.find<SystemStatusService>();
            status.show(
              'Insufficient permissions to change system mode',
              StatusType.warning,
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.white24,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.white60,
                  letterSpacing: 1,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 8,
                  color: isSelected
                      ? color.withOpacity(0.7)
                      : Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Color _getModeColor(SystemMode mode) {
    switch (mode) {
      case SystemMode.surveillance:
        return const Color(0xFF00F5FF);
      case SystemMode.defense:
        return const Color(0xFFFF3366);
      case SystemMode.manual:
        return const Color(0xFFFF9500);
      case SystemMode.patrol:
        return const Color(0xFF00FF88);
      default:
        return Colors.white60;
    }
  }

  String _getModeDescription(SystemMode mode) {
    switch (mode) {
      case SystemMode.surveillance:
        return 'Passive monitoring mode. Camera active, weapons safe. Ideal for threat detection and tracking.';
      case SystemMode.defense:
        return 'Active defense mode. Laser armed, auto-engagement enabled for verified threats.';
      case SystemMode.manual:
        return 'Direct operator control. All systems manual, autonomous features disabled.';
      case SystemMode.patrol:
        return 'Autonomous patrol mode. AI-driven navigation and threat scanning.';
      default:
        return 'System idle. All active features disabled, minimal power consumption.';
    }
  }

  String _getModeFeatures(SystemMode mode) {
    switch (mode) {
      case SystemMode.surveillance:
        return 'Camera: ON • Laser: SAFE • Autonomous: OFF';
      case SystemMode.defense:
        return 'Camera: ON • Laser: ARMED • Autonomous: ON';
      case SystemMode.manual:
        return 'Camera: ON • Laser: MANUAL • Autonomous: OFF';
      case SystemMode.patrol:
        return 'Camera: ON • Laser: SAFE • Autonomous: ON';
      default:
        return 'All systems: STANDBY';
    }
  }
}
