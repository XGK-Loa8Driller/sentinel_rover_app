import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../services/websocket_service.dart';
import 'dart:math' as math;

class DroneDetection {
  final String id;
  final Rect boundingBox; // Normalized coordinates (0-1)
  final double confidence;
  final String classification;
  final DateTime timestamp;

  DroneDetection({
    required this.id,
    required this.boundingBox,
    required this.confidence,
    required this.classification,
    required this.timestamp,
  });
}

class CameraOverlayWidget extends StatefulWidget {
  final Widget cameraFeed;
  
  const CameraOverlayWidget({
    super.key,
    required this.cameraFeed,
  });

  @override
  State<CameraOverlayWidget> createState() => _CameraOverlayWidgetState();
}

class _CameraOverlayWidgetState extends State<CameraOverlayWidget> {
  final WebSocketService _wsService = Get.find<WebSocketService>();
  
  // Simulated detections (in production, this comes from YOLO via WebSocket)
  var detections = <DroneDetection>[].obs;

  @override
  void initState() {
    super.initState();
    _listenForDetections();
    _simulateDetections(); // Remove this in production
  }

  void _listenForDetections() {
    // Listen for drone_detected events from Jetson
    _wsService.socket.on('drone_detected', (data) {
      final detection = DroneDetection(
        id: data['id'] ?? '',
        boundingBox: Rect.fromLTWH(
          (data['bbox']?['x'] ?? 0).toDouble(),
          (data['bbox']?['y'] ?? 0).toDouble(),
          (data['bbox']?['width'] ?? 0).toDouble(),
          (data['bbox']?['height'] ?? 0).toDouble(),
        ),
        confidence: (data['confidence'] ?? 0.0).toDouble(),
        classification: data['classification'] ?? 'unknown',
        timestamp: DateTime.now(),
      );
      
      setState(() {
        detections.add(detection);
        // Remove old detections after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          detections.removeWhere((d) => d.id == detection.id);
        });
      });
    });
  }

  void _simulateDetections() {
    // Simulate detection for demo (remove in production)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && math.Random().nextDouble() > 0.5) {
        final detection = DroneDetection(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          boundingBox: Rect.fromLTWH(
            0.2 + math.Random().nextDouble() * 0.4,
            0.2 + math.Random().nextDouble() * 0.4,
            0.15 + math.Random().nextDouble() * 0.1,
            0.15 + math.Random().nextDouble() * 0.1,
          ),
          confidence: 0.75 + math.Random().nextDouble() * 0.24,
          classification: 'DJI-type',
          timestamp: DateTime.now(),
        );
        setState(() => detections.add(detection));
        Future.delayed(const Duration(seconds: 3), () {
          detections.removeWhere((d) => d.id == detection.id);
        });
      }
      _simulateDetections();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera feed
        widget.cameraFeed,
        
        // Tactical overlay
        Positioned.fill(
          child: CustomPaint(
            painter: TacticalOverlayPainter(detections: detections),
          ),
        ),
        
        // Bounding boxes and labels
        ...detections.map((detection) => 
          _buildBoundingBox(context, detection)
        ).toList(),
        
        // HUD Elements
        _buildTopHUD(),
        _buildCrosshair(),
        _buildBottomHUD(),
      ],
    );
  }

  Widget _buildBoundingBox(BuildContext context, DroneDetection detection) {
    final size = MediaQuery.of(context).size;
    final left = detection.boundingBox.left * size.width;
    final top = detection.boundingBox.top * size.height;
    final width = detection.boundingBox.width * size.width;
    final height = detection.boundingBox.height * size.height;

    final color = detection.confidence > 0.9
        ? const Color(0xFFFF3366)
        : const Color(0xFFFF9500);

    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: color,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Corner brackets
            ..._buildCornerBrackets(color, width, height),
            
            // Label
            Positioned(
              top: -24,
              left: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${detection.classification.toUpperCase()} ${(detection.confidence * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            
            // Lock indicator
            Center(
              child: Icon(
                Icons.gps_fixed,
                color: color,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCornerBrackets(Color color, double width, double height) {
    final bracketSize = 12.0;
    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: bracketSize,
          height: 2,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: 2,
          height: bracketSize,
          color: color,
        ),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: bracketSize,
          height: 2,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: 2,
          height: bracketSize,
          color: color,
        ),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: bracketSize,
          height: 2,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: 2,
          height: bracketSize,
          color: color,
        ),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: bracketSize,
          height: 2,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: 2,
          height: bracketSize,
          color: color,
        ),
      ),
    ];
  }

  Widget _buildTopHUD() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHUDInfo('REC', Icons.fiber_manual_record, const Color(0xFFFF3366)),
          _buildHUDInfo('${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}', Icons.access_time, Colors.white),
          _buildHUDInfo('FHD 30', Icons.videocam, const Color(0xFF00F5FF)),
        ],
      ),
    );
  }

  Widget _buildHUDInfo(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrosshair() {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CustomPaint(
          painter: CrosshairPainter(),
        ),
      ),
    );
  }

  Widget _buildBottomHUD() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHUDInfo(
            'TARGETS: ${detections.length}',
            Icons.track_changes,
            detections.isEmpty ? Colors.white : const Color(0xFFFF3366),
          ),
          _buildHUDInfo(
            'ZOOM: 1.0x',
            Icons.zoom_in,
            const Color(0xFF00F5FF),
          ),
        ],
      )),
    );
  }
}

class TacticalOverlayPainter extends CustomPainter {
  final List<DroneDetection> detections;

  TacticalOverlayPainter({required this.detections});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.3)
      ..strokeWidth = 1;

    // Grid lines
    final gridSpacing = size.width / 8;
    for (double i = gridSpacing; i < size.width; i += gridSpacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = gridSpacing; i < size.height; i += gridSpacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Vignette effect
    final vignetteGradient = RadialGradient(
      colors: [
        Colors.transparent,
        Colors.black.withOpacity(0.4),
      ],
      stops: const [0.6, 1.0],
    );

    final vignettePaint = Paint()
      ..shader = vignetteGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF88)
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final length = size.width / 3;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - length, center.dy),
      Offset(center.dx + length, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - length),
      Offset(center.dx, center.dy + length),
      paint,
    );

    // Center dot
    canvas.drawCircle(center, 3, paint);
    
    // Outer circle
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(center, size.width / 2.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
