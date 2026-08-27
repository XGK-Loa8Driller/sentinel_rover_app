import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../services/websocket_service.dart';

class ThreatMap extends StatelessWidget {
  const ThreatMap({super.key});

  @override
  Widget build(BuildContext context) {
    final WebSocketService wsService = Get.find<WebSocketService>();

    return Container(
      color: const Color(0xFF0A0E17),
      child: Stack(
        children: [
          // Map background (simulated)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  const Color(0xFF1A2235).withOpacity(0.5),
                  const Color(0xFF0A0E17),
                ],
              ),
            ),
            child: CustomPaint(
              painter: GridPainter(),
              size: Size.infinite,
            ),
          ),
          
          // Rover position (center)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF00F5FF),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F5FF).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.precision_manufacturing,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5FF).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF00F5FF),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'SENTINEL ROVER',
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
          ),
          
          // Threat markers
          Obx(() => Stack(
            children: wsService.recentThreats.asMap().entries.map((entry) {
              int index = entry.key;
              var threat = entry.value;
              
              // Calculate position based on distance and angle
              double angle = (index * 60) * (3.14159 / 180);
              double distance = threat.distance / 5; // Scale for display
              
              double left = (MediaQuery.of(context).size.width / 2) + 
                           (distance * cos(angle)) - 20;
              double top = (MediaQuery.of(context).size.height / 2) + 
                          (distance * sin(angle)) - 20;
              
              return Positioned(
                left: left,
                top: top,
                child: _buildThreatMarker(threat.severity),
              );
            }).toList(),
          )),
          
          // Map legend
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151B2B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white10,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LEGEND',
                    style: GoogleFonts.orbitron(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem('Rover', const Color(0xFF00F5FF)),
                  _buildLegendItem('Critical', const Color(0xFFFF3366)),
                  _buildLegendItem('High', const Color(0xFFFF9500)),
                  _buildLegendItem('Medium', const Color(0xFFFFCC00)),
                ],
              ),
            ),
          ),
          
          // Coordinates overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Obx(() => Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF151B2B).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white10,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: const Color(0xFF00F5FF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CURRENT POSITION',
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${wsService.latitude.value.toStringAsFixed(6)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Lng: ${wsService.longitude.value.toStringAsFixed(6)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildThreatMarker(String severity) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'critical':
        color = const Color(0xFFFF3366);
        break;
      case 'high':
        color = const Color(0xFFFF9500);
        break;
      default:
        color = const Color(0xFFFFCC00);
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: const Icon(
        Icons.warning,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  double cos(double angle) => angle.cos();
  double sin(double angle) => angle.sin();
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

extension on double {
  double cos() => this * 0.5; // Simplified for demo
  double sin() => this * 0.5; // Simplified for demo
}
