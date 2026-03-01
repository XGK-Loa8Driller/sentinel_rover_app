import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class CarControllerScreen extends StatefulWidget {
  const CarControllerScreen({super.key});

  @override
  State<CarControllerScreen> createState() => _CarControllerScreenState();
}

class _CarControllerScreenState extends State<CarControllerScreen> {
  bool upPressed = false;
  bool downPressed = false;
  bool leftPressed = false;
  bool rightPressed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  void _sendCommand(String cmd) {
    // Replace this later with WebSocket
    print(cmd);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: _buildTopBar(),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final width = constraints.maxWidth;

                  final padSize = height * 0.72;
                  final padBottomOffset = height * 0.08;
                  final sideOffset = width * 0.12;

                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 1,
                          height: height * 0.65,
                          color: Colors.white24,
                        ),
                      ),
                      Positioned(
                        left: sideOffset,
                        bottom: padBottomOffset,
                        child: _buildVerticalPad(padSize),
                      ),
                      Positioned(
                        right: sideOffset,
                        bottom: padBottomOffset,
                        child: _buildHorizontalPad(padSize),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TOP BAR =================

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _circleIcon(Icons.message),
            const SizedBox(width: 15),
            _circleIcon(Icons.lightbulb),
            const SizedBox(width: 15),
            _circleIcon(Icons.warning),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1F5F2E),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              const Icon(Icons.battery_full, color: Colors.white),
              const SizedBox(width: 10),
              Text("85%", style: GoogleFonts.orbitron(color: Colors.white)),
              const SizedBox(width: 20),
              const Icon(Icons.speed, color: Colors.white),
              const SizedBox(width: 10),
              Text("20 Km/h", style: GoogleFonts.orbitron(color: Colors.white)),
            ],
          ),
        ),
        Row(
          children: [
            _circleIcon(Icons.settings),
            const SizedBox(width: 15),
            _circleIcon(Icons.code),
          ],
        ),
      ],
    );
  }

  Widget _circleIcon(IconData icon) {
    return Container(
      width: 55,
      height: 55,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF0D2E2E),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  // ================= VERTICAL PAD =================

  Widget _buildVerticalPad(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(decoration: _padDecoration()),

          Positioned(
            top: size * 0.5,
            left: size * 0.18,
            right: size * 0.18,
            child: Container(height: 1.5, color: Colors.white24),
          ),

          // UP
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size * 0.5,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) {
                setState(() => upPressed = true);
                HapticFeedback.mediumImpact();
                _sendCommand('F');
              },
              onTapUp: (_) {
                setState(() => upPressed = false);
                _sendCommand('S');
              },
              onTapCancel: () {
                setState(() => upPressed = false);
                _sendCommand('S');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: _glowDecoration(upPressed),
                alignment: Alignment.center,
                child: Icon(
                  Icons.keyboard_arrow_up,
                  size: size * 0.18,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // DOWN
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size * 0.5,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) {
                setState(() => downPressed = true);
                HapticFeedback.mediumImpact();
                _sendCommand('B');
              },
              onTapUp: (_) {
                setState(() => downPressed = false);
                _sendCommand('S');
              },
              onTapCancel: () {
                setState(() => downPressed = false);
                _sendCommand('S');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: _glowDecoration(downPressed),
                alignment: Alignment.center,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: size * 0.18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HORIZONTAL PAD =================

  Widget _buildHorizontalPad(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(decoration: _padDecoration()),

          Positioned(
            left: size * 0.5,
            top: size * 0.18,
            bottom: size * 0.18,
            child: Container(width: 1.5, color: Colors.white24),
          ),

          // LEFT
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: size * 0.5,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) {
                setState(() => leftPressed = true);
                HapticFeedback.mediumImpact();
                _sendCommand('L');
              },
              onTapUp: (_) {
                setState(() => leftPressed = false);
                _sendCommand('S');
              },
              onTapCancel: () {
                setState(() => leftPressed = false);
                _sendCommand('S');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: _glowDecoration(leftPressed),
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_left,
                  size: size * 0.18,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // RIGHT
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: size * 0.5,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (_) {
                setState(() => rightPressed = true);
                HapticFeedback.mediumImpact();
                _sendCommand('R');
              },
              onTapUp: (_) {
                setState(() => rightPressed = false);
                _sendCommand('S');
              },
              onTapCancel: () {
                setState(() => rightPressed = false);
                _sendCommand('S');
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: _glowDecoration(rightPressed),
                alignment: Alignment.center,
                child: Icon(
                  Icons.chevron_right,
                  size: size * 0.18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _padDecoration() {
    return const BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Color(0xFF0F3D3D),
          Color(0xFF062020),
          Colors.black,
        ],
        stops: [0.3, 0.7, 1.0],
        radius: 0.9,
      ),
    );
  }

  BoxDecoration _glowDecoration(bool pressed) {
    return BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: pressed
          ? [
              BoxShadow(
                color: const Color(0xFF00FFAA).withOpacity(0.85),
                blurRadius: 40,
                spreadRadius: 10,
              )
            ]
          : [],
    );
  }
}
