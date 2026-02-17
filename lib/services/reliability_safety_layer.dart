import 'package:get/get.dart';
import 'dart:async';
import 'rover_state_controller.dart';
import 'secure_communication_protocol.dart';
import 'mission_log_service.dart';
import '../services/system_status_service.dart';

/// L3 - RELIABILITY & SAFETY LAYER
/// Defense-grade failsafe system with:
/// - Heartbeat monitoring
/// - Auto-failsafe on link loss
/// - Battery management
/// - Temperature monitoring
/// - GPS loss handling
/// - Emergency protocols
/// - Auto-return capability

enum SafetyProtocol {
  none,
  linkLost,
  lowBattery,
  highTemperature,
  gpsLost,
  obstacleDetected,
  emergencyStop,
}

class ReliabilitySafetyLayer extends GetxController {
  final RoverStateController _rover = Get.find<RoverStateController>();
  final SecureCommunicationProtocol _comm =
      Get.find<SecureCommunicationProtocol>();
  final MissionLogService _log = Get.find<MissionLogService>();

  // Safety state
  var activeSafetyProtocol = SafetyProtocol.none.obs;
  var isSafeMode = false.obs;
  var lastHeartbeat = DateTime.now().obs;
  var missedHeartbeats = 0.obs;
  var autoReturnEnabled = true.obs;
  var autoReturnTriggered = false.obs;

  // Thresholds
  final double criticalBatteryLevel = 15.0;
  final double lowBatteryLevel = 20.0;
  final double criticalTemperature = 85.0;
  final double highTemperature = 80.0;
  final int maxMissedHeartbeats = 3;
  final int heartbeatInterval = 2; // seconds

  // Timers
  Timer? _heartbeatMonitor;
  Timer? _safetyMonitor;
  Timer? _autoReturnTimer;

  @override
  void onInit() {
    super.onInit();
    _startMonitoring();
  }

  // ============================================================================
  // MONITORING INITIALIZATION
  // ============================================================================

  void _startMonitoring() {
    print('[SAFETY] Reliability & Safety Layer initialized');

    // Monitor heartbeat
    _startHeartbeatMonitoring();

    // Monitor system health
    _startSafetyMonitoring();

    // Listen to rover state changes
    _setupStateListeners();
  }

  void _setupStateListeners() {
    // Battery level monitoring
    ever(_rover.batteryLevel, (level) => _checkBatteryLevel(level));

    // Temperature monitoring
    ever(_rover.cpuTemp, (temp) => _checkTemperature(temp));
    ever(_rover.gpuTemp, (temp) => _checkTemperature(temp));

    // GPS monitoring
    ever(_rover.gpsLocked, (locked) => _handleGPSStatus(locked));

    // Link status monitoring
    ever(_rover.linkStatus, (status) => _handleLinkStatus(status));
  }

  // ============================================================================
  // HEARTBEAT MONITORING
  // ============================================================================

  void _startHeartbeatMonitoring() {
    _heartbeatMonitor?.cancel();

    _heartbeatMonitor = Timer.periodic(
      Duration(seconds: heartbeatInterval),
      (_) => _checkHeartbeat(),
    );

    print(
        '[SAFETY] Heartbeat monitoring started (${heartbeatInterval}s interval)');
  }

  void _checkHeartbeat() {
    final now = DateTime.now();
    final timeSinceLastBeat = now.difference(lastHeartbeat.value).inSeconds;

    if (timeSinceLastBeat > heartbeatInterval * 2) {
      // Missed heartbeat
      missedHeartbeats.value++;

      if (missedHeartbeats.value >= maxMissedHeartbeats) {
        // CRITICAL: Link lost
        _handleLinkLost();
      } else if (missedHeartbeats.value >= 2) {
        print('[SAFETY] ⚠️ Link degraded (${missedHeartbeats.value} missed)');
        _log.logSystemWarning(
            'Link degraded - ${missedHeartbeats.value} missed heartbeats');
      }
    }
  }

  void updateHeartbeat() {
    lastHeartbeat.value = DateTime.now();
    missedHeartbeats.value = 0;

    // Exit safe mode if link restored
    if (activeSafetyProtocol.value == SafetyProtocol.linkLost) {
      _exitSafeMode();
    }
  }

  // ============================================================================
  // LINK LOSS HANDLING
  // ============================================================================

  void _handleLinkLost() {
    if (activeSafetyProtocol.value == SafetyProtocol.linkLost) return;

    print('[SAFETY] 🚨 LINK LOST - Activating emergency protocol');

    activeSafetyProtocol.value = SafetyProtocol.linkLost;
    isSafeMode.value = true;

    _log.logEmergencyAlert('LINK LOST - Emergency protocol activated');

    // Immediate safety actions
    _executeEmergencyProtocol(SafetyProtocol.linkLost);

    // Show alert
    final status = Get.find<SystemStatusService>();
    status.show(
      '🚨 LINK LOST – Emergency protocol activated',
      StatusType.error,
    );

    // Trigger auto-return if enabled
    if (autoReturnEnabled.value && !autoReturnTriggered.value) {
      _triggerAutoReturn();
    }
  }

  void _handleLinkStatus(LinkStatus status) {
    if (status == LinkStatus.lost) {
      _handleLinkLost();
    } else if (status == LinkStatus.connected) {
      if (activeSafetyProtocol.value == SafetyProtocol.linkLost) {
        _exitSafeMode();
      }
    }
  }

  // ============================================================================
  // BATTERY MONITORING
  // ============================================================================

  void _checkBatteryLevel(double level) {
    if (level <= criticalBatteryLevel) {
      _handleCriticalBattery();
    } else if (level <= lowBatteryLevel) {
      _handleLowBattery();
    }
  }

  void _handleCriticalBattery() {
    if (activeSafetyProtocol.value == SafetyProtocol.lowBattery) return;

    print('[SAFETY] 🔋 CRITICAL BATTERY - Initiating emergency return');

    activeSafetyProtocol.value = SafetyProtocol.lowBattery;
    isSafeMode.value = true;

    _log.logEmergencyAlert('CRITICAL BATTERY: ${_rover.batteryLevel.value}%');

    _executeEmergencyProtocol(SafetyProtocol.lowBattery);

    final status = Get.find<SystemStatusService>();
    status.show(
      '🔋 CRITICAL BATTERY ${_rover.batteryLevel.value.toStringAsFixed(0)}% – Returning to base',
      StatusType.error,
    );

    // Force auto-return
    if (!autoReturnTriggered.value) {
      _triggerAutoReturn();
    }
  }

  void _handleLowBattery() {
    print('[SAFETY] ⚠️ LOW BATTERY: ${_rover.batteryLevel.value}%');
    _log.logSystemWarning('Low battery: ${_rover.batteryLevel.value}%');

    final status = Get.find<SystemStatusService>();
    status.show(
      '⚠️ Low battery ${_rover.batteryLevel.value.toStringAsFixed(0)}%',
      StatusType.warning,
    );
  }

  // ============================================================================
  // TEMPERATURE MONITORING
  // ============================================================================

  void _checkTemperature(double temp) {
    if (temp >= criticalTemperature) {
      _handleCriticalTemperature(temp);
    } else if (temp >= highTemperature) {
      _handleHighTemperature(temp);
    }
  }

  void _handleCriticalTemperature(double temp) {
    if (activeSafetyProtocol.value == SafetyProtocol.highTemperature) return;

    print('[SAFETY] 🌡️ CRITICAL TEMPERATURE: $temp°C');

    activeSafetyProtocol.value = SafetyProtocol.highTemperature;
    isSafeMode.value = true;

    _log.logEmergencyAlert('CRITICAL TEMPERATURE: $temp°C');

    _executeEmergencyProtocol(SafetyProtocol.highTemperature);

    final status = Get.find<SystemStatusService>();
    status.show(
      '🌡️ OVERHEATING – $temp°C – Cooling down',
      StatusType.error,
    );
  }

  void _handleHighTemperature(double temp) {
    print('[SAFETY] ⚠️ HIGH TEMPERATURE: $temp°C');
    _log.logSystemWarning('High temperature: $temp°C');
  }

  // ============================================================================
  // GPS MONITORING
  // ============================================================================

  void _handleGPSStatus(bool locked) {
    if (!locked) {
      _handleGPSLost();
    } else {
      if (activeSafetyProtocol.value == SafetyProtocol.gpsLost) {
        _exitSafeMode();
      }
    }
  }

  void _handleGPSLost() {
    print('[SAFETY] 📡 GPS SIGNAL LOST - Switching to dead reckoning');

    activeSafetyProtocol.value = SafetyProtocol.gpsLost;

    _log.logSystemWarning('GPS signal lost');

    final status = Get.find<SystemStatusService>();
    status.show(
      '📡 GPS lost – Switching to dead reckoning',
      StatusType.warning,
    );
  }

  // ============================================================================
  // SAFETY PROTOCOL EXECUTION
  // ============================================================================

  void _executeEmergencyProtocol(SafetyProtocol protocol) {
    print('[SAFETY] Executing emergency protocol: ${protocol.name}');

    switch (protocol) {
      case SafetyProtocol.linkLost:
        // Stop movement
        _comm.emergencyStop();
        // Change to safe mode
        _rover.changeMode(RoverMode.emergency);
        // Disable laser
        _rover.laserEnabled.value = false;
        break;

      case SafetyProtocol.lowBattery:
        // Disable laser to save power
        _rover.laserEnabled.value = false;
        // Switch to power-saving mode
        _rover.changeMode(RoverMode.standby);
        break;

      case SafetyProtocol.highTemperature:
        // Stop all high-power operations
        _rover.laserEnabled.value = false;
        _comm.emergencyStop();
        // Wait for cooldown
        Future.delayed(const Duration(seconds: 30), () {
          if (_rover.cpuTemp.value < highTemperature) {
            _exitSafeMode();
          }
        });
        break;

      case SafetyProtocol.gpsLost:
        // Continue with reduced functionality
        // Do not disable all systems
        break;

      case SafetyProtocol.emergencyStop:
        // Full emergency stop
        _comm.emergencyStop();
        _rover.changeMode(RoverMode.emergency);
        _rover.laserEnabled.value = false;
        _rover.speed.value = 0;
        break;

      default:
        break;
    }
  }

  void _exitSafeMode() {
    print('[SAFETY] ✓ Exiting safe mode');

    isSafeMode.value = false;
    activeSafetyProtocol.value = SafetyProtocol.none;
    autoReturnTriggered.value = false;

    _log.log('Safe mode exited', LogLevel.success);

    final status = Get.find<SystemStatusService>();
    status.show(
      '✓ System restored – Normal operations resumed',
      StatusType.success,
    );
  }

  // ============================================================================
  // AUTO-RETURN SYSTEM
  // ============================================================================

  void _triggerAutoReturn() {
    if (autoReturnTriggered.value) return;

    print('[SAFETY] 🏠 AUTO-RETURN ACTIVATED');

    autoReturnTriggered.value = true;

    _log.log('Auto-return to base initiated', LogLevel.critical);

    // In production, this would:
    // 1. Calculate return route
    // 2. Engage autonomous navigation
    // 3. Return to home coordinates

    _comm.sendSecureCommand('auto_return', {
      'home_lat': 13.0827, // Set home coordinates
      'home_lng': 80.2707,
      'reason': activeSafetyProtocol.value.name,
    });

    final status = Get.find<SystemStatusService>();
    status.show(
      '🏠 AUTO-RETURN – Returning to base',
      StatusType.info,
    );
  }

  void cancelAutoReturn() {
    autoReturnTriggered.value = false;

    _comm.sendSecureCommand('cancel_auto_return', {});

    _log.log('Auto-return cancelled', LogLevel.info);
  }

  // ============================================================================
  // SAFETY MONITORING (CONTINUOUS)
  // ============================================================================

  void _startSafetyMonitoring() {
    _safetyMonitor?.cancel();

    _safetyMonitor = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _performSafetyCheck(),
    );
  }

  void _performSafetyCheck() {
    // Comprehensive safety check
    final issues = <String>[];

    if (_rover.batteryLevel.value < lowBatteryLevel) {
      issues.add('Low battery');
    }

    if (_rover.cpuTemp.value > highTemperature ||
        _rover.gpuTemp.value > highTemperature) {
      issues.add('High temperature');
    }

    if (!_rover.gpsLocked.value) {
      issues.add('GPS lost');
    }

    if (missedHeartbeats.value > 1) {
      issues.add('Link degraded');
    }

    if (issues.isNotEmpty) {
      print('[SAFETY] System issues detected: ${issues.join(", ")}');
    }
  }

  // ============================================================================
  // MANUAL EMERGENCY CONTROL
  // ============================================================================

  void triggerEmergencyStop() {
    print('[SAFETY] 🚨 EMERGENCY STOP TRIGGERED');

    activeSafetyProtocol.value = SafetyProtocol.emergencyStop;
    isSafeMode.value = true;

    _log.logEmergencyAlert('EMERGENCY STOP ACTIVATED');

    _executeEmergencyProtocol(SafetyProtocol.emergencyStop);

    final status = Get.find<SystemStatusService>();
    status.show(
      '🚨 EMERGENCY STOP – All systems halted',
      StatusType.error,
    );
  }

  void resetEmergencyStop() {
    if (activeSafetyProtocol.value == SafetyProtocol.emergencyStop) {
      _exitSafeMode();
      _rover.changeMode(RoverMode.surveillance);
    }
  }

  // ============================================================================
  // UTILITY
  // ============================================================================

  Map<String, dynamic> getSafetyStatus() {
    return {
      'safe_mode': isSafeMode.value,
      'active_protocol': activeSafetyProtocol.value.name,
      'missed_heartbeats': missedHeartbeats.value,
      'auto_return_enabled': autoReturnEnabled.value,
      'auto_return_triggered': autoReturnTriggered.value,
      'last_heartbeat': lastHeartbeat.value.toIso8601String(),
    };
  }

  @override
  void onClose() {
    _heartbeatMonitor?.cancel();
    _safetyMonitor?.cancel();
    _autoReturnTimer?.cancel();
    super.onClose();
  }
}
