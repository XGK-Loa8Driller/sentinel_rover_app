import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../services/connectivity_manager.dart';
import '../services/auth_service.dart';
import '../services/mission_log_service.dart';
import 'dart:math' as math;
import '../services/system_status_service.dart';

class ManualControlScreen extends StatefulWidget {
  const ManualControlScreen({super.key});

  @override
  State<ManualControlScreen> createState() => _ManualControlScreenState();
}

class _ManualControlScreenState extends State<ManualControlScreen> {
  final ConnectivityManager _connManager = Get.find<ConnectivityManager>();
  final AuthService _authService = Get.find<AuthService>();
  final MissionLogService _logService = Get.find<MissionLogService>();

  Offset _joystickPosition = Offset.zero;
  bool _isDragging = false;
  double _cameraAngle = 0.0; // -45 to +45 degrees

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF151B2B),
        title: Text(
          'MANUAL CONTROL',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 3,
          ),
        ),
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                  _authService.isLaserEnabled.value
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: _authService.isLaserEnabled.value
                      ? const Color(0xFFFF3366)
                      : Colors.white60,
                ),
                onPressed: _toggleLaser,
              )),
        ],
      ),
      body: Column(
        children: [
          _buildStatusBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildJoystickControl(),
                  const SizedBox(height: 30),
                  _buildCameraControl(),
                  const SizedBox(height: 30),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          _buildEmergencyStop(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Obx(() => Container(
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
            children: [
              /// LEFT SIDE (Connection Info)
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _connManager.connectionStatus.value ==
                                ConnectionStatus.connected
                            ? const Color(0xFF00FF88)
                            : const Color(0xFFFF3366),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _connManager.connectionInfo,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              /// RIGHT SIDE (Mode Badge)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getModeColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getModeColor(),
                  ),
                ),
                child: Text(
                  _authService.systemMode.value.name.toUpperCase(),
                  style: GoogleFonts.orbitron(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getModeColor(),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Color _getModeColor() {
    switch (_authService.systemMode.value) {
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

  Widget _buildJoystickControl() {
    return Column(
      children: [
        Text(
          'MOVEMENT CONTROL',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF00F5FF).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Crosshair
              CustomPaint(
                size: const Size(250, 250),
                painter: CrosshairPainter(),
              ),

              // Joystick handle
              Positioned(
                left: 125 + _joystickPosition.dx - 30,
                top: 125 + _joystickPosition.dy - 30,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _isDragging = true),
                  onPanUpdate: _handleJoystickDrag,
                  onPanEnd: (_) {
                    setState(() {
                      _isDragging = false;
                      _joystickPosition = Offset.zero;
                    });
                    _sendMovementCommand(0, 0);
                  },
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isDragging
                          ? const Color(0xFFFF3366)
                          : const Color(0xFF00F5FF),
                      boxShadow: [
                        BoxShadow(
                          color: (_isDragging
                                  ? const Color(0xFFFF3366)
                                  : const Color(0xFF00F5FF))
                              .withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gamepad,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDirectionIndicator('X', _joystickPosition.dx / 95),
            const SizedBox(width: 20),
            _buildDirectionIndicator('Y', -_joystickPosition.dy / 95),
          ],
        ),
      ],
    );
  }

  void _handleJoystickDrag(DragUpdateDetails details) {
    setState(() {
      final newPosition = _joystickPosition + details.delta;
      final distance = newPosition.distance;

      if (distance <= 95) {
        _joystickPosition = newPosition;
      } else {
        _joystickPosition = Offset.fromDirection(
          newPosition.direction,
          95,
        );
      }
    });

    // Send movement command
    final x = _joystickPosition.dx / 95; // Normalize to -1 to 1
    final y = -_joystickPosition.dy / 95;
    _sendMovementCommand(x, y);
  }

  Widget _buildDirectionIndicator(String label, double value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        Text(
          value.toStringAsFixed(2),
          style: GoogleFonts.orbitron(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00F5FF),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraControl() {
    return Column(
      children: [
        Text(
          'CAMERA ANGLE',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _adjustCamera(-5),
              icon: const Icon(Icons.arrow_downward),
              color: const Color(0xFF00F5FF),
              iconSize: 40,
            ),
            const SizedBox(width: 40),
            Text(
              '${_cameraAngle.toStringAsFixed(0)}°',
              style: GoogleFonts.orbitron(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00F5FF),
              ),
            ),
            const SizedBox(width: 40),
            IconButton(
              onPressed: () => _adjustCamera(5),
              icon: const Icon(Icons.arrow_upward),
              color: const Color(0xFF00F5FF),
              iconSize: 40,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Slider(
          value: _cameraAngle,
          min: -45,
          max: 45,
          divisions: 18,
          activeColor: const Color(0xFF00F5FF),
          inactiveColor: Colors.white10,
          onChanged: (value) {
            setState(() => _cameraAngle = value);
            _sendCameraCommand(value);
          },
        ),
      ],
    );
  }

  void _adjustCamera(double delta) {
    setState(() {
      _cameraAngle = (_cameraAngle + delta).clamp(-45.0, 45.0);
    });
    _sendCameraCommand(_cameraAngle);
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'FIRE LASER',
                  Icons.flash_on,
                  const Color(0xFFFF3366),
                  _fireLaser,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'STOP',
                  Icons.stop,
                  const Color(0xFFFF9500),
                  _stopMovement,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'AUTO MODE',
                  Icons.auto_awesome,
                  const Color(0xFF00FF88),
                  _toggleAutonomous,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'SCAN',
                  Icons.radar,
                  const Color(0xFF00F5FF),
                  _scanArea,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 1),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStop() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFF3366).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () => _authService.emergencyStop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF3366),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emergency, size: 28),
                const SizedBox(width: 8),
                Text(
                  'EMERGENCY STOP',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _sendMovementCommand(double x, double y) {
    _connManager.sendCommand('movement', {
      'x': x,
      'y': y,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _sendCameraCommand(double angle) {
    _connManager.sendCommand('camera_angle', {
      'angle': angle,
    });
    _logService.log(
        'Camera angle adjusted to ${angle.toStringAsFixed(0)}°', LogLevel.info);
  }

  void _toggleLaser() async {
    if (_authService.isLaserEnabled.value) {
      _authService.disableLaser();
    } else {
      _authService.enableLaser();
    }
  }

  void _fireLaser() async {
    if (await _authService.requestPermission(
        'fire_laser', 'Manual laser engagement')) {
      _connManager.sendCommand('fire_laser');
      _logService.logLaserFire('manual_target');

      final status = Get.find<SystemStatusService>();
      status.show('⚡ Laser pulse sent', StatusType.error);
    }
  }

  void _stopMovement() {
    setState(() => _joystickPosition = Offset.zero);
    _sendMovementCommand(0, 0);
    _logService.log('Movement stopped', LogLevel.info);
  }

  void _toggleAutonomous() {
    if (_authService.isAutonomousEnabled.value) {
      _authService.isAutonomousEnabled.value = false;
      _logService.log('Autonomous mode disabled', LogLevel.info);
    } else {
      if (_authService.hasPermission('enable_autonomous')) {
        _authService.isAutonomousEnabled.value = true;
        _logService.log('Autonomous mode enabled', LogLevel.critical);
      }
    }
  }

  void _scanArea() {
    _connManager.sendCommand('scan_area');
    _logService.log('Area scan initiated', LogLevel.info);

    final status = Get.find<SystemStatusService>();
    status.show('🔍 360° area scan in progress...', StatusType.info);
  }
}

class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withOpacity(0.3)
      ..strokeWidth = 1;

    // Horizontal line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    // Circles
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 4,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
