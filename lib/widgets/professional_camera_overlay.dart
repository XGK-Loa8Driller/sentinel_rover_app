import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../services/rover_state_controller.dart';
import '../services/secure_communication_protocol.dart';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../services/system_status_service.dart';

/// L5 - PROFESSIONAL CAMERA OVERLAY
/// Defense-grade camera interface with:
/// - YOLO bounding box rendering
/// - Target tracking lock
/// - Distance estimation
/// - Confidence display
/// - Tactical reticle
/// - Audio alert on lock
/// - Timestamp overlay

class DroneDetection {
  final String id;
  final Rect boundingBox; // Normalized 0-1
  final double confidence;
  final String classification;
  final double distance; // meters
  final bool isTracked;
  final DateTime timestamp;

  DroneDetection({
    required this.id,
    required this.boundingBox,
    required this.confidence,
    required this.classification,
    required this.distance,
    this.isTracked = false,
    required this.timestamp,
  });

  factory DroneDetection.fromJson(Map<String, dynamic> json) {
    return DroneDetection(
      id: json['id'] ?? '',
      boundingBox: Rect.fromLTWH(
        (json['bbox']?['x'] ?? 0).toDouble(),
        (json['bbox']?['y'] ?? 0).toDouble(),
        (json['bbox']?['width'] ?? 0).toDouble(),
        (json['bbox']?['height'] ?? 0).toDouble(),
      ),
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      classification: json['classification'] ?? 'unknown',
      distance: (json['distance'] ?? 0.0).toDouble(),
      timestamp: DateTime.now(),
    );
  }
}

class ProfessionalCameraOverlay extends StatefulWidget {
  final Widget cameraFeed;

  const ProfessionalCameraOverlay({
    super.key,
    required this.cameraFeed,
  });

  @override
  State<ProfessionalCameraOverlay> createState() =>
      _ProfessionalCameraOverlayState();
}

class _ProfessionalCameraOverlayState extends State<ProfessionalCameraOverlay>
    with SingleTickerProviderStateMixin {
  final RoverStateController _rover = Get.find<RoverStateController>();
  final SecureCommunicationProtocol _comm =
      Get.find<SecureCommunicationProtocol>();

  var detections = <DroneDetection>[].obs;
  var trackedTarget = Rx<DroneDetection?>(null);
  var trackingLocked = false.obs;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation for locked target
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _listenForDetections();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================================
  // YOLO DETECTION LISTENER
  // ============================================================================

  void _listenForDetections() {
    // Listen for real-time YOLO detections from Jetson
    _comm.socket.on('drone_detected', (data) {
      _handleDroneDetection(data);
    });

    // Listen for tracking updates
    _comm.socket.on('tracking_update', (data) {
      _handleTrackingUpdate(data);
    });

    // Simulate detections for demo (REMOVE IN PRODUCTION)
    _simulateDetections();
  }

  void _handleDroneDetection(dynamic data) {
    final detection = DroneDetection.fromJson(data);

    // Add to detections list
    setState(() {
      detections.removeWhere((d) => d.id == detection.id);
      detections.add(detection);
    });

    // Auto-remove after 3 seconds if no update
    Future.delayed(const Duration(seconds: 3), () {
      detections.removeWhere((d) => d.id == detection.id);
    });
  }

  void _handleTrackingUpdate(dynamic data) {
    final targetId = data['target_id'];
    final locked = data['locked'] ?? false;

    trackingLocked.value = locked;
    _rover.trackingLocked.value = locked;
    _rover.trackingTarget.value = locked ? targetId : null;

    if (locked) {
      // Play alert sound
      _playLockAlert();

      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Update tracked target
      trackedTarget.value = detections.firstWhere(
        (d) => d.id == targetId,
        orElse: () => detections.first,
      );
    } else {
      trackedTarget.value = null;
    }
  }

  void _playLockAlert() {
    // In production, play actual alert sound
    print('[CAMERA] 🎯 TRACKING LOCK ACHIEVED');
  }

  // ============================================================================
  // SIMULATION (REMOVE IN PRODUCTION)
  // ============================================================================

  void _simulateDetections() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && math.Random().nextDouble() > 0.4) {
        final detection = DroneDetection(
          id: 'sim_${DateTime.now().millisecondsSinceEpoch}',
          boundingBox: Rect.fromLTWH(
            0.2 + math.Random().nextDouble() * 0.4,
            0.2 + math.Random().nextDouble() * 0.4,
            0.12 + math.Random().nextDouble() * 0.08,
            0.12 + math.Random().nextDouble() * 0.08,
          ),
          confidence: 0.75 + math.Random().nextDouble() * 0.24,
          classification: [
            'DJI Phantom',
            'Mavic',
            'Unknown UAV'
          ][math.Random().nextInt(3)],
          distance: 50 + math.Random().nextDouble() * 200,
          timestamp: DateTime.now(),
        );

        setState(() => detections.add(detection));

        Future.delayed(const Duration(seconds: 4), () {
          detections.removeWhere((d) => d.id == detection.id);
        });
      }
      _simulateDetections();
    });
  }

  // ============================================================================
  // UI BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera feed
        widget.cameraFeed,

        // Tactical grid overlay
        Positioned.fill(
          child: CustomPaint(
            painter: TacticalGridPainter(),
          ),
        ),

        // Bounding boxes
        ...detections.map((detection) => _buildBoundingBox(context, detection)),

        // Central reticle
        _buildCentralReticle(),

        // Top HUD
        _buildTopHUD(),

        // Bottom HUD
        _buildBottomHUD(),

        // Lock status
        Obx(() => trackingLocked.value
            ? _buildLockIndicator()
            : const SizedBox.shrink()),
      ],
    );
  }

  // ============================================================================
  // BOUNDING BOX RENDERING
  // ============================================================================

  Widget _buildBoundingBox(BuildContext context, DroneDetection detection) {
    final size = MediaQuery.of(context).size;
    final left = detection.boundingBox.left * size.width;
    final top = detection.boundingBox.top * size.height;
    final width = detection.boundingBox.width * size.width;
    final height = detection.boundingBox.height * size.height;

    final isTracked = trackedTarget.value?.id == detection.id;
    final color = isTracked
        ? const Color(0xFFFF3366) // Red for tracked
        : (detection.confidence > 0.9
            ? const Color(0xFFFF9500) // Orange for high confidence
            : const Color(0xFFFFCC00)); // Yellow for medium confidence

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => _engageTracking(detection),
        child: AnimatedBuilder(
          animation:
              isTracked ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: color,
                  width: isTracked ? 3 : 2,
                ),
              ),
              child: Stack(
                children: [
                  // Corner brackets
                  ..._buildCornerBrackets(color, width, height, isTracked),

                  // Label
                  Positioned(
                    top: -28,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detection.classification.toUpperCase(),
                            style: GoogleFonts.orbitron(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${(detection.confidence * 100).toStringAsFixed(0)}% • ${detection.distance.toStringAsFixed(0)}m',
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Center lock indicator
                  if (isTracked)
                    Center(
                      child: Icon(
                        Icons.gps_fixed,
                        color: color,
                        size: 40 * _pulseAnimation.value,
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        Icons.gps_not_fixed,
                        color: color.withOpacity(0.7),
                        size: 30,
                      ),
                    ),

                  // Distance indicator lines
                  if (!isTracked)
                    CustomPaint(
                      size: Size(width, height),
                      painter: DistanceIndicatorPainter(color: color),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildCornerBrackets(
      Color color, double width, double height, bool isTracked) {
    final bracketSize = isTracked ? 16.0 : 12.0;
    final thickness = isTracked ? 3.0 : 2.0;

    return [
      // Top-left
      Positioned(
        top: 0,
        left: 0,
        child: Container(width: bracketSize, height: thickness, color: color),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(width: thickness, height: bracketSize, color: color),
      ),
      // Top-right
      Positioned(
        top: 0,
        right: 0,
        child: Container(width: bracketSize, height: thickness, color: color),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(width: thickness, height: bracketSize, color: color),
      ),
      // Bottom-left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(width: bracketSize, height: thickness, color: color),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(width: thickness, height: bracketSize, color: color),
      ),
      // Bottom-right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(width: bracketSize, height: thickness, color: color),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(width: thickness, height: bracketSize, color: color),
      ),
    ];
  }

  void _engageTracking(DroneDetection detection) {
    _comm.engageTracking(detection.id);

    final status = Get.find<SystemStatusService>();
    status.show(
      'Tracking engaged – Target: ${detection.classification}',
      StatusType.warning,
    );
  }

  // ============================================================================
  // TACTICAL RETICLE
  // ============================================================================

  Widget _buildCentralReticle() {
    return Center(
      child: SizedBox(
        width: 80,
        height: 80,
        child: CustomPaint(
          painter: TacticalReticlePainter(
            color: trackingLocked.value
                ? const Color(0xFFFF3366)
                : const Color(0xFF00FF88),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HUD ELEMENTS
  // ============================================================================

  Widget _buildTopHUD() {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildHUDInfo(
              'REC', Icons.fiber_manual_record, const Color(0xFFFF3366)),
          _buildHUDInfo(
            '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}',
            Icons.access_time,
            Colors.white,
          ),
          _buildHUDInfo('FHD 30', Icons.videocam, const Color(0xFF00F5FF)),
        ],
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
                detections.isEmpty ? Colors.white : const Color(0xFFFF9500),
              ),
              if (trackedTarget.value != null)
                _buildHUDInfo(
                  'LOCKED: ${trackedTarget.value!.distance.toStringAsFixed(0)}m',
                  Icons.gps_fixed,
                  const Color(0xFFFF3366),
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

  Widget _buildHUDInfo(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockIndicator() {
    return Positioned(
      top: 80,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _pulseAnimation.value,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3366).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3366).withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.gps_fixed,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '🎯 TRACKING LOCKED',
                      style: GoogleFonts.orbitron(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// CUSTOM PAINTERS
// ============================================================================

class TacticalGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.15)
      ..strokeWidth = 1;

    // Vertical grid lines
    final gridSpacing = size.width / 8;
    for (double i = gridSpacing; i < size.width; i += gridSpacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    // Horizontal grid lines
    for (double i = gridSpacing; i < size.height; i += gridSpacing) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TacticalReticlePainter extends CustomPainter {
  final Color color;

  TacticalReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Crosshair
    final length = size.width / 3;
    canvas.drawLine(
      Offset(center.dx - length, center.dy),
      Offset(center.dx + length, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - length),
      Offset(center.dx, center.dy + length),
      paint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, dotPaint);

    // Outer circle
    canvas.drawCircle(center, size.width / 2.5, paint);

    // Inner circle
    canvas.drawCircle(center, size.width / 6, paint);
  }

  @override
  bool shouldRepaint(covariant TacticalReticlePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class DistanceIndicatorPainter extends CustomPainter {
  final Color color;

  DistanceIndicatorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1;

    // Corner to center lines
    canvas.drawLine(
      Offset.zero,
      Offset(size.width / 2, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width / 2, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width / 2, size.height / 2),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width / 2, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
