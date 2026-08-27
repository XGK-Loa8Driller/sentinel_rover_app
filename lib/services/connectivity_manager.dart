import 'package:sentinel_rover/services/bluetooth_service.dart';
import 'package:get/get.dart';
import 'websocket_service.dart';
import 'bluetooth_service.dart';
import '../services/system_status_service.dart';

enum ConnectionType { websocket, bluetooth, wifi, offline }

enum ConnectionStatus { connected, connecting, disconnected, error }

class ConnectivityManager extends GetxController {
  final WebSocketService _wsService = Get.find<WebSocketService>();
  final RoverBluetoothService _btService = Get.find<RoverBluetoothService>();

  // Current active connection
  var activeConnection = ConnectionType.websocket.obs;
  var connectionStatus = ConnectionStatus.disconnected.obs;
  var signalStrength = 0.obs; // 0-100
  var latency = 0.obs; // milliseconds
  var packetLoss = 0.0.obs; // percentage

  // Fallback logic
  var autoFallbackEnabled = true.obs;
  var preferredConnection = ConnectionType.wifi.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeConnections();
    _monitorConnectionHealth();
  }

  void _initializeConnections() {
    // Start with preferred connection
    switchConnection(preferredConnection.value);
  }

  // Main method to switch connections
  Future<void> switchConnection(ConnectionType type) async {
    connectionStatus.value = ConnectionStatus.connecting;

    // Disconnect current
    await _disconnectAll();

    try {
      switch (type) {
        case ConnectionType.websocket:
          await _connectWebSocket();
          break;
        case ConnectionType.bluetooth:
          await _connectBluetooth();
          break;
        case ConnectionType.wifi:
          await _connectWiFi();
          break;
        case ConnectionType.offline:
          connectionStatus.value = ConnectionStatus.disconnected;
          break;
      }

      activeConnection.value = type;
      connectionStatus.value = ConnectionStatus.connected;

      final status = Get.find<SystemStatusService>();
      status.show(
        'Connected via ${type.name.toUpperCase()}',
        StatusType.success,
      );
    } catch (e) {
      connectionStatus.value = ConnectionStatus.error;

      if (autoFallbackEnabled.value) {
        _attemptFallback(type);
      } else {
        final status = Get.find<SystemStatusService>();
        status.show(
          'Connection failed via ${type.name}',
          StatusType.error,
        );
      }
    }
  }

  Future<void> _connectWebSocket() async {
    _wsService.connect();
    // Wait for connection
    await Future.delayed(const Duration(seconds: 2));
    if (!_wsService.isConnected.value) {
      throw Exception('WebSocket connection failed');
    }
  }

  Future<void> _connectBluetooth() async {
    if (_btService.availableDevices.isEmpty) {
      _btService.startScan();
      await Future.delayed(const Duration(seconds: 10));
    }

    if (_btService.availableDevices.isNotEmpty) {
      await _btService.connectToRover(_btService.availableDevices.first);
    } else {
      throw Exception('No Bluetooth devices found');
    }
  }

  Future<void> _connectWiFi() async {
    // WiFi Direct connection logic
    // For now, same as WebSocket but could be direct IP
    await _connectWebSocket();
  }

  Future<void> _disconnectAll() async {
    if (_wsService.isConnected.value) {
      _wsService.disconnect();
    }
    if (_btService.isConnected.value) {
      await _btService.disconnect();
    }
  }

  void _attemptFallback(ConnectionType failedType) {
    final status = Get.find<SystemStatusService>();
    status.show(
      'Primary link failed. Switching to backup...',
      StatusType.warning,
    );

    // Fallback hierarchy: WiFi → Bluetooth → WebSocket
    if (failedType == ConnectionType.wifi) {
      switchConnection(ConnectionType.bluetooth);
    } else if (failedType == ConnectionType.bluetooth) {
      switchConnection(ConnectionType.websocket);
    } else {
      connectionStatus.value = ConnectionStatus.disconnected;
      final status = Get.find<SystemStatusService>();
      status.show(
        'All connections failed. Rover unreachable.',
        StatusType.error,
      );
    }
  }

  // Monitor connection health
  void _monitorConnectionHealth() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!isClosed) {
        _checkConnectionHealth();
        _monitorConnectionHealth();
      }
    });
  }

  void _checkConnectionHealth() {
    switch (activeConnection.value) {
      case ConnectionType.websocket:
        signalStrength.value = _wsService.isConnected.value ? 100 : 0;
        break;
      case ConnectionType.bluetooth:
        signalStrength.value = _btService.isConnected.value ? 80 : 0;
        break;
      case ConnectionType.wifi:
        signalStrength.value = _wsService.isConnected.value ? 95 : 0;
        break;
      case ConnectionType.offline:
        signalStrength.value = 0;
        break;
    }

    // Simulate latency measurement
    _measureLatency();

    // Check if connection dropped
    if (signalStrength.value == 0 &&
        connectionStatus.value == ConnectionStatus.connected) {
      connectionStatus.value = ConnectionStatus.disconnected;
      if (autoFallbackEnabled.value) {
        _attemptFallback(activeConnection.value);
      }
    }
  }

  void _measureLatency() {
    // In production, ping the rover and measure response time
    if (activeConnection.value == ConnectionType.bluetooth) {
      latency.value = 10 + (DateTime.now().millisecond % 20);
    } else if (activeConnection.value == ConnectionType.wifi) {
      latency.value = 30 + (DateTime.now().millisecond % 50);
    } else if (activeConnection.value == ConnectionType.websocket) {
      latency.value = 100 + (DateTime.now().millisecond % 100);
    }

    // Simulate packet loss
    packetLoss.value = latency.value > 150 ? 2.5 : 0.1;
  }

  // Send command through active connection
  Future<void> sendCommand(String command, [Map<String, dynamic>? data]) async {
    if (connectionStatus.value != ConnectionStatus.connected) {
      final status = Get.find<SystemStatusService>();
      status.show(
        'No active connection. Command not sent.',
        StatusType.warning,
      );

      return;
    }

    try {
      switch (activeConnection.value) {
        case ConnectionType.bluetooth:
          await _btService.sendCommand(command);
          break;
        case ConnectionType.websocket:
        case ConnectionType.wifi:
          _wsService.socket.emit('command', {
            'command': command,
            'data': data ?? {},
            'timestamp': DateTime.now().toIso8601String(),
          });
          break;
        case ConnectionType.offline:
          throw Exception('Offline mode - cannot send commands');
      }
    } catch (e) {
      final status = Get.find<SystemStatusService>();
      status.show(
        'Command failed: $e',
        StatusType.error,
      );
    }
  }

  // Get connection info for UI
  String get connectionInfo {
    return '${activeConnection.value.name.toUpperCase()} • ${latency.value}ms • ${signalStrength.value}%';
  }

  String get connectionStatusText {
    switch (connectionStatus.value) {
      case ConnectionStatus.connected:
        return 'CONNECTED';
      case ConnectionStatus.connecting:
        return 'CONNECTING...';
      case ConnectionStatus.disconnected:
        return 'DISCONNECTED';
      case ConnectionStatus.error:
        return 'ERROR';
      default:
        return 'UNKNOWN';
    }
  }

  @override
  void onClose() {
    _disconnectAll();
    super.onClose();
  }
}
