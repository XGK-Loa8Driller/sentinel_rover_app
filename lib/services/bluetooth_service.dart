import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;
import 'package:get/get.dart';
import '../services/system_status_service.dart';

class RoverBluetoothService extends GetxService {
  var isScanning = false.obs;
  var isConnected = false.obs;
  var connectedDevice = Rx<fb.BluetoothDevice?>(null);
  var availableDevices = <fb.BluetoothDevice>[].obs;
  var connectionMode = 'websocket'.obs; // 'websocket', 'bluetooth', 'wifi'

  fb.BluetoothCharacteristic? _telemetryCharacteristic;
  fb.BluetoothCharacteristic? _commandCharacteristic;
  fb.BluetoothCharacteristic? _cameraCharacteristic;

  // Rover-specific UUIDs (customize these for your rover)
  static const String ROVER_SERVICE_UUID =
      "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String TELEMETRY_CHAR_UUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String COMMAND_CHAR_UUID =
      "beb5483e-36e1-4688-b7f5-ea07361b26a9";
  static const String CAMERA_CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26aa";

  @override
  void onInit() {
    super.onInit();
    _checkBluetoothState();
  }

  void _checkBluetoothState() async {
    final isSupported = await fb.FlutterBluePlus.isSupported;
    if (!isSupported) {
      final status = Get.find<SystemStatusService>();
      status.show('Bluetooth not supported on this device', StatusType.error);
    }
  }

  // Scan for nearby rovers
  void startScan() async {
    if (isScanning.value) return;

    availableDevices.clear();
    isScanning.value = true;

    try {
      // Start scanning
      await fb.FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

      // Listen to scan results
      fb.FlutterBluePlus.scanResults.listen((results) {
        for (fb.ScanResult result in results) {
          // Filter for Sentinel Rover devices
          if (result.device.platformName.contains('SENTINEL') ||
              result.device.platformName.contains('ROVER')) {
            if (!availableDevices.contains(result.device)) {
              availableDevices.add(result.device);
            }
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 10));
      await fb.FlutterBluePlus.stopScan();
      isScanning.value = false;

      if (availableDevices.isEmpty) {
        final status = Get.find<SystemStatusService>();
        status.show(
            'No rovers found. Check power and range.', StatusType.warning);
      }
    } catch (e) {
      print('Scan error: $e');
      isScanning.value = false;
      final status = Get.find<SystemStatusService>();
      status.show('Bluetooth scan failed: $e', StatusType.error);
    }
  }

  // Connect to a specific rover
  Future<void> connectToRover(fb.BluetoothDevice device) async {
    try {
      // Connect to device
      await device.connect(timeout: const Duration(seconds: 15));
      connectedDevice.value = device;
      isConnected.value = true;
      connectionMode.value = 'bluetooth';

      final status = Get.find<SystemStatusService>();
      status.show('Connected to ${device.platformName}', StatusType.success);

      // Discover services
      await _discoverServices(device);

      // Start listening to telemetry
      _subscribeTelemetry();
    } catch (e) {
      print('Connection error: $e');
      final status = Get.find<SystemStatusService>();
      status.show('Connection failed: $e', StatusType.error);
    }
  }

  // Discover rover services and characteristics
  Future<void> _discoverServices(fb.BluetoothDevice device) async {
    List<fb.BluetoothService> services = await device.discoverServices();

    for (fb.BluetoothService service in services) {
      if (service.uuid.toString() == ROVER_SERVICE_UUID) {
        for (fb.BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid.toString() == TELEMETRY_CHAR_UUID) {
            _telemetryCharacteristic = characteristic;
          } else if (characteristic.uuid.toString() == COMMAND_CHAR_UUID) {
            _commandCharacteristic = characteristic;
          } else if (characteristic.uuid.toString() == CAMERA_CHAR_UUID) {
            _cameraCharacteristic = characteristic;
          }
        }
      }
    }
  }

  // Subscribe to telemetry updates
  void _subscribeTelemetry() async {
    if (_telemetryCharacteristic == null) return;

    await _telemetryCharacteristic!.setNotifyValue(true);
    _telemetryCharacteristic!.onValueReceived.listen((value) {
      // Parse telemetry data
      // Format: [battery, latitude, longitude, distance, threat_count]
      if (value.length >= 20) {
        _parseTelemetry(value);
      }
    });
  }

  // Parse incoming telemetry data
  void _parseTelemetry(List<int> data) {
    // Example parsing (customize based on your rover's data format)
    // This is a simplified example - implement proper binary parsing
    final telemetry = String.fromCharCodes(data);
    print('Telemetry: $telemetry');

    // You would parse this and update your WebSocketService
    // or create a unified state management for rover data
  }

  // Send command to rover
  Future<void> sendCommand(String command) async {
    if (_commandCharacteristic == null) {
      final status = Get.find<SystemStatusService>();
      status.show('Not connected to rover', StatusType.error);
      return;
    }

    try {
      final commandBytes = command.codeUnits;
      await _commandCharacteristic!.write(commandBytes);
      print('Command sent: $command');
    } catch (e) {
      print('Command error: $e');
    }
  }

  // Request camera frame
  Future<List<int>?> getCameraFrame() async {
    if (_cameraCharacteristic == null) return null;

    try {
      // Request frame
      await _cameraCharacteristic!.write([0x01]); // Request frame command

      // Read frame data
      final frameData = await _cameraCharacteristic!.read();
      return frameData;
    } catch (e) {
      print('Camera error: $e');
      return null;
    }
  }

  // Disconnect from rover
  Future<void> disconnect() async {
    if (connectedDevice.value != null) {
      await connectedDevice.value!.disconnect();
      connectedDevice.value = null;
      isConnected.value = false;
      connectionMode.value = 'websocket';

      final status = Get.find<SystemStatusService>();
      status.show('Disconnected from rover', StatusType.info);
    }
  }

  // Switch connection modes
  void switchToWebSocket() {
    connectionMode.value = 'websocket';
    disconnect();
  }

  void switchToBluetooth() {
    connectionMode.value = 'bluetooth';
    if (availableDevices.isEmpty) {
      startScan();
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
