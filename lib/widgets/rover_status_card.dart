import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../services/websocket_service.dart';

class RoverStatusCard extends StatelessWidget {
  const RoverStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final WebSocketService wsService = Get.find<WebSocketService>();

    return Obx(
      () => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF151B2B), const Color(0xFF1A2235)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF00F5FF).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00F5FF).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: wsService.roverStatus.value == 'ACTIVE'
                                ? const Color(0xFF00FF88)
                                : const Color(0xFFFF3366),
                            boxShadow: [
                              BoxShadow(
                                color: wsService.roverStatus.value == 'ACTIVE'
                                    ? const Color(0xFF00FF88)
                                    : const Color(0xFFFF3366),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .fadeOut(duration: 1000.ms)
                        .then()
                        .fadeIn(duration: 1000.ms),
                    const SizedBox(width: 12),
                    Text(
                      wsService.roverStatus.value,
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.precision_manufacturing,
                  color: const Color(0xFF00F5FF),
                  size: 32,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'BATTERY',
                    '${wsService.batteryLevel.value}%',
                    Icons.battery_charging_full,
                    wsService.batteryLevel.value > 20
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF3366),
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    'LASER',
                    wsService.laserStatus.value,
                    Icons.flash_on,
                    wsService.laserStatus.value == 'READY'
                        ? const Color(0xFF00FF88)
                        : const Color(0xFFFF9500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'POSITION',
                    '${wsService.latitude.value.toStringAsFixed(4)}, ${wsService.longitude.value.toStringAsFixed(4)}',
                    Icons.location_on,
                    const Color(0xFF00F5FF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    'DISTANCE',
                    wsService.distanceTraveled.value >= 1000
                        ? '${(wsService.distanceTraveled.value / 1000).toStringAsFixed(2)} km'
                        : '${wsService.distanceTraveled.value.toStringAsFixed(0)} m',
                    Icons.route,
                    const Color(0xFFFFCC00),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF00F5FF),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last updated: ${DateTime.now().toString().substring(11, 19)}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
