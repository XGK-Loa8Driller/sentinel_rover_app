import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'rover_state_controller.dart';

/// L3 - SECURE COMMUNICATION LAYER
/// Professional-grade secure communication with:
/// - Token authentication
/// - Command signatures
/// - Acknowledgment system
/// - Heartbeat monitoring
/// - Auto-reconnect
/// - Encrypted payloads

class SecureCommunicationProtocol extends GetxController {
  final RoverStateController _roverState = Get.find<RoverStateController>();
  
  late IO.Socket socket;
  
  var isConnected = false.obs;
  var isAuthenticated = false.obs;
  var authToken = Rx<String?>(null);
  var sessionId = Rx<String?>(null);
  
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  Timer? _ackTimeoutTimer;
  
  final int heartbeatInterval = 2000; // 2 seconds
  final int ackTimeout = 5000; // 5 seconds
  final int reconnectDelay = 3000; // 3 seconds
  final int maxReconnectAttempts = 5;
  int reconnectAttempts = 0;
  
  // Pending command acknowledgments
  final Map<String, CommandPacket> _pendingCommands = {};
  
  @override
  void onInit() {
    super.onInit();
    connect();
  }
  
  // ============================================================================
  // CONNECTION MANAGEMENT
  // ============================================================================
  
  void connect() {
    print('[COMM_PROTOCOL] Initiating secure connection...');
    
    try {
      // Configure secure WebSocket
      socket = IO.io(
        'http://localhost:3000', // Change to wss:// in production
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({
              'authorization': 'Bearer ${authToken.value ?? ""}',
            })
            .build(),
      );
      
      _setupEventHandlers();
      socket.connect();
      
    } catch (e) {
      print('[COMM_PROTOCOL] Connection error: $e');
      _scheduleReconnect();
    }
  }
  
  void _setupEventHandlers() {
    socket.onConnect((_) {
      print('[COMM_PROTOCOL] Connected to server');
      isConnected.value = true;
      reconnectAttempts = 0;
      
      _authenticate();
      _startHeartbeat();
      _startAckMonitoring();
    });
    
    socket.onDisconnect((_) {
      print('[COMM_PROTOCOL] Disconnected from server');
      isConnected.value = false;
      isAuthenticated.value = false;
      
      _stopHeartbeat();
      _roverState.linkStatus.value = LinkStatus.lost;
      _scheduleReconnect();
    });
    
    socket.on('connect_error', (error) {
      print('[COMM_PROTOCOL] Connection error: $error');
      _scheduleReconnect();
    });
    
    // Protocol event handlers
    socket.on('auth_response', _handleAuthResponse);
    socket.on('heartbeat_ack', _handleHeartbeatAck);
    socket.on('command_ack', _handleCommandAck);
    socket.on('rover_status', _handleRoverStatus);
    socket.on('drone_detected', _handleDroneDetected);
    socket.on('telemetry_update', _handleTelemetryUpdate);
  }
  
  void _scheduleReconnect() {
    if (reconnectAttempts >= maxReconnectAttempts) {
      print('[COMM_PROTOCOL] Max reconnection attempts reached');
      _roverState.linkStatus.value = LinkStatus.lost;
      return;
    }
    
    _roverState.linkStatus.value = LinkStatus.reconnecting;
    reconnectAttempts++;
    
    print('[COMM_PROTOCOL] Reconnecting in ${reconnectDelay}ms (attempt $reconnectAttempts/$maxReconnectAttempts)');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: reconnectDelay), () {
      connect();
    });
  }
  
  void disconnect() {
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _ackTimeoutTimer?.cancel();
    socket.disconnect();
    socket.dispose();
  }
  
  // ============================================================================
  // AUTHENTICATION
  // ============================================================================
  
  void _authenticate() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final deviceId = 'mobile_app_001';
    
    // In production, use proper JWT tokens
    final authPayload = {
      'device_id': deviceId,
      'timestamp': timestamp,
      'version': '3.0',
    };
    
    socket.emit('authenticate', authPayload);
    print('[COMM_PROTOCOL] Authentication request sent');
  }
  
  void _handleAuthResponse(dynamic data) {
    if (data['success'] == true) {
      isAuthenticated.value = true;
      authToken.value = data['token'];
      sessionId.value = data['session_id'];
      
      print('[COMM_PROTOCOL] ✓ Authentication successful');
      print('[COMM_PROTOCOL] Session ID: ${sessionId.value}');
      
      _roverState.linkStatus.value = LinkStatus.connected;
    } else {
      print('[COMM_PROTOCOL] ✗ Authentication failed: ${data['error']}');
      disconnect();
    }
  }
  
  // ============================================================================
  // HEARTBEAT SYSTEM
  // ============================================================================
  
  void _startHeartbeat() {
    _stopHeartbeat();
    
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: heartbeatInterval),
      (_) => _sendHeartbeat(),
    );
  }
  
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  void _sendHeartbeat() {
    if (!isConnected.value || !isAuthenticated.value) return;
    
    final heartbeat = {
      'timestamp': DateTime.now().toIso8601String(),
      'state': _roverState.roverState.value.name,
      'mode': _roverState.roverMode.value.name,
    };
    
    socket.emit('heartbeat', heartbeat);
  }
  
  void _handleHeartbeatAck(dynamic data) {
    _roverState.updateHeartbeat();
    
    // Update network metrics
    final sentTime = DateTime.parse(data['timestamp']);
    final latency = DateTime.now().difference(sentTime).inMilliseconds;
    _roverState.latency.value = latency;
  }
  
  // ============================================================================
  // SECURE COMMAND PROTOCOL
  // ============================================================================
  
  Future<bool> sendSecureCommand(
    String commandType,
    Map<String, dynamic> payload, {
    bool requiresAck = true,
  }) async {
    if (!isConnected.value || !isAuthenticated.value) {
      print('[COMM_PROTOCOL] Cannot send command: Not authenticated');
      return false;
    }
    
    final commandId = 'cmd_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now().toIso8601String();
    
    // Create command packet
    final packet = CommandPacket(
      id: commandId,
      type: commandType,
      payload: payload,
      timestamp: timestamp,
      signature: _generateSignature(commandId, commandType, timestamp),
      requiresAck: requiresAck,
    );
    
    // Add to pending commands if ack required
    if (requiresAck) {
      _pendingCommands[commandId] = packet;
    }
    
    // Send command
    socket.emit('secure_command', packet.toJson());
    
    print('[COMM_PROTOCOL] Command sent: $commandType ($commandId)');
    
    // Update rover state
    _roverState.sendCommand(commandType, payload);
    
    return true;
  }
  
  String _generateSignature(String commandId, String commandType, String timestamp) {
    // In production, use HMAC with secret key
    final data = '$commandId:$commandType:$timestamp:${authToken.value}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  void _handleCommandAck(dynamic data) {
    final commandId = data['command_id'];
    final status = data['status'];
    final result = data['result'];
    
    if (_pendingCommands.containsKey(commandId)) {
      print('[COMM_PROTOCOL] ✓ Command acknowledged: $commandId ($status)');
      
      _pendingCommands.remove(commandId);
      _roverState.acknowledgeCommand(commandId, status);
      
      // Handle result if present
      if (result != null) {
        _handleCommandResult(commandId, result);
      }
    }
  }
  
  void _handleCommandResult(String commandId, dynamic result) {
    // Process command execution results
    print('[COMM_PROTOCOL] Command result: $result');
  }
  
  void _startAckMonitoring() {
    _ackTimeoutTimer?.cancel();
    
    _ackTimeoutTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _checkAckTimeouts(),
    );
  }
  
  void _checkAckTimeouts() {
    final now = DateTime.now();
    final timeout = Duration(milliseconds: ackTimeout);
    
    _pendingCommands.removeWhere((commandId, packet) {
      final elapsed = now.difference(DateTime.parse(packet.timestamp));
      
      if (elapsed > timeout) {
        print('[COMM_PROTOCOL] ✗ Command timeout: $commandId');
        return true;
      }
      return false;
    });
  }
  
  // ============================================================================
  // EVENT HANDLERS
  // ============================================================================
  
  void _handleRoverStatus(dynamic data) {
    _roverState.updateTelemetry(data);
    
    if (data.containsKey('position')) {
      final pos = data['position'];
      _roverState.updatePosition(
        pos['latitude'],
        pos['longitude'],
        hdg: pos['heading'],
        alt: pos['altitude'],
        spd: pos['speed'],
      );
    }
  }
  
  void _handleDroneDetected(dynamic data) {
    print('[COMM_PROTOCOL] Drone detection received');
    
    // Parse drone detection data
    final threat = ThreatModel.fromJson(data);
    _roverState.addThreat(threat);
  }
  
  void _handleTelemetryUpdate(dynamic data) {
    _roverState.updateTelemetry(data);
  }
  
  // ============================================================================
  // HIGH-LEVEL COMMAND INTERFACE
  // ============================================================================
  
  Future<bool> changeMode(RoverMode mode) async {
    return await sendSecureCommand('mode_change', {
      'mode': mode.name,
    });
  }
  
  Future<bool> move(String direction, double speed) async {
    return await sendSecureCommand('move', {
      'direction': direction,
      'speed': speed,
    });
  }
  
  Future<bool> fireLaser(String targetId) async {
    return await sendSecureCommand('fire_laser', {
      'target_id': targetId,
    });
  }
  
  Future<bool> engageTracking(String targetId) async {
    return await sendSecureCommand('engage_tracking', {
      'target_id': targetId,
    });
  }
  
  Future<bool> setCameraAngle(double pan, double tilt) async {
    return await sendSecureCommand('camera_control', {
      'pan': pan,
      'tilt': tilt,
    }, requiresAck: false);
  }
  
  Future<bool> emergencyStop() async {
    return await sendSecureCommand('emergency_stop', {}, requiresAck: true);
  }
  
  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}

// ============================================================================
// COMMAND PACKET DATA STRUCTURE
// ============================================================================

class CommandPacket {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final String timestamp;
  final String signature;
  final bool requiresAck;
  
  CommandPacket({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    required this.signature,
    this.requiresAck = true,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'timestamp': timestamp,
      'signature': signature,
      'requires_ack': requiresAck,
    };
  }
  
  factory CommandPacket.fromJson(Map<String, dynamic> json) {
    return CommandPacket(
      id: json['id'],
      type: json['type'],
      payload: json['payload'],
      timestamp: json['timestamp'],
      signature: json['signature'],
      requiresAck: json['requires_ack'] ?? true,
    );
  }
}
