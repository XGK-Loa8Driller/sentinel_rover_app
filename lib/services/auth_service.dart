import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mission_log_service.dart';
import '../services/system_status_service.dart';

enum UserRole { operator, admin, superadmin }

enum SystemMode { surveillance, defense, manual, patrol, standby }

class AuthService extends GetxController {
  final MissionLogService _logService = Get.find<MissionLogService>();

  var isAuthenticated = false.obs;
  var currentUser = Rx<String?>(null);
  var currentRole = UserRole.operator.obs;
  var systemMode = SystemMode.surveillance.obs;
  var isLaserEnabled = false.obs;
  var isAutonomousEnabled = false.obs;

  // Default credentials (in production, use secure backend)
  final Map<String, Map<String, dynamic>> _credentials = {
    'operator': {'password': '1234', 'role': UserRole.operator},
    'admin': {'password': 'admin123', 'role': UserRole.admin},
    'sentinel': {'password': 'sentinel2024', 'role': UserRole.superadmin},
  };

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('logged_in_user');
    if (savedUser != null) {
      currentUser.value = savedUser;
      isAuthenticated.value = true;
      _logService.log('Auto-login successful: $savedUser', LogLevel.info);
    }
  }

  Future<bool> login(String username, String password) async {
    if (_credentials.containsKey(username)) {
      if (_credentials[username]!['password'] == password) {
        currentUser.value = username;
        currentRole.value = _credentials[username]!['role'];
        isAuthenticated.value = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_in_user', username);

        _logService.log(
          'User logged in: $username (${currentRole.value.name})',
          LogLevel.success,
        );

        return true;
      }
    }

    _logService.log('Failed login attempt: $username', LogLevel.warning);
    return false;
  }

  Future<void> logout() async {
    final username = currentUser.value;

    currentUser.value = null;
    isAuthenticated.value = false;
    currentRole.value = UserRole.operator;
    isLaserEnabled.value = false;
    isAutonomousEnabled.value = false;
    systemMode.value = SystemMode.standby;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user');

    _logService.log('User logged out: $username', LogLevel.info);
  }

  bool hasPermission(String action) {
    switch (action) {
      case 'fire_laser':
        return currentRole.value == UserRole.admin ||
            currentRole.value == UserRole.superadmin;

      case 'enable_autonomous':
        return currentRole.value == UserRole.superadmin;

      case 'change_mode':
        return currentRole.value == UserRole.admin ||
            currentRole.value == UserRole.superadmin;

      case 'emergency_stop':
        return true; // Everyone can emergency stop

      case 'manual_control':
        return isAuthenticated.value;

      default:
        return false;
    }
  }

  Future<bool> requestPermission(String action, String reason) async {
    if (!isAuthenticated.value) {
      final status = Get.find<SystemStatusService>();
      status.show(
          '🔐 Please log in to perform this action', StatusType.warning);

      return false;
    }

    if (!hasPermission(action)) {
      final status = Get.find<SystemStatusService>();
      status.show(
        '🚫 ${currentRole.value.name} cannot perform: $action',
        StatusType.error,
      );

      _logService.log(
        'Permission denied: $action for ${currentUser.value}',
        LogLevel.warning,
      );

      return false;
    }

    // For critical actions, show confirmation dialog
    if (_isCriticalAction(action)) {
      return await _showPinVerification(action, reason);
    }

    return true;
  }

  bool _isCriticalAction(String action) {
    return ['fire_laser', 'enable_autonomous', 'emergency_stop']
        .contains(action);
  }

  Future<bool> _showPinVerification(String action, String reason) async {
    String? pin = await Get.dialog<String>(
      _buildPinDialog(action, reason),
      barrierDismissible: false,
    );

    if (pin != null && pin.length == 4) {
      // Verify PIN (in production, use proper verification)
      _logService.log(
        'Critical action authorized: $action by ${currentUser.value}',
        LogLevel.critical,
      );
      return true;
    }

    _logService.log(
      'Critical action cancelled: $action',
      LogLevel.warning,
    );
    return false;
  }

  Widget _buildPinDialog(String action, String reason) {
    // This would be a proper PIN entry dialog
    // Simplified for now
    return AlertDialog(
      title: Text('Confirm Action'),
      content: Text('Authorize: $action\nReason: $reason'),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: null),
          child: Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () => Get.back(result: '1234'),
          child: Text('AUTHORIZE'),
        ),
      ],
    );
  }

  void changeSystemMode(SystemMode newMode) {
    if (!hasPermission('change_mode')) {
      final status = Get.find<SystemStatusService>();
      status.show('⚠ Cannot change system mode', StatusType.warning);

      return;
    }

    final oldMode = systemMode.value;
    systemMode.value = newMode;

    _logService.log(
      'System mode changed: ${oldMode.name} → ${newMode.name}',
      LogLevel.info,
    );

    // Auto-configure based on mode
    _configureModeSettings(newMode);
  }

  void _configureModeSettings(SystemMode mode) {
    switch (mode) {
      case SystemMode.surveillance:
        isLaserEnabled.value = false;
        isAutonomousEnabled.value = false;
        break;

      case SystemMode.defense:
        if (hasPermission('fire_laser')) {
          isLaserEnabled.value = true;
        }
        break;

      case SystemMode.manual:
        isAutonomousEnabled.value = false;
        break;

      case SystemMode.patrol:
        isAutonomousEnabled.value = true;
        break;

      case SystemMode.standby:
        isLaserEnabled.value = false;
        isAutonomousEnabled.value = false;
        break;
    }
  }

  void enableLaser() async {
    if (await requestPermission('fire_laser', 'Enable laser system')) {
      isLaserEnabled.value = true;
      _logService.log('Laser system ENABLED', LogLevel.critical);

      final status = Get.find<SystemStatusService>();
      status.show('⚠️ Laser system is now ACTIVE', StatusType.error);
    }
  }

  void disableLaser() {
    isLaserEnabled.value = false;
    _logService.log('Laser system DISABLED', LogLevel.info);
  }

  void emergencyStop() {
    systemMode.value = SystemMode.standby;
    isLaserEnabled.value = false;
    isAutonomousEnabled.value = false;

    _logService.log('🚨 EMERGENCY STOP ACTIVATED', LogLevel.critical);

    final status = Get.find<SystemStatusService>();
    status.show('🚨 EMERGENCY STOP – All systems halted', StatusType.error);
  }
}
