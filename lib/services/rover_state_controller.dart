import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../models/threat_model.dart';
import 'dart:async';

/// L5 - SINGLE SOURCE OF TRUTH
/// All system state flows through this controller
/// No widget should directly access other services
/// This prevents state fragmentation and race conditions

enum RoverMode { surveillance, defense, manual, patrol, standby, emergency }
enum RoverState { idle, moving, tracking, engaging, returning, error }
enum LinkStatus { connected, degraded, lost, reconnecting }

class RoverStateController extends GetxController {
  // ============================================================================
  // CORE STATE - SINGLE SOURCE OF TRUTH
  // ============================================================================
  
  // Rover Identity & Status
  final roverId = 'SENTINEL_001'.obs;
  final roverMode = RoverMode.surveillance.obs;
  final roverState = RoverState.idle.obs;
  final linkStatus = LinkStatus.connected.obs;
  
  // Position & Navigation
  final latitude = 13.0827.obs;
  final longitude = 80.2707.obs;
  final heading = 0.0.obs; // degrees
  final altitude = 0.0.obs; // meters
  final speed = 0.0.obs; // m/s
  final distanceTraveled = 0.0.obs; // meters
  
  // Path History
  final pathHistory = <Position>[].obs;
  final maxPathPoints = 500.obs;
  
  // System Health
  final batteryLevel = 100.0.obs;
  final batteryVoltage = 12.6.obs;
  final cpuTemp = 45.0.obs;
  final gpuTemp = 42.0.obs;
  final cpuLoad = 0.0.obs;
  final gpuLoad = 0.0.obs;
  final ramUsage = 0.0.obs;
  final storageUsage = 0.0.obs;
  
  // Network Health
  final signalStrength = 100.obs;
  final latency = 0.obs; // milliseconds
  final packetLoss = 0.0.obs; // percentage
  final bandwidth = 0.0.obs; // Mbps
  final lastHeartbeat = DateTime.now().obs;
  final missedHeartbeats = 0.obs;
  
  // Sensors
  final gpsLocked = false.obs;
  final gpsSatellites = 0.obs;
  final imuCalibrated = true.obs;
  final cameraActive = true.obs;
  final lidarActive = false.obs;
  
  // Weapons & Defense
  final laserEnabled = false.obs;
  final laserTemperature = 25.0.obs;
  final laserCooldown = 0.obs; // seconds
  final trackingLocked = false.obs;
  final trackingTarget = Rx<String?>(null);
  
  // Threats
  final activeThreats = <ThreatModel>[].obs;
  final threatHistory = <ThreatModel>[].obs;
  final maxThreatHistory = 100.obs;
  final totalThreatsDetected = 0.obs;
  final totalThreatsNeutralized = 0.obs;
  
  // Mission
  final missionActive = false.obs;
  final missionStartTime = Rx<DateTime?>(null);
  final missionDuration = 0.obs; // seconds
  final patrolWaypoints = <Position>[].obs;
  final currentWaypoint = Rx<Position?>(null);
  
  // Commands
  final lastCommand = Rx<String?>(null);
  final lastCommandTime = Rx<DateTime?>(null);
  final commandQueue = <Map<String, dynamic>>[].obs;
  final pendingAcks = <String, DateTime>{}.obs;
  
  // ============================================================================
  // TIMERS & BACKGROUND TASKS
  // ============================================================================
  
  Timer? _heartbeatTimer;
  Timer? _telemetryTimer;
  Timer? _missionTimer;
  
  @override
  void onInit() {
    super.onInit();
    _startBackgroundTasks();
    _initializeRover();
  }
  
  void _initializeRover() {
    print('[ROVER_STATE] Initializing rover state controller...');
    
    // Set initial state
    roverMode.value = RoverMode.surveillance;
    roverState.value = RoverState.idle;
    linkStatus.value = LinkStatus.connected;
    
    // Start position tracking
    _startPositionTracking();
  }
  
  void _startBackgroundTasks() {
    // Heartbeat monitoring (every 2 seconds)
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkHeartbeat();
    });
    
    // Telemetry updates (every 1 second)
    _telemetryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTelemetry();
    });
    
    // Mission timer (every 1 second)
    _missionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (missionActive.value) {
        missionDuration.value++;
      }
    });
  }
  
  // ============================================================================
  // POSITION & NAVIGATION
  // ============================================================================
  
  void _startPositionTracking() {
    // This will be replaced with actual GPS data from Jetson
    // For now, simulated movement
  }
  
  void updatePosition(double lat, double lng, {double? hdg, double? alt, double? spd}) {
    // Add to path history
    if (pathHistory.isNotEmpty) {
      final lastPos = pathHistory.last;
      final distance = Geolocator.distanceBetween(
        lastPos.latitude,
        lastPos.longitude,
        lat,
        lng,
      );
      distanceTraveled.value += distance;
    }
    
    // Update position
    latitude.value = lat;
    longitude.value = lng;
    if (hdg != null) heading.value = hdg;
    if (alt != null) altitude.value = alt;
    if (spd != null) speed.value = spd;
    
    // Add to path
    pathHistory.add(Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      altitude: alt ?? 0,
      heading: hdg ?? 0,
      speed: spd ?? 0,
      speedAccuracy: 1.0,
      altitudeAccuracy: 1.0,
      headingAccuracy: 1.0,
    ));
    
    // Maintain max path points
    if (pathHistory.length > maxPathPoints.value) {
      pathHistory.removeAt(0);
    }
  }
  
  void clearPath() {
    pathHistory.clear();
    distanceTraveled.value = 0;
  }
  
  // ============================================================================
  // THREAT MANAGEMENT
  // ============================================================================
  
  void addThreat(ThreatModel threat) {
    // Add to active threats if not already present
    if (!activeThreats.any((t) => t.id == threat.id)) {
      activeThreats.add(threat);
      totalThreatsDetected.value++;
      
      // Add to history
      threatHistory.insert(0, threat);
      if (threatHistory.length > maxThreatHistory.value) {
        threatHistory.removeLast();
      }
    }
  }
  
  void updateThreat(String id, {
    double? lat,
    double? lng,
    double? distance,
    double? confidence,
    bool? neutralized,
  }) {
    final index = activeThreats.indexWhere((t) => t.id == id);
    if (index != -1) {
      final threat = activeThreats[index];
      activeThreats[index] = ThreatModel(
        id: threat.id,
        severity: threat.severity,
        latitude: lat ?? threat.latitude,
        longitude: lng ?? threat.longitude,
        distance: distance ?? threat.distance,
        timestamp: threat.timestamp,
        neutralized: neutralized ?? threat.neutralized,
        alertsSent: threat.alertsSent,
      );
      
      if (neutralized == true) {
        totalThreatsNeutralized.value++;
      }
    }
  }
  
  void removeThreat(String id) {
    activeThreats.removeWhere((t) => t.id == id);
  }
  
  void clearThreats() {
    activeThreats.clear();
  }
  
  // ============================================================================
  // MODE & STATE MANAGEMENT
  // ============================================================================
  
  void changeMode(RoverMode newMode) {
    final oldMode = roverMode.value;
    roverMode.value = newMode;
    
    print('[ROVER_STATE] Mode changed: ${oldMode.name} → ${newMode.name}');
    
    // Auto-configure based on mode
    _configureMode(newMode);
  }
  
  void _configureMode(RoverMode mode) {
    switch (mode) {
      case RoverMode.surveillance:
        laserEnabled.value = false;
        roverState.value = RoverState.idle;
        break;
      
      case RoverMode.defense:
        // Laser enabled in defense mode (if authorized)
        roverState.value = RoverState.idle;
        break;
      
      case RoverMode.manual:
        // Manual control mode
        roverState.value = RoverState.idle;
        break;
      
      case RoverMode.patrol:
        if (patrolWaypoints.isNotEmpty) {
          roverState.value = RoverState.moving;
          missionActive.value = true;
          missionStartTime.value = DateTime.now();
        }
        break;
      
      case RoverMode.standby:
        laserEnabled.value = false;
        roverState.value = RoverState.idle;
        break;
      
      case RoverMode.emergency:
        // Emergency stop
        laserEnabled.value = false;
        roverState.value = RoverState.idle;
        speed.value = 0;
        break;
    }
  }
  
  void setState(RoverState newState) {
    roverState.value = newState;
    print('[ROVER_STATE] State changed: ${newState.name}');
  }
  
  // ============================================================================
  // HEARTBEAT & LINK MONITORING
  // ============================================================================
  
  void updateHeartbeat() {
    lastHeartbeat.value = DateTime.now();
    missedHeartbeats.value = 0;
    
    if (linkStatus.value != LinkStatus.connected) {
      linkStatus.value = LinkStatus.connected;
      print('[ROVER_STATE] Link restored');
    }
  }
  
  void _checkHeartbeat() {
    final timeSinceLastBeat = DateTime.now().difference(lastHeartbeat.value);
    
    if (timeSinceLastBeat.inSeconds > 6) {
      // 3 missed heartbeats (2s interval)
      if (linkStatus.value != LinkStatus.lost) {
        linkStatus.value = LinkStatus.lost;
        print('[ROVER_STATE] ⚠️ LINK LOST - Entering safe mode');
        _handleLinkLost();
      }
    } else if (timeSinceLastBeat.inSeconds > 4) {
      // 2 missed heartbeats
      if (linkStatus.value != LinkStatus.degraded) {
        linkStatus.value = LinkStatus.degraded;
        print('[ROVER_STATE] ⚠️ Link degraded');
      }
    }
  }
  
  void _handleLinkLost() {
    // Safety protocol when link is lost
    changeMode(RoverMode.emergency);
    laserEnabled.value = false;
    
    // Start auto-reconnect
    linkStatus.value = LinkStatus.reconnecting;
  }
  
  // ============================================================================
  // TELEMETRY UPDATES
  // ============================================================================
  
  void _updateTelemetry() {
    // This will be replaced with actual data from Jetson
    // For now, simulated
  }
  
  void updateTelemetry(Map<String, dynamic> data) {
    if (data.containsKey('battery')) batteryLevel.value = data['battery'];
    if (data.containsKey('battery_voltage')) batteryVoltage.value = data['battery_voltage'];
    if (data.containsKey('cpu_temp')) cpuTemp.value = data['cpu_temp'];
    if (data.containsKey('gpu_temp')) gpuTemp.value = data['gpu_temp'];
    if (data.containsKey('cpu_load')) cpuLoad.value = data['cpu_load'];
    if (data.containsKey('gpu_load')) gpuLoad.value = data['gpu_load'];
    if (data.containsKey('ram_usage')) ramUsage.value = data['ram_usage'];
    if (data.containsKey('storage')) storageUsage.value = data['storage'];
    
    // Check for warnings
    _checkSystemHealth();
  }
  
  void _checkSystemHealth() {
    // Low battery warning
    if (batteryLevel.value < 20 && batteryLevel.value > 0) {
      print('[ROVER_STATE] ⚠️ Low battery: ${batteryLevel.value}%');
    }
    
    // High temperature warning
    if (cpuTemp.value > 80 || gpuTemp.value > 80) {
      print('[ROVER_STATE] ⚠️ High temperature detected');
    }
    
    // GPS lost warning
    if (!gpsLocked.value) {
      print('[ROVER_STATE] ⚠️ GPS signal lost');
    }
  }
  
  // ============================================================================
  // COMMAND MANAGEMENT
  // ============================================================================
  
  void sendCommand(String command, Map<String, dynamic> payload) {
    final commandId = 'cmd_${DateTime.now().millisecondsSinceEpoch}';
    
    final cmd = {
      'id': commandId,
      'type': command,
      'payload': payload,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    commandQueue.add(cmd);
    lastCommand.value = command;
    lastCommandTime.value = DateTime.now();
    
    // Add to pending acknowledgments
    pendingAcks[commandId] = DateTime.now();
    
    print('[ROVER_STATE] Command sent: $command ($commandId)');
  }
  
  void acknowledgeCommand(String commandId, String status) {
    pendingAcks.remove(commandId);
    print('[ROVER_STATE] Command acknowledged: $commandId ($status)');
  }
  
  // ============================================================================
  // MISSION MANAGEMENT
  // ============================================================================
  
  void startMission() {
    missionActive.value = true;
    missionStartTime.value = DateTime.now();
    missionDuration.value = 0;
    print('[ROVER_STATE] Mission started');
  }
  
  void stopMission() {
    missionActive.value = false;
    print('[ROVER_STATE] Mission stopped - Duration: ${missionDuration.value}s');
  }
  
  void addPatrolWaypoint(Position waypoint) {
    patrolWaypoints.add(waypoint);
  }
  
  void clearPatrolRoute() {
    patrolWaypoints.clear();
    currentWaypoint.value = null;
  }
  
  // ============================================================================
  // UTILITY METHODS
  // ============================================================================
  
  Map<String, dynamic> getFullState() {
    return {
      'rover_id': roverId.value,
      'mode': roverMode.value.name,
      'state': roverState.value.name,
      'link_status': linkStatus.value.name,
      'position': {
        'latitude': latitude.value,
        'longitude': longitude.value,
        'heading': heading.value,
        'altitude': altitude.value,
        'speed': speed.value,
        'distance_traveled': distanceTraveled.value,
      },
      'health': {
        'battery': batteryLevel.value,
        'cpu_temp': cpuTemp.value,
        'gpu_temp': gpuTemp.value,
        'cpu_load': cpuLoad.value,
        'gpu_load': gpuLoad.value,
      },
      'network': {
        'signal': signalStrength.value,
        'latency': latency.value,
        'packet_loss': packetLoss.value,
      },
      'threats': {
        'active': activeThreats.length,
        'total_detected': totalThreatsDetected.value,
        'total_neutralized': totalThreatsNeutralized.value,
      },
      'mission': {
        'active': missionActive.value,
        'duration': missionDuration.value,
      },
    };
  }
  
  void reset() {
    print('[ROVER_STATE] Resetting rover state...');
    
    // Reset to initial state
    changeMode(RoverMode.surveillance);
    setState(RoverState.idle);
    clearThreats();
    clearPath();
    stopMission();
    
    // Reset telemetry
    batteryLevel.value = 100;
    cpuTemp.value = 45;
    gpuTemp.value = 42;
  }
  
  @override
  void onClose() {
    _heartbeatTimer?.cancel();
    _telemetryTimer?.cancel();
    _missionTimer?.cancel();
    super.onClose();
  }
}
