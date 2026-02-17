import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/bluetooth_service.dart';
import 'dart:typed_data';
import 'package:sentinel_rover/services/bluetooth_service.dart';

class LiveCameraFeed extends StatefulWidget {
  const LiveCameraFeed({super.key});

  @override
  State<LiveCameraFeed> createState() => _LiveCameraFeedState();
}

class _LiveCameraFeedState extends State<LiveCameraFeed> {
  final RoverBluetoothService _btService = Get.find<RoverBluetoothService>();

  late WebViewController _webViewController;
  bool _isStreaming = false;
  final String _streamUrl = 'http://localhost:3000/camera/stream';
  Uint8List? _currentFrame;

  @override
  void initState() {
    super.initState();
    _initializeWebView();

    ever(_btService.connectionMode, (mode) {
      if (mode == 'bluetooth') {
        _startBluetoothStream();
      } else {
        _stopBluetoothStream();
      }
    });
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse(_streamUrl));
  }

  void _startBluetoothStream() async {
    setState(() => _isStreaming = true);

    // If using Bluetooth, get frames directly
    if (_btService.connectionMode.value == 'bluetooth') {
      _streamViaBluetooth();
    }
    // Otherwise use WebSocket/HTTP stream
  }

  void _stopBluetoothStream() {
    _isStreaming = false;
  }

  void _streamViaBluetooth() async {
    while (_isStreaming && mounted) {
      final frameData = await _btService.getCameraFrame();
      if (frameData != null && mounted) {
        setState(() {
          _currentFrame = Uint8List.fromList(frameData);
        });
      }
      await Future.delayed(const Duration(milliseconds: 100)); // 10 FPS
    }
  }

  @override
  void dispose() {
    _isStreaming = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF151B2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00F5FF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Camera feed
            Obx(() {
              if (_btService.connectionMode.value == 'bluetooth' &&
                  _currentFrame != null) {
                // Display Bluetooth frame
                return Image.memory(
                  _currentFrame!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                );
              } else {
                // Display WebView stream
                return WebViewWidget(controller: _webViewController);
              }
            }),

            // Overlay controls
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live indicator
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3366).withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE',
                            style: GoogleFonts.orbitron(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Connection type badge
                    Obx(() => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00F5FF).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF00F5FF),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _btService.connectionMode.value.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),

            // Bottom info bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoChip(Icons.videocam, 'FHD 30FPS'),
                    _buildInfoChip(Icons.wb_sunny_outlined, 'Night Vision'),
                    _buildInfoChip(Icons.zoom_in, '10x Zoom'),
                  ],
                ),
              ),
            ),

            // Recording indicator (if needed)
            if (_isStreaming)
              Positioned(
                top: 50,
                right: 12,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFF3366),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF3366).withOpacity(0.6),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF00F5FF),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
