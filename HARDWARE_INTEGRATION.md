# 🔌 Hardware Integration Guide

Complete guide for connecting your physical Sentinel Rover to the mobile app via Bluetooth or WiFi.

## 📡 Connection Options

### Option 1: Bluetooth Low Energy (BLE) - Recommended for Close Range
- **Range**: Up to 100 meters (line of sight)
- **Latency**: Very low (~10ms)
- **Best for**: Direct rover control, camera streaming
- **Power**: More efficient than WiFi

### Option 2: WiFi Direct/Hotspot
- **Range**: Up to 200 meters
- **Bandwidth**: Higher (better for camera)
- **Best for**: Video streaming, large data transfer
- **Power**: Higher consumption

### Option 3: WebSocket (Internet)
- **Range**: Unlimited (requires internet)
- **Latency**: Higher (100-500ms)
- **Best for**: Remote monitoring, cloud integration

## 🛠️ Hardware Requirements

### For Rover (ESP32 Based)
```
- ESP32 DevKit (WiFi + Bluetooth built-in)
- Camera Module (ESP32-CAM or OV2640)
- GPS Module (Neo-6M or better)
- IMU/Gyroscope (MPU6050)
- Laser system control interface
- Motor drivers for movement
- Battery management system
```

### Recommended: ESP32-CAM
- Built-in camera
- WiFi + Bluetooth
- Affordable ($10-15)
- Perfect for this project

## 📝 ESP32 Firmware Code

### BLE Server Implementation

```cpp
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// UUIDs (must match those in Flutter app)
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define TELEMETRY_CHAR_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define COMMAND_CHAR_UUID   "beb5483e-36e1-4688-b7f5-ea07361b26a9"
#define CAMERA_CHAR_UUID    "beb5483e-36e1-4688-b7f5-ea07361b26aa"

BLEServer* pServer = NULL;
BLECharacteristic* pTelemetryChar = NULL;
BLECharacteristic* pCommandChar = NULL;
BLECharacteristic* pCameraChar = NULL;

bool deviceConnected = false;
float batteryLevel = 100.0;
float latitude = 13.0827;
float longitude = 80.2707;
float distanceTraveled = 0.0;

// Server callbacks
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("Device connected!");
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("Device disconnected!");
      // Restart advertising
      BLEDevice::startAdvertising();
    }
};

// Command characteristic callback
class CommandCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      
      if (value.length() > 0) {
        Serial.print("Received command: ");
        for (int i = 0; i < value.length(); i++) {
          Serial.print(value[i]);
        }
        Serial.println();
        
        // Handle commands
        String cmd = String(value.c_str());
        if (cmd == "FIRE_LASER") {
          fireLaser();
        } else if (cmd == "STOP") {
          stopRover();
        } else if (cmd.startsWith("MOVE_")) {
          handleMovement(cmd);
        }
      }
    }
};

void setup() {
  Serial.begin(115200);
  
  // Initialize BLE
  BLEDevice::init("SENTINEL_ROVER_001");
  
  // Create BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());

  // Create BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Telemetry Characteristic (Notify)
  pTelemetryChar = pService->createCharacteristic(
    TELEMETRY_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | 
    BLECharacteristic::PROPERTY_NOTIFY
  );
  pTelemetryChar->addDescriptor(new BLE2902());

  // Command Characteristic (Write)
  pCommandChar = pService->createCharacteristic(
    COMMAND_CHAR_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  pCommandChar->setCallbacks(new CommandCallbacks());

  // Camera Characteristic (Read)
  pCameraChar = pService->createCharacteristic(
    CAMERA_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ
  );

  // Start service
  pService->start();

  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(false);
  pAdvertising->setMinPreferred(0x0);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE Server started. Waiting for connections...");
}

void loop() {
  if (deviceConnected) {
    // Send telemetry every 1 second
    sendTelemetry();
    delay(1000);
  }
}

void sendTelemetry() {
  // Create telemetry packet
  String telemetry = String(batteryLevel) + "," + 
                     String(latitude, 6) + "," + 
                     String(longitude, 6) + "," + 
                     String(distanceTraveled, 2) + "," +
                     String(getActiveThreatCount());
  
  pTelemetryChar->setValue(telemetry.c_str());
  pTelemetryChar->notify();
  
  // Simulate battery drain
  batteryLevel -= 0.01;
  if (batteryLevel < 0) batteryLevel = 0;
  
  // Update distance (integrate odometry here)
  distanceTraveled += 0.5; // Example: 0.5m per second
}

void fireLaser() {
  Serial.println("Firing laser!");
  // Control laser GPIO here
  // digitalWrite(LASER_PIN, HIGH);
  // delay(100);
  // digitalWrite(LASER_PIN, LOW);
}

void stopRover() {
  Serial.println("Stopping rover");
  // Stop motors
}

void handleMovement(String cmd) {
  Serial.println("Movement command: " + cmd);
  // Implement motor control
}

int getActiveThreatCount() {
  // Implement threat detection
  return 0;
}
```

## 📷 Camera Streaming

### HTTP Camera Server (ESP32-CAM)

```cpp
#include "esp_camera.h"
#include <WiFi.h>
#include <WebServer.h>

WebServer server(80);

void handleStream() {
  WiFiClient client = server.client();
  
  String response = "HTTP/1.1 200 OK\r\n";
  response += "Content-Type: multipart/x-mixed-replace; boundary=frame\r\n\r\n";
  server.sendContent(response);
  
  while (client.connected()) {
    camera_fb_t * fb = esp_camera_fb_get();
    if (!fb) {
      Serial.println("Camera capture failed");
      break;
    }
    
    client.print("--frame\r\n");
    client.print("Content-Type: image/jpeg\r\n\r\n");
    client.write((char *)fb->buf, fb->len);
    client.print("\r\n");
    
    esp_camera_fb_return(fb);
    delay(100); // 10 FPS
  }
}

void setupCamera() {
  camera_config_t config;
  config.ledc_channel = LEDC_CHANNEL_0;
  config.ledc_timer = LEDC_TIMER_0;
  config.pin_d0 = Y2_GPIO_NUM;
  // ... configure all camera pins
  
  esp_err_t err = esp_camera_init(&config);
  if (err != ESP_OK) {
    Serial.printf("Camera init failed: 0x%x", err);
    return;
  }
}

void setup() {
  // Setup WiFi
  WiFi.begin("YOUR_SSID", "YOUR_PASSWORD");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected!");
  Serial.print("Camera Stream: http://");
  Serial.println(WiFi.localIP());
  
  setupCamera();
  
  server.on("/stream", HTTP_GET, handleStream);
  server.begin();
}

void loop() {
  server.handleClient();
}
```

## 🗺️ GPS Integration

```cpp
#include <TinyGPS++.h>
#include <HardwareSerial.h>

TinyGPSPlus gps;
HardwareSerial GPS(1);

void setupGPS() {
  GPS.begin(9600, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
}

void updateGPS() {
  while (GPS.available() > 0) {
    gps.encode(GPS.read());
  }
  
  if (gps.location.isUpdated()) {
    latitude = gps.location.lat();
    longitude = gps.location.lng();
  }
}
```

## 📱 Connecting from Flutter App

### Step 1: Enable Bluetooth in App
1. Open app → Dashboard
2. Tap "CONNECTION MODE" card
3. Select "BLUETOOTH"
4. Tap "SCAN FOR ROVERS"

### Step 2: Pair with Rover
1. Your rover should appear as "SENTINEL_ROVER_001"
2. Tap "CONNECT"
3. Connection established!

### Step 3: Switch to WiFi (Optional)
If using WiFi Direct:
1. Rover creates WiFi hotspot: "SENTINEL_AP"
2. Connect phone to this network
3. App auto-connects via WebSocket

## 🔧 Troubleshooting

### Bluetooth Won't Connect
- Ensure rover is powered on
- Check UUID matches in both app and firmware
- Restart both devices
- Check phone Bluetooth permissions

### Camera Not Streaming
- Verify camera module connections
- Check WiFi signal strength
- Ensure correct IP address in app
- Test stream in browser first

### GPS Not Updating
- GPS needs clear sky view
- Allow 30-60 seconds for satellite lock
- Check GPS module power
- Verify baud rate (usually 9600)

## 📊 Data Format

### Telemetry Packet Structure
```
Format: battery,latitude,longitude,distance,threat_count
Example: 85.5,13.082756,80.270721,1250.50,2
```

### Command Format
```
FIRE_LASER
STOP
MOVE_FORWARD
MOVE_BACKWARD
TURN_LEFT
TURN_RIGHT
```

## 🔐 Security Considerations

1. **Encryption**: BLE has built-in encryption
2. **Authentication**: Add PIN pairing in production
3. **Range Limits**: BLE auto-disconnects when out of range
4. **Command Validation**: Always validate commands on rover

## 🚀 Next Steps

1. Flash firmware to ESP32
2. Test BLE connection with app
3. Add camera module
4. Integrate GPS
5. Connect laser control
6. Test everything together!

## 📚 Additional Resources

- [ESP32 BLE Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/bluetooth/esp_gatts.html)
- [ESP32-CAM Guide](https://randomnerdtutorials.com/esp32-cam-video-streaming-web-server-camera-home-assistant/)
- [TinyGPS++ Library](https://github.com/mikalhart/TinyGPSPlus)

---

**Hardware Support**: For issues with ESP32 setup, consult Espressif documentation or ESP32 forums.
