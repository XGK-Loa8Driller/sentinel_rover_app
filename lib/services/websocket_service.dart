import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/threat_model.dart';
import '../config/app_config.dart';
import 'package:flutter/material.dart';

class WebSocketService extends GetxController {
  late IO.Socket socket;

  // Observable states
  var isConnected = false.obs;
  var roverStatus = 'STANDBY'.obs;
  var batteryLevel = 85.obs;
  var laserStatus = 'READY'.obs;
  var latitude = 13.0827.obs;
  var longitude = 80.2707.obs;
  var threatLevel = 'LOW'.obs;
  var threatsDetected = 0.obs;
  var recentThreats = <ThreatModel>[].obs;
  var distanceTraveled = 0.0.obs;
  var environmentMode = 'OUTDOOR'.obs; // INDOOR / OUTDOOR
  var autonomousAllowed = false.obs;
  var autonomousInProgress = false.obs;

  // 🔥 Tactical Banner State
  var bannerMessage = ''.obs;
  var bannerColor = Colors.transparent.obs;
  var showBanner = false.obs;

  void _showBanner(String message, Color color) {
    bannerMessage.value = message;
    bannerColor.value = color;
    showBanner.value = true;

    Future.delayed(const Duration(seconds: 2), () {
      showBanner.value = false;
    });
  }

  void connect() {
    try {
      socket = IO.io(
        AppConfig.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(10)
            .setReconnectionDelay(2000)
            .build(),
      );

      socket.connect();

      // ---------------- CONNECTION EVENTS ----------------

      socket.onConnect((_) {
        isConnected.value = true;
        roverStatus.value = 'ACTIVE';

        _showBanner(
          "CONNECTION ESTABLISHED",
          const Color(0xFF00FF88),
        );
      });

      socket.onDisconnect((_) {
        isConnected.value = false;
        roverStatus.value = 'OFFLINE';

        _showBanner(
          "CONNECTION LOST — RECONNECTING...",
          const Color(0xFFFF3366),
        );
      });

      socket.onReconnect((_) {
        isConnected.value = true;
        roverStatus.value = 'ACTIVE';

        _showBanner(
          "CONNECTION RESTORED",
          const Color(0xFF00FF88),
        );
      });

      socket.onReconnectAttempt((attempt) {
        roverStatus.value = 'RECONNECTING';
      });

      socket.onReconnectError((_) {
        _showBanner(
          "SERVER UNREACHABLE",
          const Color(0xFFFF3366),
        );
      });

      // ---------------- ROVER STATUS ----------------

      socket.on('rover_status', (data) {
        if (data is Map<String, dynamic>) {
          batteryLevel.value = data['battery'] ?? 85;
          laserStatus.value = data['laser_status'] ?? 'READY';
          latitude.value = data['latitude'] ?? 13.0827;
          longitude.value = data['longitude'] ?? 80.2707;
          distanceTraveled.value =
              (data['distance_traveled'] ?? 0.0).toDouble();
        }
      });

      // ---------------- THREAT DETECTED ----------------

      socket.on('threat_detected', (data) {
        if (data is Map<String, dynamic>) {
          final threat = ThreatModel.fromJson(data);

          recentThreats.insert(0, threat);

          // Memory protection (max 50 threats)
          if (recentThreats.length > 50) {
            recentThreats.removeLast();
          }

          threatsDetected.value = recentThreats.length;
          _updateThreatLevel();
        }
      });

      // ---------------- THREAT NEUTRALIZED ----------------

      socket.on('threat_neutralized', (data) {
        if (data is Map<String, dynamic>) {
          final threatId = data['id'];

          final index = recentThreats.indexWhere((t) => t.id == threatId);

          if (index != -1) {
            recentThreats[index] = ThreatModel(
              id: recentThreats[index].id,
              severity: recentThreats[index].severity,
              latitude: recentThreats[index].latitude,
              longitude: recentThreats[index].longitude,
              distance: recentThreats[index].distance,
              timestamp: recentThreats[index].timestamp,
              neutralized: true,
              alertsSent: recentThreats[index].alertsSent,
              confidence: (data['confidence'] ?? 0.75).toDouble(),
            );

            recentThreats.refresh();
            _updateThreatLevel();
          }
        }
      });
    } catch (e) {
      print('Error connecting to server: $e');
    }
  }

  void _updateThreatLevel() {
    final activeThreat = recentThreats.where((t) => !t.neutralized).toList();

    if (activeThreat.any((t) => t.severity.toLowerCase() == 'critical')) {
      threatLevel.value = 'CRITICAL';
    } else if (activeThreat.any((t) => t.severity.toLowerCase() == 'high')) {
      threatLevel.value = 'HIGH';
    } else if (activeThreat.isNotEmpty) {
      threatLevel.value = 'MEDIUM';
    } else {
      threatLevel.value = 'LOW';
    }
  }

  void disconnect() {
    socket.dispose();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
