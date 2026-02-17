import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../services/websocket_service.dart';
import '../services/connectivity_manager.dart';
import '../services/auth_service.dart';

class EnhancedTelemetryDashboard extends StatelessWidget {
  const EnhancedTelemetryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final WebSocketService wsService = Get.find<WebSocketService>();
    final ConnectivityManager connManager = Get.find<ConnectivityManager>();
    final AuthService authService = Get.find<AuthService>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF151B2B),
            const Color(0xFF1A2235),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
                'TELEMETRY',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(wsService.roverStatus.value).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(wsService.roverStatus.value),
                    width: 1,
                  ),
                ),
                child: Text(
                  wsService.roverStatus.value,
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(wsService.roverStatus.value),
                    letterSpacing: 1,
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 20),
          
          // Primary Metrics Row
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildMetricCard(
                  'BATTERY',
                  '${wsService.batteryLevel.value}%',
                  Icons.battery_charging_full,
                  _getBatteryColor(wsService.batteryLevel.value),
                  wsService.batteryLevel.value / 100,
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildMetricCard(
                  'SPEED',
                  '${(wsService.distanceTraveled.value / 3600).toStringAsFixed(1)} m/s',
                  Icons.speed,
                  const Color(0xFF00F5FF),
                  null,
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Secondary Metrics Row
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildMetricCard(
                  'LATENCY',
                  '${connManager.latency.value}ms',
                  Icons.network_check,
                  _getLatencyColor(connManager.latency.value),
                  null,
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildMetricCard(
                  'MODE',
                  authService.systemMode.value.name.toUpperCase(),
                  Icons.settings_input_composite,
                  _getModeColor(authService.systemMode.value),
                  null,
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // System Health Indicators
          Row(
            children: [
              Expanded(
                child: _buildIndicatorCard(
                  'CPU',
                  '42%',
                  const Color(0xFF00F5FF),
                  0.42,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildIndicatorCard(
                  'TEMP',
                  '45°C',
                  const Color(0xFFFF9500),
                  0.56,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => _buildIndicatorCard(
                  'SIGNAL',
                  '${connManager.signalStrength.value}%',
                  const Color(0xFF00FF88),
                  connManager.signalStrength.value / 100,
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Laser Status
          Obx(() => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: authService.isLaserEnabled.value
                  ? const Color(0xFFFF3366).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: authService.isLaserEnabled.value
                    ? const Color(0xFFFF3366)
                    : Colors.white24,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: authService.isLaserEnabled.value
                          ? const Color(0xFFFF3366)
                          : Colors.white60,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LASER SYSTEM',
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: authService.isLaserEnabled.value
                        ? const Color(0xFFFF3366)
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    authService.isLaserEnabled.value ? 'ARMED' : 'SAFE',
                    style: GoogleFonts.orbitron(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
    double? progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (progress != null)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white60,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard(
    String label,
    String value,
    Color color,
    double progress,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.white60,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                value,
                style: GoogleFonts.orbitron(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF00FF88);
      case 'standby':
        return const Color(0xFF00F5FF);
      case 'offline':
        return const Color(0xFFFF3366);
      default:
        return Colors.white;
    }
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return const Color(0xFF00FF88);
    if (level > 20) return const Color(0xFFFF9500);
    return const Color(0xFFFF3366);
  }

  Color _getLatencyColor(int latency) {
    if (latency < 50) return const Color(0xFF00FF88);
    if (latency < 150) return const Color(0xFFFF9500);
    return const Color(0xFFFF3366);
  }

  Color _getModeColor(SystemMode mode) {
    switch (mode) {
      case SystemMode.defense:
        return const Color(0xFFFF3366);
      case SystemMode.surveillance:
        return const Color(0xFF00F5FF);
      case SystemMode.manual:
        return const Color(0xFFFF9500);
      case SystemMode.patrol:
        return const Color(0xFF00FF88);
      default:
        return Colors.white;
    }
  }
}
