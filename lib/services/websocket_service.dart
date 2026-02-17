import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/threat_model.dart';

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
  var distanceTraveled = 0.0.obs; // Distance in meters

  void connect() {
    try {
      // Replace with your backend URL
      socket = IO.io(
        'http://localhost:3000',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      socket.connect();

      socket.onConnect((_) {
        print('Connected to server');
        isConnected.value = true;
        roverStatus.value = 'ACTIVE';
      });

      socket.onDisconnect((_) {
        print('Disconnected from server');
        isConnected.value = false;
        roverStatus.value = 'OFFLINE';
      });

      // Listen for rover status updates
      socket.on('rover_status', (data) {
        batteryLevel.value = data['battery'] ?? 85;
        laserStatus.value = data['laser_status'] ?? 'READY';
        latitude.value = data['latitude'] ?? 13.0827;
        longitude.value = data['longitude'] ?? 80.2707;
        distanceTraveled.value = data['distance_traveled'] ?? 0.0;
      });

      // Listen for threat alerts
      socket.on('threat_detected', (data) {
        final threat = ThreatModel.fromJson(data);
        recentThreats.insert(0, threat);
        threatsDetected.value = recentThreats.length;
        
        // Update threat level
        _updateThreatLevel();
      });

      // Listen for threat neutralized
      socket.on('threat_neutralized', (data) {
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
          );
          recentThreats.refresh();
          _updateThreatLevel();
        }
      });

      // Simulate some data for demo
      _simulateData();
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

  void _simulateData() {
    // Simulate rover status updates every 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (isConnected.value) {
        batteryLevel.value = (batteryLevel.value - 1).clamp(0, 100);
        _simulateData();
      }
    });
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
